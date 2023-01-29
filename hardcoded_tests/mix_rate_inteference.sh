#!/bin/bash

# PCIe of ordinary NVMe and ZNS drive
sudo PCI_ALLOWED="0000:87:00.0 0000:88:00.0" ./submodules/spdk/scripts/setup.sh;

# Ordinary NVMe
for iodepth in 1 2 4 8 16 32 64 128 256; do sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio \
	--ioengine=spdk --thread=1 --filename='trtype=PCIe traddr=0000.87.00.0 ns=1' --direct=1 --size=100% --time_based=1 \
	--ramp_time=5s --runtime=3m --lat_percentiles=1  --name=read  --rw=randread --bs=4k --iodepth=${iodepth} --output-format=json \
	--output=./data/custom/zns-a/rate_inteference/nvme_0_${iodepth}; done;

# Ordinary NVMe
for rate in 10 50 100 250 500; do for iodepth in 1 2 4 8 16 32 64 128 256; do sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio \
	--ioengine=spdk --thread=1 --filename='trtype=PCIe traddr=0000.87.00.0 ns=1' --direct=1 --size=100% --time_based=1 --ramp_time=5s --runtime=3m --lat_percentiles=1\
	--name=fill --rw=write --bs=128k --iodepth=1 --rate=,${rate}m --name=read  --rw=randread --bs=4k --iodepth=${iodepth} --output-format=json \
	--output=./data/custom/zns-a/rate_inteference/nvme_${rate}_${iodepth}; done; done;

# ZNS NVMe writes
for iodepth in 1 2 4 8 16 32 64 128 256; do sudo PCI_ALLOWED="0000:87:00.0 0000:88:00.0" ./submodules/spdk/scripts/setup.sh; 
	sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/opt/fio/fio \
		--ioengine=spdk --thread=1 --filename='trtype=PCIe traddr=0000.88.00.0 ns=2' --zonemode=zbd --direct=1  --time_based=1 --ramp_time=5s --runtime=3m --lat_percentiles=1 \
		--name=read --rw=randread --offset=0 --size=400z --bs=4k --iodepth=${iodepth} --output-format=json --output=./data/custom/zns-a/rate_inteference/zns_0_${iodepth};
	sudo ./submodules/spdk/scripts/setup.sh reset; sudo nvme zns finish-zone -a /dev/nvme7n2; done;

# ZNS NVMe writes
for rate in 10 50 100 250 500; do for iodepth in 1 2 4 8 16 32 64 128 256; do sudo PCI_ALLOWED="0000:87:00.0 0000:88:00.0" ./submodules/spdk/scripts/setup.sh; 
	sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio --ioengine=spdk --thread=1 --filename='trtype=PCIe traddr=0000.88.00.0 ns=2' --zonemode=zbd\
		--direct=1  --time_based=1 --ramp_time=5s --runtime=3m --lat_percentiles=1 --name=fill --rw=write --bs=128k --iodepth=1 --rate=,${rate}m --offset=400z --size=400z \
		--name=read --rw=randread --offset=0 --size=400z --bs=4k --iodepth=${iodepth} --output-format=json --output=./data/custom/zns-a/rate_inteference/zns_${rate}_${iodepth}; 
	sudo ./submodules/spdk/scripts/setup.sh reset; sudo nvme zns finish-zone -a /dev/nvme7n2; done; done;

# ZNS NVMe appends
for iodepth in 1 2 4 8 16 32 64 128 256; do sudo PCI_ALLOWED="0000:87:00.0 0000:88:00.0" ./submodules/spdk/scripts/setup.sh; 
	sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio --ioengine=spdk --thread=1 --filename='trtype=PCIe traddr=0000.88.00.0 ns=2' --zonemode=zbd \
		--zone_append=1 --direct=1  --time_based=1 --ramp_time=5s --runtime=3m --lat_percentiles=1  --name=read --rw=randread --offset=0 --size=400z --bs=4k --iodepth=${iodepth}\
		--output-format=json --output=./data/custom/zns-a/rate_inteference/zns_append_0_${iodepth}; 
	sudo ./submodules/spdk/scripts/setup.sh reset; sudo nvme zns finish-zone -a /dev/nvme7n2; done;

# ZNS NVMe appends
for rate in 10 50 100 250 500; do for iodepth in 1 2 4 8 16 32 64 128 256; do sudo PCI_ALLOWED="0000:87:00.0 0000:88:00.0" ./submodules/spdk/scripts/setup.sh; 
	sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio --ioengine=spdk --thread=1 --filename='trtype=PCIe traddr=0000.88.00.0 ns=2' --zonemode=zbd \
		--zone_append=1 --direct=1  --time_based=1 --ramp_time=5s --runtime=3m --lat_percentiles=1 --name=fill --rw=write --bs=128k --iodepth=1 --rate=,${rate}m --offset=400z \
		--size=400z --name=read --rw=randread --offset=0 --size=400z --bs=4k --iodepth=${iodepth} --output-format=json --output=./data/custom/zns-a/rate_inteference/zns_append_${rate}_${iodepth}; 
	sudo ./submodules/spdk/scripts/setup.sh reset; sudo nvme zns finish-zone -a /dev/nvme7n2; done; done;
