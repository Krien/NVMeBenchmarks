#!/bin/bash

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit

if [ -z FIO_DIR ]; then
    echo "Please provide a path to the FIO_DIR"
    exit 1
fi

if [ -z SPDK_DIR ]; then
    echo "Please provide a path to the SPDK_DIR"
    exit 1
fi

DATA_DIR=data
ENGINES=(spdk io_uring)

mkdir -p ${DATA_DIR}
for engine in ${engines}
    mkdir -p data/${engine}

if [[ "$#" -ne 5 ]]; then
    echo "Please  specify <device name> <NVMe/ZNS> <ns> <lbaf> <page_size>"
    echo "device name should be in format nvme9"
    echo "namespace should be in format 1"
    echo "For the second arg type either NVMe or ZNS"
    echo "Lbaf should be in a format like lbaf0 or lbaf2"
    echo "Pagesize should be numeric like 512 or 4096"
    exit 1
fi
nvme_dev=$1
type=$2
ns=$3
lbaf=$4
test_name=$5

model_str="/sys/block/${nvme_dev}/device/model"
model=$(cat model_str)

addr_str="/sys/block/${nvme_dev}/device/address"
addr=$(cat addr_str)

numa_str="/sys/block/${nvme_dev}/device/numa_node"
numa=$(cat numa_str)

for engine in ${engines}
    mkdir -p data/${engine}/${model_str}
    mkdir -p data/${engine}/${model_str}/${lbaf}

default_args=" --rw=write --direct=1 --time_based=1 --runtime=30s --ramptime=10s --group_reporting=1 --thread=1 --output-format=json"
io_uring_default_args=" --fixedbufs=1 --registerfiles=1 --hipri=1 --sqthread_poll=1 --filename=/dev/${nvme_dev} --ioengine=io_uring "
spdk_filename="\'trtype=PCIe traddr=${addr_str} ns=${ns}\'"
spdk_default_args="  --filename=${spdk_filename} --ioengine=spdk "
fio='LD_PRELOAD=/home/krijn/opt/spdk/build/fio/spdk_nvme  $FIO_DIR/fio'


# QD test
for engine in ${engines}
    mkdir -p data/${engine}/${model_str}/${lbaf}/write
if [[ $type -eq "ZNS" ]]
    mkdir -p data/spdk/${model_str}/${lbaf}/append
    mkdir -p data/io_uring/${model_str}/${lbaf}/writemq
fi

# io_uring
for qd in 1 2 4 8 16 32 64 128 256 512 1024; do
    if [[ $type -eq "ZNS" ]]
        sudo nvme zns reset-zone -a /dev/${nvme9}
        for concurrent_zones in 1 2 3 4 5; do
            mkdir ${DATA_DIR}/io_uring/${model}/writemq/${concurrent_zones};
            sudo $fio $default_args --iodepth=${qd} --output=${DATA_DIR}/io_uring/${model}/writemq/${concurrent_zones}/${qd}.json ${io_uring_default_args} --ioscheduler=mq-deadline --numjobs=${concurrent_zones} --offset_increment=20z --size=20z --zone_mode=zbd;
        done
    else 
        sudo $fio $default_args --iodepth=${qd} --output=${DATA_DIR}/io_uring/${model}/write/1zone/${qd}.json ${io_uring_default_args} --ioscheduler=none --size=40G;
    fi
done
if [[ $type -eq "ZNS" ]]
    sudo nvme zns reset-zone -a /dev/${nvme9}
    sudo $fio $default_args --iodepth=1 --output=${DATA_DIR}/io_uring/${model}/write/1zone/${qd}.json ${io_uring_default_args} --ioscheduler=none --size=20z --zone_mode=zbd;
fi

# SPDK
sudo PCI_ALLOWED="${addr_str}" ${SPDK_DIR}/script/setup.sh
for qd in 1 2 4 8 16 32 64 128 256 512 1024; do
    if [[ $type -eq "ZNS" ]]
        for concurrent_zones in 1 2 3 4 5; do
            mkdir ${DATA_DIR}/spdk/${model}/append/${concurrent_zones};
            sudo $fio $default_args --iodepth=${qd} --output=${DATA_DIR}/spdk/${model}/append/${concurrent_zones}/${qd}.json ${spdk_default_args} --zone_append=1 --initial_zone_reset=1 --numjobs=${concurrent_zones} --offset_increment=20z --size=20z --zone_append=1 --zone_mode=zbd;
        done
    else
        sudo $fio $default_args --iodepth=${qd} --output=${DATA_DIR}/spdk/${model}/write/1zone/${qd}.json ${spdk_default_args} -size=40G;
    fi
done
if [[ $type -eq "ZNS" ]]
    sudo $fio $default_args --iodepth=1 --output=${DATA_DIR}/spdk/${model}/append/${concurrent_zones}/${qd}.json ${spdk_default_args} --zone_append=1 --initial_zone_reset=1 --numjobs=${concurrent_zones} --offset_increment=20z --size=20z --zone_append=0 --zone_mode=zbd;
fi

sudo ${SPDK_DIR}/script/setup.sh reset


# Block penner
if [[ $ype -eq "ZNS" ]]
else
    exit 0
fi

# io_uring
for bs in 512 1024 2048 4096 8192 16384 32768 65536 131072; do
    if [[ bs -ge $page_size ]]
        sudo nvme zns reset-zone -a /dev/${nvme9}
        mkdir ${DATA_DIR}/io_uring/${model}/writemq/bs;
        sudo $fio $default_args --iodepth=4 --bs=${bs} --output=${DATA_DIR}/io_uring/${model}/writemq/${concurrent_zones}/${qd}.json ${io_uring_default_args} --ioscheduler=mq-deadline --size=20z --zone_mode=zbd;
    fi
done

# SPDK
sudo PCI_ALLOWED="${addr_str}" ${SPDK_DIR}/script/setup.sh
for bs in 512 1024 2048 4096 8192 16384 32768 65536 131072; do
    if [[ bs -ge $page_size ]]
        mkdir ${DATA_DIR}/spdk/${model}/append/bs;
        sudo $fio $default_args --iodepth=4 --bs=${bs} --output=${DATA_DIR}/spdk/${model}/append/bs/${qd}.json ${spdk_default_args} --zone_append=1 --initial_zone_reset=1 --size=20z --zone_mode=zbd;
    fi
done
sudo ${SPDK_DIR}/script/setup.sh reset
