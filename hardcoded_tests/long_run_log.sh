#!/bin/bash

sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio --ioengine=spdk --direct=1 --offset=0 \
    --size=100% --filename='trtype=PCIe traddr=0000.af.00.0 ns=1' --rw=write --thread=1 --time_based=1 --runtime=240m \
    --ramp_time=5 --name=rw --iodepth=32 --numjobs=1 --bs=4096 --lat_percentiles=1 --percentile_list=50:75:90:95:99:99.9:99.999 \
    --log_avg_msec=5000 --write_iops_log=nvme_fill_4 --write_lat_log=nvme_fill_4

sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio --ioengine=spdk --direct=1 --offset=0 \
    --size=100% --filename='trtype=PCIe traddr=0000.b0.00.0 ns=2' --zonemode=zbd --rw=write --thread=1 --time_based=1 \
    --runtime=240m --ramp_time=5 --name=rw --iodepth=32 --numjobs=1 --bs=4096 --lat_percentiles=1 \
    --percentile_list=50:75:90:95:99:99.9:99.999 --log_avg_msec=5000 --write_iops_log=zns_fill_4 --write_lat_log=zns_fill_4

sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio --ioengine=spdk --direct=1 --offset=0 \
    --size=100% --filename='trtype=PCIe traddr=0000.af.00.0 ns=1' --rw=write --thread=1 --loops=4 --name=rw --iodepth=32 \
    --numjobs=1 --bs=4096 --lat_percentiles=1 --percentile_list=50:75:90:95:99:99.9:99.999 --log_avg_msec=5000 \
    --write_iops_log=nvme_fill_2 --write_lat_log=nvme_fill_2

sudo LD_PRELOAD=./submodules/spdk/build/fio/spdk_nvme ./submodules/fio/fio --ioengine=spdk --direct=1 --offset=0 \
    --size=100% --filename='trtype=PCIe traddr=0000.b0.00.0 ns=2' --zonemode=zbd --rw=write --zone_append=1 --thread=1 \
    --loops=4 --name=rw --iodepth=32 --numjobs=1 --bs=4096 --lat_percentiles=1 --percentile_list=50:75:90:95:99:99.9:99.999 \
    --log_avg_msec=5000 --write_iops_log=zns_fill_2 --write_lat_log=zns_fill_2
