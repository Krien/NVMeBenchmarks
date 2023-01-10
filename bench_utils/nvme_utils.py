import os
import subprocess

mock_nvme_database = {
    "mockznsn0": {
        "ns": 0,
        "zoned": True,
        "lba": 8192,
        "numa": 3,
        "address": "00:88:00.0",
        "max_open": 3,
        "min": 8192 * 2,
    },
    "mockznsn1": {
        "ns": 1,
        "zoned": True,
        "lba": 8192,
        "numa": 3,
        "address": "00:88:00.0",
        "max_open": 3,
        "min": 8192 * 2,
    },
    "mockznsn2": {
        "ns": 2,
        "zoned": True,
        "lba": 8192,
        "numa": 3,
        "address": "00:88:00.0",
        "max_open": 3,
        "min": 8192 * 2,
    },
    "mockznsn3": {
        "ns": 3,
        "zoned": True,
        "lba": 8192,
        "numa": 3,
        "address": "00:88:00.0",
        "max_open": 3,
        "min": 8192 * 2,
    },
    "mocknvmen0": {
        "ns": 0,
        "zoned": False,
        "lba": 512,
        "numa": 0,
        "address": "00:00:09.0",
        "min": 512,
    },
    "mocknvmen1": {
        "ns": 1,
        "zoned": False,
        "lba": 512,
        "numa": 0,
        "address": "00:00:09.0",
        "min": 512,
    },
}


class NVMeRunner:
    def __init__(self, device):
        self.device = device

    def reset_zones(self):
        raise NotImplementedError

    def secure_erase(self):
        raise NotImplementedError

    def finish_all_zones(self):
        raise NotImplementedError

    def clean_device(self):
        if self.is_zoned():
            self.reset_zones()
        else:
            self.secure_erase()

    def get_ns(self):
        nsid = 0
        with open(f"/sys/class/block/{self.device}/nsid", "r") as f:
            nsid = int(f.readline())
            return nsid

    def is_zoned(self):
        zoned = False
        with open(f"/sys/class/block/{self.device}/queue/zoned", "r") as f:
            zoned = "none" not in f.readline().strip()
        return zoned

    def get_lba_size(self):
        lba_size = 0
        with open(f"/sys/class/block/{self.device}/queue/logical_block_size", "r") as f:
            lba_size = int(f.readline())
        return lba_size

    def get_numa_node(self):
        numa_node = 0
        with open(f"/sys/class/block/{self.device}/device/numa_node", "r") as f:
            numa_node = int(f.readline())
        return numa_node

    def get_pcie_address(self):
        address = ""
        with open(f"/sys/class/block/{self.device}/device/address", "r") as f:
            address = f.readline().strip()
        return address

    def get_nr_zones(self):
        if not self.is_zoned():
            return -1
        nr_zones = 0
        with open(f"/sys/class/block/{self.device}/queue/nr_zones", "r") as f:
            nr_zones = int(f.readline())
        return nr_zones

    def get_max_open_zones(self):
        if not self.is_zoned():
            return -1
        max_open = 0
        with open(f"/sys/class/block/{self.device}/queue/max_open_zones", "r") as f:
            max_open = int(f.readline())
        return max_open

    def get_min_request_size(self):
        min_size = 0
        with open(f"/sys/class/block/{self.device}/queue/minimum_io_size", "r") as f:
            min_size = int(f.readline())
        return min_size


class NVMeRunnerCLI(NVMeRunner):
    def reset_zones(self):
        subprocess.check_call(f"nvme zns reset-zone -a /dev/{self.device}", shell=True)

    def secure_erase(self):
        subprocess.check_call(f"nvme format -s 1 /dev/{self.device}", shell=True)

    def finish_all_zones(self):
        subprocess.check_call(f"nvme zns finish-zone -a /dev/{self.device}", shell=True)


class NVMeRunnerMock(NVMeRunner):
    def reset_zones(self):
        print(f"nvme zns reset-zone -a /dev/{self.device}")

    def secure_erase(self):
        print(f"nvme format -s 1 /dev/{self.device}")

    def finish_all_zones(self):
        print(f"nvme zns finish-zone -a /dev/{self.device}")

    def get_ns(self):
        if self.device in mock_nvme_database:
            return mock_nvme_database[self.device]["ns"]
        return NVMeRunner.get_ns(self)

    def is_zoned(self):
        if self.device in mock_nvme_database:
            return mock_nvme_database[self.device]["zoned"]
        return NVMeRunner.is_zoned(self)

    def get_lba_size(self):
        if self.device in mock_nvme_database:
            return mock_nvme_database[self.device]["lba"]
        return NVMeRunner.get_lba_size(self)

    def get_numa_node(self):
        if self.device in mock_nvme_database:
            return mock_nvme_database[self.device]["numa"]
        return NVMeRunner.get_numa_node(self)

    def get_pcie_address(self):
        if self.device in mock_nvme_database:
            return mock_nvme_database[self.device]["address"]
        return NVMeRunner.get_pcie_address(self)

    def get_max_open_zones(self):
        if self.device in mock_nvme_database:
            return mock_nvme_database[self.device]["max_open"]
        return NVMeRunner.get_max_open_zones(self)

    def get_min_request_size(self):
        if self.device in mock_nvme_database:
            return mock_nvme_database[self.device]["min"]
        return NVMeRunner.get_min_request_size(self)
