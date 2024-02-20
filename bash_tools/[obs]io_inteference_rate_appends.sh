#!/bin/bash
# OBSOLETE! Kept to see what not to do.
# Gets I/O inteferences using the rate limit method. This is not very effective to see the effect of writes on reads...

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

for percent in 100 99 95 90 75 50; do
    for depth in 1 2 4 8 16 32 64 128; do
        sudo PCI_ALLOWED=${DEVICE_ADDR} ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1; 
        sudo numactl -C ${NUMA_DOMAIN} -m ${NUMA_DOMAIN} ./fio_spdk_wrapper.sh \
            --ioengine=spdk \
            --direct=1 \
            --offset=0 \
            --size=100% \
            --filename='trtype=PCIe traddr=${DEVICE_SPDK_ADDR} ns=2' \
            --zonemode=zbd \
            --rw=randrw \
            --rwmixread=$percent \
            --zone_append=1 \
            --thread=1 \
            --time_based=1 \
            --runtime=20m \
            --ramp_time=5  \
            --name=rw \
            --iodepth=$depth \
            --numjobs=1 \
            --bs=4096 \
            --output-format=json \
            --output=${DATA_DIR}/inteference/mixratio/spdk_${percent}_${depth}.json \
            --lat_percentiles=1 \
            --percentile_list=50:75:90:95:99:99.9:99.999; 
        sudo ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;
        sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${NVME_DEVICE}" && sleep 1;
    done; 
done;
