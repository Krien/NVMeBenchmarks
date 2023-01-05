import os
import math
import json
from dataclasses import dataclass

DATA_PATH = f"{os.path.realpath(os.path.dirname(__file__))}/../data"


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
    concurrent_zones: int
    qd: int
    bs: int

    def Path(self) -> str:
        return f"{self.engine}/{self.mode}/{self.lbaf}/{self.operation}/{self.bs}bs/{self.concurrent_zones}zone/{self.qd}.json"


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


[0, ' 10980', ' 11265', ' 11665', ' 11210', ' 11324', ' 11155', ' 11284', ' 11011', ' 11443', ' 11159', ' 11288', ' 11273', ' 11108', ' 11066', ' 11356', ' 11209', ' 11120', ' 11276', ' 11376', ' 11311', ' 11149', ' 11162', ' 11188', ' 11170', ' 11250', ' 11190', ' 16074', ' 11129', ' 10885',
    ' 11011', ' 11231', ' 11078', ' 11130', ' 11156', ' 11251', ' 11217', ' 10919', ' 11404', ' 11169', ' 11176', ' 19780', ' 11075', ' 11077', ' 10993', ' 10774', ' 10915', ' 11007', ' 10842', ' 11294', ' 10963', ' 11053', ' 11011', ' 10929', ' 11015', ' 10932', ' 10990', ' 10885', ' 11046', ' 11087']
[11532.116883116883, 10980.0, 11265.0, 11665.0, 11210.0, 11324.0, 11155.0, 11284.0, 11011.0, 11443.0, 11159.0, 11288.0, 11273.0, 11108.0, 11066.0, 11356.0, 11209.0, 11120.0, 11276.0, 11376.0, 11311.0, 11149.0, 11162.0, 11188.0, 11170.0, 11250.0, 11190.0, 16074.0, 11129.0,
    10885.0, 11011.0, 11231.0, 11078.0, 11130.0, 11156.0, 11251.0, 11217.0, 10919.0, 11404.0, 11169.0, 11176.0, 19780.0, 11075.0, 11077.0, 10993.0, 10774.0, 10915.0, 11007.0, 10842.0, 11294.0, 10963.0, 11053.0, 11011.0, 10929.0, 11015.0, 10932.0, 10990.0, 10885.0, 11046.0, 11087.0]


[11366.968614718615, 11021.333333333334, 10998.35, 10978.15, 11031.766666666666, 10998.8, 11032.883333333333, 11039.266666666666, 11067.116666666667, 11025.7, 11022.133333333333, 11349.85, 11191.0, 11221.983333333334, 10742.883333333333, 10737.75, 10936.833333333334, 11074.633333333333, 11034.766666666666, 11017.95, 11062.016666666666, 11036.733333333334, 11015.116666666667, 11080.15, 11082.366666666667, 11071.35, 11013.016666666666, 11040.65, 11067.6, 11015.783333333333,
    11053.883333333333, 11025.066666666668, 11026.116666666667, 11060.366666666667, 11003.416666666666, 11098.766666666666, 11029.466666666667, 11067.6, 11014.8, 11379.55, 11335.166666666666, 10999.733333333334, 11032.1, 11022.433333333332, 11045.833333333334, 11042.733333333334, 11023.666666666666, 11243.7, 11155.0, 11139.033333333333, 11050.216666666667, 11034.25, 11034.166666666666, 11054.833333333334, 11037.216666666667, 11035.433333333332, 11073.1, 11048.3, 11094.45, 11050.75]
