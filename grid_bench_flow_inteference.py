#!/usr/bin/env python3
import os
from bench_utils import *
import argparse

# Magic constants
JOB_SIZE_ZNS: str = "100%"
JOB_SIZE_NVME: str = "100%"
JOB_RAMP: str = "10s"
JOB_RUN: str = "1m"

# Grid
JOB_QDS: list[int] = [1, 2, 4, 8, 16, 32, 64]
JOB_BSS: list[int] = [4096, 8192, 16384]
JOB_TOKENS: list[int] = [1,5,10,25,50]

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
    dry_run: bool,
):
    # Setup tools
    job_gen = FioJobGenerator(overwrite)
    fio_opts = FioRunnerOptions(overwrite=overwrite, parse_only=dry_run)
    fio = FioRunner(fio, fio_opts)
    fio.LD_PRELOAD(f"{spdk_dir}/build/fio/spdk_nvme")
    nvme = NVMeRunnerCLI(device) if not (mock or dry_run) else NVMeRunnerMock(device)

    # Investigate device
    zns = nvme.is_zoned()
    numa_node = nvme.get_numa_node()
    min_size = nvme.get_min_request_size()
    max_open_zones = nvme.get_max_open_zones() if zns else -1

    if (not zns):
      print("This test requises a ZNS device")
      return

    # spdk setup
    spdk = (
        SPDKRunnerCLI(
            spdk_dir, [device], lambda dev: NVMeRunnerCLI(dev), {"numa": numa_node}
        )
        if not (mock or dry_run)
        else SPDKRunnerMock(
            spdk_dir, [device], lambda dev: NVMeRunnerMock(dev), {"numa": numa_node}
        )
    )

    # Setup grid
    qds = JOB_QDS
    bss = [bs for bs in JOB_BSS if bs >= min_size]
    JOB_SIZE_ZNS = f"{nvme.get_nr_zones()//2}z"
    tokens = JOB_TOKENS

    # Setup default job args
    job_defaults = [
        DirectOption(True),
        ThreadOption(True),
        TimedOption(JOB_RAMP, JOB_RUN),
        HighTailLatencyOption(),
        NumaPinOption(numa_node),
        ZnsOption(),
        MaxOpenZonesOption(max_open_zones)
    ]

    io_uring_args = [
        IOEngineOption(IOEngine.IO_URING),
        DefaultIOUringOption(),
        TargetOption(f"/dev/{device}"),
    ]
    spdk_filename = spdk.get_spdk_traddress(device)
    spdk_args = [IOEngineOption(IOEngine.SPDK), TargetOption(spdk_filename)]

    # Fill device
    fill_path = BenchPath(
        IOEngine.IO_URING, model, lbaf, "prefill_grid", 1, 1, "128K"
    ).AbsPathOut()
    fio.run_job(
        f"{PREDEFINED_JOB_PATH}/precondition_fill.fio",
        fill_path,
        [
            f"FILENAME=/dev/{device}",
            f"BW_PATH={fill_path}",
            f"LOG_PATH={fill_path}",
        ],
        [
            f"zonemode={'zbd' if zns else 'none'}",
            f"loops=4",
        ],
        mock=mock,
    )

    configs = [("adjacent","1z","1z","1z"),
               ("offset","1z","100z","1z"),
               ("offset_far","1z",f"{nvme.get_nr_zones()-2}z", "1z"),
               ("strip","200z","200z","200z"),
               ("strip_far","200z",f"{nvme.get_nr_zones()-202}z","200z")]
    # io_uring grid search
    for (qd, bs, token, config) in [
        (qd, bs, token, config) for bs in bss for qd in qds for token in tokens for config in configs
    ]:
        # define job
        job = FioGlobalJob()
        job.add_options(job_defaults)
        job.add_options(io_uring_args)
        job.add_options([SchedulerOption(Scheduler.MQ_DEADLINE)])

        operation = f"read_writemq_{token}_{100-token}_{config[0]}"

        read_job = FioSubJob(f"read_4096")
        read_job.add_options(
            [
                QDOption(1),
                RequestSizeOption(f"{4096}"),
                JobOption(JobWorkload.RAN_READ),
                SizeOption(config[1]),
                FlowOption(100-token)
            ]
        )
        job.add_job(read_job)

        write_job = FioSubJob(f"write_{qd}_{bs}")
        write_job.add_options(
            [
                QDOption(qd),
                RequestSizeOption(f"{bs}"),
                JobOption(JobWorkload.SEQ_WRITE),
                SizeOption(config[3]),
                FixedOffsetOption(config[2]),
                FlowOption(-token)
            ]
        )
        job.add_job(write_job)


        # paths
        path = BenchPath(
            IOEngine.IO_URING, model, lbaf, operation, 1, qd, bs
        )
        # Write job file
        job_gen.generate_job_file(path.AbsPathJob(), job)
        # Prepare device
        nvme.finish_all_zones()
        # run job
        try:
            fio.run_job(path.AbsPathJob(), path.AbsPathOut(), mock=mock)
        except:
            print(f"Failed for qd={qd}, bs={bs}, token={token}")

    # io_uring grid search
    for (qd, bs, token, config) in [
        (qd, bs, token, config) for bs in bss for qd in [1] for token in tokens for config in configs
    ]:
        # define job
        job = FioGlobalJob()
        job.add_options(job_defaults)
        job.add_options(io_uring_args)
        job.add_options([SchedulerOption(Scheduler.NONE)])

        operation = f"read_write_{token}_{100-token}_{config[0]}"

        read_job = FioSubJob(f"read_4096")
        read_job.add_options(
            [
                QDOption(1),
                RequestSizeOption(f"{4096}"),
                JobOption(JobWorkload.RAN_READ),
                SizeOption(config[1]),
                FlowOption(100-token)
            ]
        )
        job.add_job(read_job)

        write_job = FioSubJob(f"write_{qd}_{bs}")
        write_job.add_options(
            [
                QDOption(qd),
                RequestSizeOption(f"{bs}"),
                JobOption(JobWorkload.SEQ_WRITE),
                SizeOption(config[3]),
                FixedOffsetOption(config[2]),
                FlowOption(-token)
            ]
        )
        job.add_job(write_job)


        # paths
        path = BenchPath(
            IOEngine.IO_URING, model, lbaf, operation, 1, qd, bs
        )
        # Write job file
        job_gen.generate_job_file(path.AbsPathJob(), job)
        # Prepare device
        nvme.finish_all_zones()
        # run job
        try:
            fio.run_job(path.AbsPathJob(), path.AbsPathOut(), mock=mock)
        except:
            print(f"Failed for qd={qd}, bs={bs}, token={token}")



    # SPDK
    spdk.setup()
    for (qd, bs, token, config) in [
        (qd, bs, token, config) for bs in bss for qd in qds for token in tokens for config in configs
    ]:
        job = FioGlobalJob()
        job.add_options(job_defaults)
        job.add_options(spdk_args)

        operation = f"read_append_{token}_{100-token}_{config[0]}"

        read_job = FioSubJob(f"read_4096")
        read_job.add_options(
            [
                QDOption(1),
                RequestSizeOption(f"{4096}"),
                JobOption(JobWorkload.RAN_READ),
                SizeOption(config[1]),
                FlowOption(100-token)
            ]
        )
        job.add_job(read_job)

        write_job = FioSubJob(f"write_{qd}_{bs}")
        write_job.add_options(
            [
                QDOption(qd),
                RequestSizeOption(f"{bs}"),
                JobOption(JobWorkload.SEQ_WRITE),
                SizeOption(config[3]),
                FixedOffsetOption(config[2]),
                FlowOption(-token),
                ZNSAppendOption(True),
            ]
        )
        job.add_job(write_job)

        # paths
        path = BenchPath(
            IOEngine.SPDK, model, lbaf, operation, 1, qd, bs
        )
        # Write job file
        job_gen.generate_job_file(path.AbsPathJob(), job)
        # Prepare device
        spdk.reset()
        # Prepare device
        nvme.finish_all_zones()
        spdk.setup()
        # run job
        try:
            fio.run_job(path.AbsPathJob(), path.AbsPathOut(), mock=mock)
        except:
            print(f"Failed for qd={qd}, bs={bs}, token={token}")

    for (qd, bs, token, config) in [
        (qd, bs, token, config) for bs in bss for qd in [1] for token in tokens for config in configs
    ]:
        job = FioGlobalJob()
        job.add_options(job_defaults)
        job.add_options(spdk_args)

        operation = f"read_write_{token}_{100-token}_{config[0]}"

        read_job = FioSubJob(f"read_4096")
        read_job.add_options(
            [
                QDOption(1),
                RequestSizeOption(f"{4096}"),
                JobOption(JobWorkload.RAN_READ),
                SizeOption(config[1]),
                FlowOption(100-token)
            ]
        )
        job.add_job(read_job)

        write_job = FioSubJob(f"write_{qd}_{bs}")
        write_job.add_options(
            [
                QDOption(qd),
                RequestSizeOption(f"{bs}"),
                JobOption(JobWorkload.SEQ_WRITE),
                SizeOption(config[3]),
                FixedOffsetOption(config[2]),
                FlowOption(-token),
                ZNSAppendOption(False),
            ]
        )
        job.add_job(write_job)

        # paths
        path = BenchPath(
            IOEngine.SPDK, model, lbaf, operation, 1, qd, bs
        )
        # Write job file
        job_gen.generate_job_file(path.AbsPathJob(), job)
        # Prepare device
        spdk.reset()
        # Prepare device
        nvme.finish_all_zones()
        spdk.setup()
        # run job
        try:
            fio.run_job(path.AbsPathJob(), path.AbsPathOut(), mock=mock)
        except:
            print(f"Failed for qd={qd}, bs={bs}, token={token}")
    spdk.reset()


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
    parser.add_argument("--dry_run", type=bool, required=False, default=False)
    args = parser.parse_args()

    main(
        args.fio,
        args.spdk_dir,
        args.model,
        args.device,
        args.lbaf,
        args.overwrite,
        args.mock,
        args.dry_run,
    )
