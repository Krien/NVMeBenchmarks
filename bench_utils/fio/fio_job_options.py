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


def io_engine_to_string(engine: IOEngine) -> str:
    return {
        IOEngine.IO_URING: "io_uring",
        IOEngine.SPDK: "spdk",
    }.get(engine, "deadbeef")


def string_to_io_engine(engine: str) -> IOEngine:
    return {
        "io_uring": IOEngine.IO_URING,
        "spdk": IOEngine.SPDK,
    }.get(engine, IOEngine.IO_URING)


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
        return [("iodepth", f"{self.qd}")]


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


@dataclass
class OffsetOption(FioOption):
    offset: str

    def to_opt(self) -> [(str, str)]:
        return [("offset_increment", f"{self.offset}")]


@dataclass
class DelayOption(FioOption):
    delay: str

    def to_opt(self) -> [(str, str)]:
        return [("startdelay", f"{self.delay}")]


@dataclass
class StartupZoneResetOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("initial_zone_reset", f"{fio_truthy(self.yes)}")]


@dataclass
class ZNSAppendOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("zone_append", f"{fio_truthy(self.yes)}")]


@dataclass
class Io_uringFixedBufsOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("fixedbufs", f"{fio_truthy(self.yes)}")]


@dataclass
class Io_uringRegisterFilesOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("registerfiles", f"{fio_truthy(self.yes)}")]


@dataclass
class Io_uringHipriOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("fixedbufs", f"{fio_truthy(self.yes)}")]


@dataclass
class Io_uringSqthreadPollOption(FioOption):
    yes: bool

    def to_opt(self) -> [(str, str)]:
        return [("sqthread_poll", f"{fio_truthy(self.yes)}")]


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
                    JobWorkload.RAN_WRITE: "writerand",
                    JobWorkload.SEQ_READ: "read",
                    JobWorkload.RAN_READ: "readrand",
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
                io_engine_to_string(self.engine),
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
            ("time_based", fio_truthy(True)),
            ("ramp_time", self.warmup_period),
            ("runtime", self.measured_time),
        ]


@dataclass
class DefaultIOUringOption(FioOption):
    def to_opt(self) -> [(str, str)]:
        return (
            Io_uringFixedBufsOption(True).to_opt()
            + Io_uringRegisterFilesOption(True).to_opt()
            + Io_uringHipriOption(True).to_opt()
            + Io_uringSqthreadPollOption(True).to_opt()
        )


@dataclass
class DefaultSPDKOption(FioOption):
    def to_opt(self) -> [(str, str)]:
        return []
