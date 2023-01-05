import os
from dataclasses import dataclass

ROOT_PATH = f"{os.path.realpath(os.path.dirname(__file__))}/.."
DATA_PATH = f"{ROOT_PATH}/data"
JOB_PATH = f"{ROOT_PATH}/jobs"
PREDEFINED_JOB_PATH = f"{ROOT_PATH}/predefined_jobs"
PLOT_PATH = f"{ROOT_PATH}/plots"


@dataclass
class BenchPath:
    """Data dir structured"""

    engine: str
    model: str
    lbaf: str
    operation: str
    concurrent_zones: int
    qd: int
    bs: int

    def RelPathDir(self) -> str:
        return f"{self.engine}/{self.model}/{self.lbaf}/{self.operation}/{self.bs}bs/{self.concurrent_zones}zone"

    def RelPathOut(self) -> str:
        return f"{self.RelPathDir()}/{self.qd}.json"

    def RelPathJob(self):
        return f"{self.RelPathDir()}/{self.qd}.fio"

    def AbsPathOut(self) -> str:
        return f"{DATA_PATH}/{self.RelPathOut()}"

    def AbsPathJob(self) -> str:
        return f"{JOB_PATH}/{self.RelPathJob()}"
