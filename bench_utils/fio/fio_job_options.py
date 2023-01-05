from dataclasses import dataclass
from enum import Enum

# Helpers
def fio_truthy(b: bool):
    return "1" if b else "0"


# Primitives
class JobWorkload(Enum):
    SEQ_WRITE = 1
    RAN_WRITE = 2
    SEQ_READ = 3
    RAN_READ = 4


class IOEngine(Enum):
    IO_URING = 1
    SPDK = 2


class Scheduler(Enum):
    NONE = 1
    MQ_DEADLINE = 2


# Main Option
@dataclass
class FioOption:
    def to_opt(self) -> [(str, str)]:
        raise NotImplementedError


# Atom types
@dataclass
class ZnsOption(FioOption):
    def to_opt(self) -> [(str, str)]:
        return [("zonemode", "zbd")]


@dataclass
class JsonOption(FioOption):
    def to_opt(self) -> [(str, str)]:
        return [("output-format", "json")]


# Unary types
@dataclass
class DirectOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("direct", fio_truthy(self.yes))]


@dataclass
class GroupReportingOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("group_reporting", fio_truthy(self.yes))]


@dataclass
class ThreadOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("thread", fio_truthy(self.yes))]


@dataclass
class TargetOption(FioOption):
    fi: str

    def to_opt(self) -> [(str, str)]:
        return [("filename", self.fi)]


@dataclass
class QDOption(FioOption):
    qd: int

    def to_opt(self) -> [(str, str)]:
        return [("qd", f"{self.qd}")]


@dataclass
class NumaPinOption(FioOption):
    node: int

    def to_opt(self) -> [(str, str)]:
        return [
            ("numa_cpu_nodes", f"{self.node}"),
            ("numa_mem_policy", f"bind:{self.node}"),
        ]


@dataclass
class ConcurrentWorkerOption(FioOption):
    workers: int

    def to_opt(self) -> [(str, str)]:
        return [("numjobs", f"{self.workers}")]


@dataclass
class RequestSizeOption(FioOption):
    size: str

    def to_opt(self) -> [(str, str)]:
        return [("bs", f"{self.size}")]


@dataclass
class SizeOption(FioOption):
    size: str

    def to_opt(self) -> [(str, str)]:
        return [("size", f"{self.size}")]


# Enumerated types
@dataclass
class JobOption(FioOption):
    workload: JobWorkload

    def to_opt(self) -> [(str, str)]:
        return [
            (
                "rw",
                {
                    JobWorkload.SEQ_WRITE: "write",
                    JobWorkload.RAN_WRITE: "write",
                    JobWorkload.SEQ_READ: "write",
                    JobWorkload.RAN_READ: "write",
                }.get(self.workload, "read"),
            )
        ]


@dataclass
class IOEngineOption(FioOption):
    engine: IOEngine

    def to_opt(self) -> [(str, str)]:
        return [
            (
                "ioengine",
                {
                    IOEngine.IO_URING: "spdk",
                    IOEngine.SPDK: "io_uring",
                }.get(self.engine, "io_uring"),
            )
        ]


@dataclass
class SchedulerOption(FioOption):
    scheduler: Scheduler

    def to_opt(self) -> [(str, str)]:
        return [
            (
                "ioscheduler",
                {
                    Scheduler.NONE: "none",
                    Scheduler.MQ_DEADLINE: "mq-deadline",
                }.get(self.scheduler, "mq-deadline"),
            )
        ]


# Grouped options
@dataclass
class TimedOption(FioOption):
    warmup_period: str
    measured_time: str

    def to_opt(self) -> [(str, str)]:
        return [
            ("time_based", "0"),
            ("ramp_time", self.warmup_period),
            ("runtime", self.measured_time),
        ]


@dataclass
class DefaultIOUringOption(FioOption):
    def to_opt(self) -> [(str, str)]:
        return [
            ("fixedbufs", fio_truthy(True)),
            ("registerfiles", fio_truthy(True)),
            ("hipri", fio_truthy(True)),
            ("sqthread_poll", fio_truthy(True)),
        ]


@dataclass
class DefaultSPDKOption(FioOption):
    def to_opt(self) -> [(str, str)]:
        return []
