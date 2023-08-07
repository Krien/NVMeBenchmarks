#!/bin/bash

set -e

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
cd "$DIR" || exit;

SUBMOD_DIR=${DIR}/../submodules
DATA_DIR=${DIR}/.${DATA_DIR}

if [ -z "$1" ]; then
    echo "Args <NVMe_dev> <NUMA_DOMAIN> missing"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Second arg <NUMA_DOMAIN> missing"
    exit 1
fi

# Transformative
DEVICE=$1
NUMA_DOMAIN=$2

DEVICE_ADDR="/sys/block/${DEVICE}/device/address";
DEVICE_ADDR=$(cat ${DEVICE_ADDR});
DEVICE_SPDK_ADDR=$(echo ${DEVICE_ADDR} | sed 's/\:/./g')

for percent in 99 95 90 75 50; do 
    for depth in 1 2 4 8 14; do 
        sudo PCI_ALLOWED=${DEVICE_ADDR} ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1; 
        sudo numactl -C ${NUMA_DOMAIN} -m ${NUMA_DOMAIN} ./fio_spdk_wrapper.sh \
            --ioengine=spdk \
            --direct=1 \
            --filename='trtype=PCIe traddr=${DEVICE_SPDK_ADDR} ns=2' \
            --zonemode=zbd \
            --zone_append=0 \
            --thread=1 \
            --time_based=1 \
            --runtime=1m \
            --ramp_time=5 \
            --bs=4096 \
            --flow_sleep=1 \
            --name=read \
            --rw=read \
            --offset=0z \
            --iodepth=${depth} \
            --size=1z \
            --flow=$((${percent}*${depth})) \
            --name=write1 \
            --offset=100z \
            --size=100z \
            --offset_increment=100z \
            --rw=write \
            --numjobs=${depth} \
            --job_max_open_zones=1 \
            --flow=$((100-${percent})) \
            --output-format=json \
            --output=${DATA_DIR}/inteference/mixratio/spdk_${percent}_conc_${depth}.json \
            --lat_percentiles=1 \
            --percentile_list=50:75:90:95:99:99.9:99.999; 
        sudo ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;
        sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${NVME_DEVICE}" && sleep 1;
    done; 
done;
