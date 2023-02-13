#!/bin/bash

for percent in 100 99 95 90 75 50; do for depth in 1 2 4 8 16 32 64 128 256; do sudo numactl -C 1 -m 1 /mnt/sdb/anon/opt/fio/fio \
    --ioengine=io_uring --fixedbufs=1 --hipri --sqthread_poll=1 --registerfiles=1 --direct=1 --offset=0 --size=100% --filename=/dev/nvme6n2 \
    --zonemode=zbd --rw=randrw --rwmixread=$percent --thread=1 --time_based=1 --runtime=20m --ramp_time=5  --name=rw --iodepth=$depth --numjobs=1 \
    --bs=4096 --output-format=json --output=./data/inteference/mixratio)${percent}_${depth}.json --lat_percentiles=1 --percentile_list=50:75:90:95:99:99.9:99.999; 
    sudo ./nvme-cli/.build/nvme zns finish-zone -a /dev/nvme6n2;  done; done;
