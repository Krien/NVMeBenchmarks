#!/usr/bin/env python3
import os
from bench_utils import *
import argparse

JOB_RAMP = "10s"
JOB_RUN = "10m"

DIS_DELAY = "4m"
DIS_RAMP = "10s"
DIS_RUN = "2m"

JOB_SIZE_NVME = "40G"
JOB_SIZE_ZNS = "20z"

def dev_name(device:str, namespace:str)->str:
    return f"{device}n{namespace}"

def operation_options(io_engine:IOEngine, operation:str, qd:int, zns: bool)->list[JobOption]:
    opts = []
    if "write" in operation:
        if "rand" in operation:
            opts.append(JobOption(JobWorkload.RAN_WRITE))
        else:
            opts.append(JobOption(JobWorkload.SEQ_WRITE))
        if zns and int(qd) > 1:
            if io_engine == IOEngine.SPDK:
                opts.append(ZNSAppendOption(True))
            else:
                opts.append(SchedulerOption(Scheduler.MQ_DEADLINE))
        elif IOEngine == IOEngine.IO_URING:
                opts.append(SchedulerOption(Scheduler.NONE))
    else:
        if "rand" in operation:
            opts.append(JobOption(JobWorkload.RAN_READ))
        else:
            opts.append(JobOption(JobWorkload.SEQ_READ))
        if IOEngine == IOEngine.IO_URING:
                opts.append(SchedulerOption(Scheduler.NONE))
    return opts

    
def main(
    fio: str,
        spdk_dir: str,
    model: str,
    device: str,
    target_ns: str,
    disturbed_nss: list[str],
    lbaf: str,
    io_engine: str,
    target_op: str,
    target_size: str,
    target_depth: str,
    dis_op: str,
    dis_size: str,
    dis_depth: str,
    overwrite: bool,
    mock: bool,
):
    # Devices
    target_device = dev_name(device, target_ns)
    disturbed_devices = [dev_name(device, ns) for ns in disturbed_nss]
    devices =  disturbed_devices + [target_device]

    # Setup tools
    job_gen = FioJobGenerator(overwrite)
    fio = FioRunner(fio, overwrite)
    nvme = {device: NVMeRunnerCLI(device) if not mock else NVMeRunnerMock(device) for device in devices}
    io_engine = string_to_io_engine(io_engine)
    filename_func = lambda dev : f"/dev/{dev}"

    # Investigate device (Be careful this might be different between namespaces)
    zns = nvme[target_device].is_zoned()
    numa_node = nvme[target_device].get_numa_node()
    min_size = nvme[target_device].get_min_request_size()

    # SPDK
    spdk = {}
    if io_engine == IOEngine.SPDK:
        fio.LD_PRELOAD(f"{spdk_dir}/build/fio/spdk_nvme")
        spdk = {device: (
            SPDKRunnerCLI(
                spdk_dir, [device], lambda dev: NVMeRunnerCLI(dev), {"numa": numa_node}
            )
            if not mock
            else SPDKRunnerMock(
                    spdk_dir, [device], lambda dev: NVMeRunnerMock(dev), {"numa": numa_node}
            )
        ) for device in devices}
        filename_func = lambda dev : spdk[dev].get_spdk_traddress(dev)

    # Setup default job args
    job_defaults = [
        DirectOption(True),
        GroupReportingOption(False),
        ThreadOption(True),
        NumaPinOption(numa_node),
        IOEngineOption(io_engine)
    ]
    if zns:
        job_defaults.append(SizeOption(JOB_SIZE_ZNS))
        job_defaults.append(ZnsOption())
    else:
        job_defaults.append(SizeOption(JOB_SIZE_NVME))
    if io_engine == IOEngine.IO_URING:
        job_defaults.append(DefaultIOUringOption())


    job = FioGlobalJob()
    target_job = FioSubJob(f"target_{target_depth}")
    target_job.add_options(job_defaults)
    target_job.add_options([
        TimedOption(JOB_RUN, JOB_RAMP),
        JsonOption(),
        TargetOption(filename_func(target_device)),
        RequestSizeOption(target_size),
        QDOption(target_depth)
    ] + operation_options(io_engine, target_op, target_depth, zns))
    # Do not leak paths in job file, use env var
    target_job.add_option2("write_bw_log", "${BW_PATH}")
    target_job.add_option2("write_lat_log", "${LOG_PATH}")
    target_job.add_option2("log_avg_msec", "10ms")
    job.add_job(target_job)

    for disturbed_dev in disturbed_devices:
        dis_job = FioSubJob(f"dis_{disturbed_dev}")
        dis_job.add_options(job_defaults)
        dis_job.add_options([
            DelayOption(DIS_DELAY),
            TimedOption(DIS_RUN, DIS_RAMP),
            TargetOption(filename_func(disturbed_dev))
        ] + operation_options(io_engine, dis_op, dis_depth, zns))
        job.add_job(dis_job)

    # paths
    path = BenchPath(io_engine, model, lbaf, f"concurrent_namespaces_{target_op}_{dis_op}", 1, target_depth, target_size)

    # Write job file
    job_gen.generate_job_file(path.AbsPathJob(), job)
    # run job
    fio.run_job(
        path.AbsPathJob(),
        path.AbsPathOut(),
        [f"BW_PATH={path.AbsPathOut()}", f"LOG_PATH={path.AbsPathOut()}"],
        mock=mock,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Do investigative tests on an NVMe drive in grid fashion"
    )
    parser.add_argument("-d", "--device", type=str, required=True)
    parser.add_argument("-n", "--devicens", type=str, required=True)
    parser.add_argument("-t", "--otherns", type=str, nargs="+", required=True)
    parser.add_argument("-m", "--model", type=str, required=True)
    parser.add_argument("-f", "--fio", type=str, required=True)
    parser.add_argument("-s", "--spdk_dir", type=str, required=True)
    parser.add_argument("-l", "--lbaf", type=str, required=True)
    parser.add_argument("-e", "--engine", type=str, required=False, default="io_uring")
    parser.add_argument("--target_bs", type=str, required=False, default="4096")
    parser.add_argument("--target_qd", type=str, required=False, default="1")
    parser.add_argument("--target_op", type=str, required=False, default="write")
    parser.add_argument("--dis_bs", type=str, required=False, default="4096")
    parser.add_argument("--dis_qd", type=str, required=False, default="1")
    parser.add_argument("--dis_op", type=str, required=False, default="write")
    parser.add_argument("--mock", type=bool, required=False, default=False)
    parser.add_argument("-o", "--overwrite", type=str, required=False, default=False)
    args = parser.parse_args()

    main(
        args.fio,
        args.spdk_dir,
        args.model,
        args.device,
        args.devicens,
        args.otherns,
        args.lbaf,
        args.engine,
        args.target_op,
        args.target_bs,
        args.target_qd,
        args.dis_op,
        args.dis_bs,
        args.dis_qd,
        args.overwrite,
        args.mock,
    )
