#!/usr/bin/env python3
import os
from bench_utils import *
import argparse

JOB_RAMP = "10s"
JOB_RUN = "120m"

FILL_BS = "128k"
FILL_QD = 1
FILL_RAND_BS = "4k"
FILL_RAND_QD = 1
STEADY_BS = "4k"
STEADY_QD = 1
RAND_BS = "4k"
RAND_QD = 1


def main(
    fio: str,
    model: str,
    device: str,
    lbaf: str,
    overwrite: bool,
    mock: bool,
):
    # Setup tools
    job_gen = FioJobGenerator(overwrite)
    fio = FioRunner(fio, overwrite)
    nvme = NVMeRunnerCLI(device) if not mock else NVMeRunnerMock(device)

    # Investigate device
    zns = nvme.is_zoned()
    numa_node = nvme.get_numa_node()
    min_size = nvme.get_min_request_size()

    if zns:
        print("Rand not supported on ZNS")
        return

    # Clean state
    nvme.clean_device()

    # Prefill
    fill_path = BenchPath(
        IOEngine.IO_URING, model, lbaf, "prefill", 1, FILL_QD, FILL_BS
    ).AbsPathOut()
    fio.run_job(
        f"{PREDEFINED_JOB_PATH}/precodition_fill.fio",
        fill_path,
        [f"FILENAME=/dev/{device}", f"BW_PATH={fill_path}", f"LOG_PATH={fill_path}"],
        mock=mock,
    )

    # Prefill rand
    fill_rand_path = BenchPath(
        IOEngine.IO_URING, model, lbaf, "rand_fill", 1, FILL_RAND_QD, FILL_RAND_BS
    ).AbsPathOut()
    fio.run_job(
        f"{PREDEFINED_JOB_PATH}/precodition_rand_nvme.fio",
        fill_rand_path,
        [
            f"FILENAME=/dev/{device}",
            f"BW_PATH={fill_rand_path}",
            f"LOG_PATH={fill_rand_path}",
            f"BS={FILL_RAND_BS}",
        ],
        mock=mock,
    )

    # steady_state path
    steady_path = BenchPath(
        IOEngine.IO_URING, model, lbaf, "steady", 1, STEADY_QD, STEADY_BS
    ).AbsPathOut()
    fio.run_job(
        f"{PREDEFINED_JOB_PATH}/steady_state_nvme.fio",
        steady_path,
        [
            f"FILENAME=/dev/{device}",
            f"BW_PATH={steady_path}",
            f"LOG_PATH={steady_path}",
            f"BS={STEADY_BS}",
            f"STEADY=1%",
        ],
        mock=mock,
    )

    job_defaults = [
        DirectOption(True),
        GroupReportingOption(True),
        JsonOption(),
        ThreadOption(True),
        TimedOption(JOB_RAMP, JOB_RUN),
        NumaPinOption(numa_node),
        IOEngineOption(IOEngine.IO_URING),
        DefaultIOUringOption(),
        TargetOption(f"/dev/{device}"),
        JobOption(JobWorkload.RAN_WRITE),
        RequestSizeOption(RAND_BS),
        QDOption(RAND_QD),
    ]

    job = FioGlobalJob()
    sjob = FioSubJob(f"qd{RAND_QD}")
    # paths
    path = BenchPath(IOEngine.IO_URING, model, lbaf, "randwrite", 1, RAND_BS, RAND_QD)
    sjob.add_options(job_defaults)
    # Do not leak paths in job file, use env var
    sjob.add_option2("write_bw_log", "${BW_PATH}")
    sjob.add_option2("write_lat_log", "${LOG_PATH}")
    sjob.add_option2("log_avg_msec", "10ms")
    job.add_job(sjob)

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
    parser.add_argument("-m", "--model", type=str, required=True)
    parser.add_argument("-f", "--fio", type=str, required=True)
    parser.add_argument("-l", "--lbaf", type=str, required=True)
    parser.add_argument("--mock", type=bool, required=False, default=False)
    parser.add_argument("-o", "--overwrite", type=str, required=False, default=False)
    args = parser.parse_args()

    main(
        args.fio,
        args.model,
        args.device,
        args.lbaf,
        args.overwrite,
        args.mock,
    )
