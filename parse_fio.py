import os
import math
import json
from dataclasses import dataclass

DATA_PATH = f"{os.path.realpath(os.path.dirname(__file__))}/data"


def get_json(path):
    output = {}
    with open(f"{path}") as f:
        output = json.load(f)
    return output


@dataclass
class FioOutput:
    """Fio Output"""

    iops_mean: int
    iops_stddev: int
    lat_mean: int
    lat_stdef: int
    clat_mean: int
    clat_stdef: int
    slat_mean: int
    slat_stdef: int


def stub_fio_lat():
    return {"mean": -1, "stddev": -1}


def parse_data_from_json(json_output):
    # Parse main field
    write_dat = {}
    try:
        write_dat = json_output["jobs"][0]["write"]
    except:
        print("Incorrect FIO format")
        raise "Incorrect FIO format"
    # Fallback
    lat = write_dat["lat_ns"] if "lat_ns" in write_dat else stub_fio_lat()
    clat = write_dat["clat_ns"] if "clat_ns" in write_dat else stub_fio_lat()
    slat = write_dat["slat_ns"] if "slat_ns" in write_dat else stub_fio_lat()
    # Nice Python format
    return FioOutput(
        write_dat["iops_mean"],
        write_dat["iops_stddev"],
        lat["mean"],
        lat["stddev"],
        clat["mean"],
        clat["stddev"],
        slat["mean"],
        slat["stddev"],
    )


@dataclass
class DataPath:
    """Data dir structured"""

    engine: str
    mode: str
    lbaf: str
    operation: str
    concurrent_zones: str
    qd: str

    def Path(self) -> str:
        return f"{self.engine}/{self.mode}/{self.lbaf}/{self.operation}/{self.concurrent_zones}/{self.qd}qd.json"


def parse_fio_file(fio_data_path_definition):
    return parse_data_from_json(
        get_json(f"{DATA_PATH}/{fio_data_path_definition.Path()}")
    )


def divide_by_1000(x):
    return x / 1000


def divide_by1000_and_2log(x):
    return math.log(x / 1000, 2)


def prep_function(q, x):
    if q == "none":
        return x
    elif q == "div1000":
        return divide_by_1000(x)
    else:
        return divide_by1000_and_2log(x)
