import os
from enum import Enum
from dataclasses import dataclass
from .fio_job_options import FioOption

# ...EXAMPLE...
# jo = FioGlobalJob()
# jo.add_option2("io_engine", "io_uring")
# jo.add_option("hipri")
#
# jo1 = FioSubJob("test")
# jo1.add_option2("size","2G")
# jo.add_job(jo1)
#
# print(jo.stringify())
#
# jobg = FioJobGenerator()
# jobg.generate_job_file('test', jo)


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

    def add_job(self, job: FioSubJob):
        self.subjobs.append(job)

    def stringify(self) -> str:
        st = FioJobDescription.stringify(self)
        for job in self.subjobs:
            st += "\n"
            st += job.stringify()
        return st


class FioJobGenerator:
    """Generates Fio jobs"""

    def __init__(self):
        pass

    def __setup_dirs(self, path):
        jobpath = os.path.dirname(path)
        os.makedirs(jobpath, exist_ok=True)
        self.jobpath = jobpath

    def generate_job_file(self, path: str, job: FioJobDescription):
        self.__setup_dirs(path)
        with open(f"{path}", "w") as f:
            f.write(job.stringify())
