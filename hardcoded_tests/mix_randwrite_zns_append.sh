#!/bin/bash

for percent in 100 99 95 90 75 50; do for depth in 1 2 4 8 16 32 64 128; do sudo PCI_ALLOWED="0000:b0:00.0" ./submodule/spdk/scripts/setup.sh; 
    sudo numactl -C 1 -m 1 ./fio_spdk_wrapper.sh --ioengine=spdk  --direct=1 --offset=0 --size=100% --filename='trtype=PCIe traddr=0000.b0.00.0 ns=2' --zonemode=zbd \
        --rw=randrw --rwmixread=$percent --zone_append=1 --thread=1 --time_based=1 --runtime=20m --ramp_time=5  --name=rw --iodepth=$depth --numjobs=1 \
        --bs=4096 --output-format=json --output=./data/inteference/mixratio/spdk_${percent}_${depth}.json --lat_percentiles=1 \
        --percentile_list=50:75:90:95:99:99.9:99.999; 
    sudo ./submodule/spdk/scripts/setup.sh reset; 
    sudo ./submodule/nvme-cli/.build/nvme zns finish-zone -a /dev/nvme6n2;  done; done;
