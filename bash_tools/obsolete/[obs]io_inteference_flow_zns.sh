#!/bin/bash
# OBSOLETE! Kept to see what not to do.
# Gets I/O inteferences using the rate limit method. This is not very effective to see the effect of writes on reads...

set -e

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
cd "$DIR" || exit;

SUBMOD_DIR=${DIR}/../submodules
DATA_DIR=${DIR}/../data

if [ -z "$1" ]; then
    echo "Args <NVMe_dev> <NUMA_DOMAIN> missing"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Second arg <NUMA_DOMAIN> missing"
    exit 1
fi

NVME_DEVICE=$1
NUMA_DOMAIN=$2

if [[ -f "/dev/${NVME_DEVICE}" ]] then else
    echo "NVMe device '/dev/${NVME_DEVICE}' does not exist"
    exit 2
done

for percent in 100 99 95 90 75 50; do
    for depth in 1 2 4 8 16 32 64 128 256; do
        sudo numactl -C ${NUMA_DOMAIN} -m ${NUMA_DOMAIN} ./fio_spdk_wrapper \
            --rw=randrw \
            --rwmixread=${percent} \
            --time_based=1 \
            --runtime=20m \
            --ramp_time=5 \
            --bs=4096 \
            --thread=1 \
            --numjobs=1 \
            --iodepth=${depth} \
            --zonemode=zbd \
            --direct=1 \
            --offset=0 \
            --size=100% \
            --ioengine=io_uring \
            --fixedbufs=1 \
            --hipri \
            --sqthread_poll=1 \
            --registerfiles=1 \
            --filename="/dev/${NVME_DEVICE}" \
            --name=rw \
            --output-format=json \
            --output=${DATA_DIR}/inteference/mixratio${percent}_${depth}.json \
            --lat_percentiles=1 \
            --percentile_list=50:75:90:95:99:99.9:99.999; 
        sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${NVME_DEVICE}" && sleep 1;  
    done; 
done;
