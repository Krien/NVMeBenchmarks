#!/bin/bash

for percent in 99 95 90 75 50; do for depth in 1 2 4 8 14; do sudo PCI_ALLOWED="0000:b0:00.0" ./submodule/spdk/scripts/setup.sh; 
    sudo numactl -C 1 -m 1 ./fior --ioengine=spdk  --direct=1 --filename='trtype=PCIe traddr=0000.b0.00.0 ns=2' --zonemode=zbd \
        --zone_append=0 --thread=1 --time_based=1 --runtime=1m --ramp_time=5  --bs=4096 --flow_sleep=1  --name=read --rw=read --offset=0z \
        --iodepth=${depth} --size=1z --flow=$((${percent}*depth))  --name=write1 --offset=100z --size=100z --offset_increment=100z --rw=write \
        --numjobs=${depth} --job_max_open_zones=1 --flow=$((100-${percent}))  --output-format=json \
        --output=./data/inteference/mixratio/spdk_${percent}_conc_${depth}.json \
        --lat_percentiles=1 --percentile_list=50:75:90:95:99:99.9:99.999; 
    sudo ./submodule/spdk/scripts/setup.sh reset; 
    sudo ./submodule/nvme-cli/.build/nvme zns finish-zone -a /dev/nvme6n2;  done; done;
