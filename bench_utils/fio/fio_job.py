import os
from enum import Enum
from dataclasses import dataclass
from .fio_job_options import FioOption
import datetime


class FioJobDescription:
    """Structure to hold Fio jobs"""

    def __init__(self):
        self.options = []
        self.header = "[?]"

    def add_option(self, opt: str):
        self.options.append(opt)

    def add_option2(self, opt: str, val: str):
        self.options.append(f"{opt}={val}")

    def add_raw_options(self, opts: list[(str, str)]):
        for opt, val in opts:
            self.options.append(f"{opt}={val}" if val is not None else opt)

    def add_options(self, opts: list[FioOption]):
        for opt in opts:
            self.add_raw_options([t for t in opt.to_opt()])

    def stringify(self) -> str:
        lines = [self.header]
        lines += self.options
        st = "\n".join(lines) + "\n"
        return st


class FioSubJob(FioJobDescription):
    """Structure to hold a sub Fio job"""

    def __init__(self, name):
        FioJobDescription.__init__(self)
        self.header = f"[{name}]"


class FioGlobalJob(FioJobDescription):
    """Structure to hold the main Fio job"""

    GLOBAL_HEADER = "[global]"

    def __init__(self):
        FioJobDescription.__init__(self)
        self.subjobs = []
        self.header = self.GLOBAL_HEADER

    def add_time_comment(self) -> str:
        return f"; -- CREATED ON {datetime.datetime.now()} ---" "\n"

    def add_job(self, job: FioSubJob):
        self.subjobs.append(job)

    def stringify(self) -> str:
        st = self.add_time_comment()
        st = st + FioJobDescription.stringify(self)
        for job in self.subjobs:
            st += "\n"
            st += job.stringify()
        return st


class FioJobGenerator:
    """Generates Fio jobs"""

    def __init__(self, overwrite=False):
        self.overwrite = overwrite

    def __setup_dirs(self, path):
        jobpath = os.path.dirname(path)
        os.makedirs(jobpath, exist_ok=True)
        self.jobpath = jobpath

    def compare_existing_job(self, path: str, job: FioJobDescription):
        this = job.stringify().splitlines()
        lines = []
        with open(f"{path}", "r") as f:
            lines = f.readlines()
        if len(lines) != len(this):
            print(f"Job file is different len {len(this)} -> {len(lines)}!")
            return
        line = 0
        for l1, l2 in zip(this, lines):
            l1 = l1.strip()
            l2 = l2.strip()
            if (len(l1) and l1[0] != ";") and (len(l2) and l2[0] != ";") and l1 != l2:
                print(
                    f"Job file is different at line {line}:" "\n" f"-{l1}" "\n" f"+{l2}"
                )
                return
            line = line + 1
        return

    def generate_job_file(self, path: str, job: FioJobDescription):
        if not self.overwrite and os.path.exists(path):
            print(f"Job file {path} already exists, enable overwrite to enable")
            self.compare_existing_job(path, job)
            return
        self.__setup_dirs(path)
        with open(f"{path}", "w") as f:
            f.write(job.stringify())
