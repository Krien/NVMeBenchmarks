import os
import subprocess
from .nvme_utils import NVMeRunner

class SPDKRunner():
    def __init__(self, spdk_dir, devices, nvme_factory, options={}):
        self.spdk_dir = spdk_dir
        self.devices = devices
        self.nvmes = {device : nvme_factory(device) for device in devices}
        self.options = options

    def get_spdk_pcie_address(self, device):
        if not device in self.devices:
            raise "Device is not loaded"
        return self.nvmes[device].get_pcie_address().replace(':', '.')

    def  get_spdk_ns(self, device):
        if not device in self.devices:
            raise "Device is not loaded"
        return self.nvmes[device].get_ns()

    def get_spdk_traddress(self, device):
       return f'"trtype=PCIe traddr={self.get_spdk_pcie_address(device)} ns={self.get_spdk_ns(device)}"'


class SPDKRunnerCLI(SPDKRunner):
    def setup(self):
        device_addrs = [self.get_spdk_pcie_address(dev) for dev in self.devices]
        pcie_allowed = f'PCI_ALLOWED="{" ".join(device_addrs)}"'
        env_vars = pcie_allowed
        if 'numa' in self.options:
            env_vars = f'HUGENODE={self.options["numa"]} {env_vars}'
        cmd = f'{env_vars} {self.spdk_dir}/scripts/setup.sh'
        subprocess.check_call(cmd, shell=True)

    def reset(self):
        cmd = f'{self.spdk_dir}/scripts/setup.sh reset'
        subprocess.check_call(cmd, shell=True)

class SPDKRunnerMock(SPDKRunner):
    def setup(self):
        device_addrs = [self.get_spdk_pcie_address(dev) for dev in self.devices]
        pcie_allowed = f'PCI_ALLOWED="{" ".join(device_addrs)}"'
        env_vars = pcie_allowed
        if 'numa' in self.options:
            env_vars = f'HUGENODE={self.options["numa"]} {env_vars}'
        cmd = f'{env_vars} {self.spdk_dir}/scripts/setup.sh'
        print(cmd)

    def reset(self):
        cmd = f'{self.spdk_dir}/scripts/setup.sh reset'
        print(cmd)
