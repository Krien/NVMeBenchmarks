#!/usr/bin/env python3
import os
from bench_utils import *
import argparse

# Magic constants
JOB_SIZE_ZNS: str = "20z"
JOB_SIZE_NVME: str = "40G"
JOB_RAMP: str = "10s"
JOB_RUN: str = "30s"

# Grid
JOB_QDS: list[int] = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512]
JOB_BSS: list[int] = [512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072]
JOB_CZONES: list[int] = [1, 2, 3, 4, 5]

# Out names
SPDK_APPEND_OP: str = "append"
SPDK_WRITE_OP: str = "write"
IO_URING_WRITE_MQ_OPTION: str = "writemq"
IO_URING_WRITE_NONE_OPTION: str = "write"


def main(
    fio: str,
    spdk_dir: str,
    model: str,
    device: str,
    lbaf: str,
    overwrite: bool,
    mock: bool,
):
    # Setup tools
    job_gen = FioJobGenerator(overwrite)
    fio = FioRunner(fio, overwrite)
    fio.LD_PRELOAD(f"{spdk_dir}/build/fio/spdk_nvme")
    nvme = NVMeRunnerCLI(device) if not mock else NVMeRunnerMock(device)

    # Investigate device
    zns = nvme.is_zoned()
    numa_node = nvme.get_numa_node()
    min_size = nvme.get_min_request_size()
    max_open_zones = nvme.get_max_open_zones() if zns else -1

    # spdk setup
    spdk = (
        SPDKRunnerCLI(
            spdk_dir, [device], lambda dev: NVMeRunnerCLI(dev), {"numa": numa_node}
        )
        if not mock
        else SPDKRunnerMock(
            spdk_dir, [device], lambda dev: NVMeRunnerMock(dev), {"numa": numa_node}
        )
    )

    # Setup default job args
    job_defaults = [
        JobOption(JobWorkload.SEQ_WRITE),
        DirectOption(True),
        GroupReportingOption(True),
        JsonOption(),
        ThreadOption(True),
        TimedOption(JOB_RUN, JOB_RAMP),
        NumaPinOption(numa_node),
    ]
    if zns:
        job_defaults.append(SizeOption(JOB_SIZE_ZNS))
        job_defaults.append(ZnsOption())
    else:
        job_defaults.append(SizeOption(JOB_SIZE_NVME))

    io_uring_args = [
        IOEngineOption(IOEngine.IO_URING),
        DefaultIOUringOption(),
        TargetOption(f"/dev/{device}"),
    ]
    spdk_filename = spdk.get_spdk_traddress(device)
    spdk_args = [IOEngineOption(IOEngine.SPDK), TargetOption(spdk_filename)]

    # Setup grid
    qds = JOB_QDS
    bss = [bs for bs in JOB_BSS if bs >= min_size]
    czones = [czone for czone in JOB_CZONES if czone <= max_open_zones] if zns else [1]

    # io_uring grid search
    for (qd, bs, concurrent_zones) in [
        (qd, bs, czone) for bs in bss for qd in qds for czone in czones
    ]:
        # define job
        job = FioGlobalJob()
        sjob = FioSubJob(f"qd{qd}")
        sjob.add_options(job_defaults)
        sjob.add_options(io_uring_args)
        sjob.add_options(
            [
                QDOption(qd),
                ConcurrentWorkerOption(concurrent_zones),
                RequestSizeOption(f"{bs}"),
            ]
        )
        operation = "deadbeef"
        if zns:
            sjob.add_options(
                [SchedulerOption(Scheduler.MQ_DEADLINE), OffsetOption(JOB_SIZE_ZNS)]
            )
            operation = IO_URING_WRITE_MQ_OPTION
        else:
            sjob.add_options([SchedulerOption(Scheduler.NONE)])
            operation = IO_URING_WRITE_NONE_OPTION
        job.add_job(sjob)

        # paths
        path = BenchPath(
            IOEngine.IO_URING, model, lbaf, operation, concurrent_zones, qd, bs
        )
        # Write job file
        job_gen.generate_job_file(path.AbsPathJob(), job)
        # Prepare device
        nvme.clean_device()
        # run job
        fio.run_job(path.AbsPathJob(), path.AbsPathOut(), mock=mock)

    if zns:
        for (qd, bs, concurrent_zones) in [
            (qd, bs, czone) for bs in bss for qd in qds for czone in [1]
        ]:
            job = FioGlobalJob()
            sjob = FioSubJob(f"qd{qd}")
            sjob.add_options(job_defaults)
            sjob.add_options(io_uring_args)
            sjob.add_options(
                [
                    QDOption(qd),
                    ConcurrentWorkerOption(concurrent_zones),
                    RequestSizeOption(bs),
                    SchedulerOption(Scheduler.NONE),
                    OffsetOption(JOB_SIZE_ZNS),
                ]
            )
            job.add_job(sjob)

            # paths
            path = BenchPath(
                IOEngine.IO_URING,
                model,
                lbaf,
                IO_URING_WRITE_NONE_OPTION,
                concurrent_zones,
                qd,
                bs,
            )
            # Write job file
            job_gen.generate_job_file(path.AbsPathJob(), job)
            # Prepare device
            nvme.clean_device()
            # run job
            fio.run_job(path.AbsPathJob(), path.AbsPathOut(), mock=mock)

    # SPDK
    spdk.setup()
    for (qd, bs, concurrent_zones) in [
        (qd, bs, czone) for bs in bss for qd in qds for czone in czones
    ]:
        job = FioGlobalJob()
        sjob = FioSubJob(f"qd{qd}")
        sjob.add_options(job_defaults)
        sjob.add_options(spdk_args)
        sjob.add_options(
            [
                QDOption(qd),
                ConcurrentWorkerOption(concurrent_zones),
                RequestSizeOption(bs),
            ]
        )
        operation = "deadbeef"
        if zns:
            sjob.add_options(
                [
                    ZNSAppendOption(True),
                    StartupZoneResetOption(True),
                    OffsetOption(JOB_SIZE_ZNS),
                ]
            )
            operation = SPDK_APPEND_OP
        else:
            operation = SPDK_WRITE_OP
        job.add_job(sjob)

        # paths
        path = BenchPath(
            IOEngine.SPDK, model, lbaf, operation, concurrent_zones, qd, bs
        )
        # Write job file
        job_gen.generate_job_file(path.AbsPathJob(), job)
        # Prepare device
        spdk.reset()
        nvme.clean_device()
        spdk.setup()
        # run job
        fio.run_job(path.AbsPathJob(), path.AbsPathOut(), mock=mock)

    if zns:
        for (qd, bs, concurrent_zones) in [
            (qd, bs, czone) for bs in bss for qd in qds for czone in [1]
        ]:
            job = FioGlobalJob()
            sjob = FioSubJob(f"qd{qd}")
            sjob.add_options(job_defaults)
            sjob.add_options(spdk_args)
            sjob.add_options(
                [
                    QDOption(qd),
                    ConcurrentWorkerOption(concurrent_zones),
                    RequestSizeOption(bs),
                    ZNSAppendOption(False),
                    StartupZoneResetOption(True),
                    OffsetOption(JOB_SIZE_ZNS),
                ]
            )
            job.add_job(sjob)

            # paths
            path = BenchPath(
                IOEngine.SPDK, model, lbaf, SPDK_WRITE_OP, concurrent_zones, qd, bs
            )
            # Write job file
            job_gen.generate_job_file(path.AbsPathJob(), job)
            # Prepare device
            spdk.reset()
            nvme.clean_device()
            spdk.setup()
            # run job
            fio.run_job(path.AbsPathJob(), path.AbsPathOut(), mock=mock)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Do investigative tests on an NVMe drive in grid fashion"
    )
    parser.add_argument("-d", "--device", type=str, required=True)
    parser.add_argument("-m", "--model", type=str, required=True)
    parser.add_argument("-f", "--fio", type=str, required=True)
    parser.add_argument("-s", "--spdk_dir", type=str, required=True)
    parser.add_argument("-l", "--lbaf", type=str, required=True)
    parser.add_argument("--mock", type=bool, required=False, default=False)
    parser.add_argument("-o", "--overwrite", type=str, required=False, default=False)
    args = parser.parse_args()

    main(
        args.fio,
        args.spdk_dir,
        args.model,
        args.device,
        args.lbaf,
        args.overwrite,
        args.mock,
    )
