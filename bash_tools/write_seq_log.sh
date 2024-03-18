#!/bin/bash
# Measure throughput and latency overtime for sequential I/O when writing sequentially to NVMe and ZNS continously.

set -e

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
cd "$DIR" || exit;

SUBMOD_DIR=${DIR}/../submodules
DATA_DIR=${DIR}/.${DATA_DIR}

if [ -z "$1" ]; then
    echo "Args nvmexny znsxny  missing"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Second arg znsxny missing"
    exit 1
fi

# Transformative
NVME_DEVICE=$1
ZNS_DEVICE=$2

if [[ -f "/dev/${NVME_DEVICE}" ]] then else
    echo "NVMe device '/dev/${NVME_DEVICE}' does not exist"
    exit 2
done

if [[ -f "/dev/${ZNS_DEVICE}" ]] then else
    echo "ZNS device '/dev/${ZNS_DEVICE}' does not exist"
    exit 2
done

NVME_DEVICE_ADDR="/sys/block/${NVME_DEVICE}/device/address";
NVME_DEVICE_ADDR=$(cat ${NVME_DEVICE_ADDR});
ZNS_DEVICE_ADDR="/sys/block/${ZNS_DEVICE}/device/address";
ZNS_DEVICE_ADDR=$(cat ${ZNS_DEVICE_ADDR});

NVME_DEVICE_SPDK_ADDR=$(echo ${NVME_DEVICE_ADDR} | sed 's/\:/./g')
ZNS_DEVICE_SPDK_ADDR=$(echo ${ZNS_DEVICE_ADDR} | sed 's/\:/./g')

sudo ./fio_spdk_wrapper \
    --ioengine=spdk \
    --direct=1 \
    --offset=0 \
    --size=100% \
    --filename='trtype=PCIe traddr=${NVME_DEVICE_SPDK_ADDR} ns=1' \
    --rw=write \
    --thread=1 \
    --time_based=1 \
    --runtime=240m \
    --ramp_time=5 \
    --name=rw \
    --iodepth=32 \
    --numjobs=1 \
    --bs=4096 \
    --lat_percentiles=1 \
    --percentile_list=50:75:90:95:99:99.9:99.999 \
    --log_avg_msec=5000 \
    --write_iops_log=${DATA_DIR}/nvme_fill_4 \
    --write_lat_log=${DATA_DIR}/nvme_fill_4

sudo ./fio_spdk_wrapper \
    --ioengine=spdk \
    --direct=1 \
    --offset=0 \
    --size=100% \
    --filename='trtype=PCIe traddr=${ZNS_DEVICE_SPDK_ADDR} ns=2' \
    --zonemode=zbd \
    --rw=write \
    --thread=1 \
    --time_based=1 \
    --runtime=240m \
    --ramp_time=5 \
    --name=rw \
    --iodepth=32 \
    --numjobs=1 \
    --bs=4096 \
    --lat_percentiles=1 \
    --percentile_list=50:75:90:95:99:99.9:99.999 \
    --log_avg_msec=5000 \
    --write_iops_log=${DATA_DIR}/zns_fill_4 \
    --write_lat_log=${DATA_DIR}/zns_fill_4

sudo ./fio_spdk_wrapper \
    --ioengine=spdk \
    --direct=1 \
    --offset=0 \
    --size=100% \
    --filename='trtype=PCIe traddr=${NVME_DEVICE_SPDK_ADDR} ns=1' \
    --rw=write \
    --thread=1 \
    --loops=4 \
    --name=rw \
    --iodepth=32 \
    --numjobs=1 \
    --bs=4096 \
    --lat_percentiles=1 \
    --percentile_list=50:75:90:95:99:99.9:99.999 \
    --log_avg_msec=5000 \
    --write_iops_log=${DATA_DIR}/nvme_fill_2 \
    --write_lat_log=${DATA_DIR}/nvme_fill_2

sudo ./fio_spdk_wrapper \
    --ioengine=spdk \
    --direct=1 \
    --offset=0 \
    --size=100% \
    --filename='trtype=PCIe traddr=${ZNS_DEVICE_SPDK_ADDR} ns=2' \
    --zonemode=zbd \
    --rw=write \
    --zone_append=1 \
    --thread=1 \
    --loops=4 \
    --name=rw \
    --iodepth=32 \
    --numjobs=1 \
    --bs=4096 \
    --lat_percentiles=1 \
    --percentile_list=50:75:90:95:99:99.9:99.999 \
    --log_avg_msec=5000 \
    --write_iops_log=${DATA_DIR}/zns_fill_2 \
    --write_lat_log=${DATA_DIR}/zns_fill_2
