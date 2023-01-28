import os
import math
import json
from dataclasses import dataclass
from ..path_utils import BenchPath
from enum import Enum


class FioOperation(Enum):
    WRITE = 1
    READ = 2
    TRIM = 3


def fio_operation_to_string(operation: FioOperation) -> str:
    if operation == FioOperation.WRITE:
        return "write"
    elif operation == FioOperation.READ:
        return "read"
    else:
        return "trim"


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
    lat_stddev: int
    lat_p95: int
    clat_mean: int
    clat_stddev: int
    clat_p95: int
    slat_mean: int
    slat_stddev: int
    slat_p95: int

def stub_fio_lat():
    return {"mean": -1, "stddev": -1}


def parse_data_from_json(json_output, operation: FioOperation) -> FioOutput:
    # Parse main field
    dat = {}
    try:
        dat = json_output["jobs"][0][fio_operation_to_string(operation)]
    except:
        print("Incorrect FIO format")
        raise "Incorrect FIO format"
    # Fallback
    lat = dat["lat_ns"] if "lat_ns" in dat else stub_fio_lat()
    clat = dat["clat_ns"] if "clat_ns" in dat else stub_fio_lat()
    slat = dat["slat_ns"] if "slat_ns" in dat else stub_fio_lat()
    # Nice Python format
    return FioOutput(
        dat["iops_mean"],
        dat["iops_stddev"],
        lat["mean"],
        lat["stddev"],
        lat["percentile"]["95.000000"] if "percentile" in lat else -1,
        clat["mean"],
        clat["stddev"],
        clat["percentile"]["95.000000"] if "percentile" in clat else -1,
        slat["mean"],
        slat["stddev"],
        slat["percentile"]["95.000000"] if "percentile" in slat else -1,
    )


def parse_fio_file(fio_data_path_definition: BenchPath, operation: FioOperation):
    return parse_data_from_json(
        get_json(f"{fio_data_path_definition.AbsPathOut()}"), operation
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
