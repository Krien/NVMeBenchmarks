#!/bin/bash                                                                                                                                                                                                                                                                                                               #f

set -e

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
cd "$DIR" || exit;

SUBMOD_DIR=${DIR}/../submodules
DATA_DIR=${DIR}/.${DATA_DIR}

if [ -z "$1" ]; then
    echo "Args nvmexny znsxny missing"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Second arg znsxny  missing"
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

for depth in 1 2 4 8 16 32 64 128 256; do
       sudo PCI_ALLOWED="${ZNS_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1;
       sudo ./fio_spdk_wrapper \
              --ioengine=spdk \
              --thread=1 \
              --filename='trtype=PCIe traddr=${ZNS_DEVICE_SPDK_ADDR} ns=2' \
              --zonemode=zbd \
              --zone_append=1 \
              --direct=1  \
              --time_based=1 \
              --ramp_time=5s \
              --runtime=20m \
              --lat_percentiles=1 \
              --write_bw_log=${DATA_DIR}/long/log_zns_${depth}_0 \
              --log_avg_msec=1000 \
              --output-format=json \
              --output=${DATA_DIR}/long/zns_append_${depth}_0.json \
              --group_reporting=1  \
              --zonemode=zbd  \
              --name=read  \
              --rw=randread \
              --bs=4k \
              --iodepth=${depth} \
              --size=100z --offset=0; 
       sudo ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1; 
       sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${ZNS_DEVICE}" && sleep 1; 
done;

for depth in 1 2 4 8 16 32 64 128 256; do 
       for rate in 1115 750 250; do
              sudo PCI_ALLOWED="${ZNS_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1;
              sudo ./fio_spdk_wrapper \
                     --ioengine=spdk \
                     --thread=1 \
                     --filename='trtype=PCIe traddr=${ZNS_DEVICE_SPDK_ADDR} ns=2' \
                     --zonemode=zbd \
                     --zone_append=1 \
                     --direct=1 \
                     --time_based=1 \
                     --ramp_time=5s \
                     --runtime=20m \
                     --lat_percentiles=1 \
                     --write_bw_log=${DATA_DIR}/long/log_zns_${depth}_${rate} \
                     --log_avg_msec=1000 \
                     --output-format=json \
                     --output=${DATA_DIR}/long/zns_append_${depth}_${rate}.json \
                     --name=fill \
                     --group_reporting=1 \
                     --rw=randwrite \
                     --rate=${rate}m,${rate}m \
                     --zonemode=zbd \
                     --job_max_open_zones=2 \
                     --bs=1m \
                     --iodepth=32 \
                     --offset=100z \
                     --size=100z \
                     --numjobs=4 \
                     --offset_increment=100z \
                     --name=read \
                     --rw=randread \
                     --bs=4k \
                     --iodepth=${depth} \
                     --size=100z \
                     --offset=0; 
              sudo ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1; 
              sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${ZNS_DEVICE}" && sleep 1; 
       done; 
done

sudo PCI_ALLOWED="${SPDK_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1;  
for depth in 1 2 4 8 16 32 64 128 256; do
       sudo ./fio_spdk_wrapper \
              --ioengine=spdk \
              --thread=1 \
              --filename='trtype=PCIe traddr=${NVME_DEVICE_SPDK_ADDR} ns=1' \
              --direct=1 \
              --time_based=1 \
              --ramp_time=5s \
              --runtime=20m \
              --lat_percentiles=1 \
              --write_bw_log=${DATA_DIR}/long/log_${depth}_0 \
              --log_avg_msec=1000 \
              --output-format=json \
              --output=${DATA_DIR}/long/nvme_${depth}_0.json \
              --group_reporting=1 \
              --name=read \
              --rw=randread \
              --bs=4k \
              --iodepth=${depth} \
              --size=100G \
              --offset=0;  
done;
sudo PCI_ALLOWED="${SPDK_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;  

sudo PCI_ALLOWED="${SPDK_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1;  
for depth in 1 2 4 8 16 32 64 128 256; do 
       for rate in 1115 750 250; do
              sudo ./fio_spdk_wrapper \
                     --ioengine=spdk \
                     --thread=1 \
                     --filename='trtype=PCIe traddr=${NVME_DEVICE_SPDK_ADDR} ns=1' \
                     --direct=1  \
                     --time_based=1 \
                     --ramp_time=5s \
                     --runtime=20m \
                     --lat_percentiles=1 \
                     --write_bw_log=${DATA_DIR}/long/log_${depth}_${rate} \
                     --log_avg_msec=1000 \
                     --output-format=json \
                     --output=${DATA_DIR}/long/nvme_${depth}_${rate}.json \
                     --name=fill \
                     --group_reporting=1 \
                     --rw=randwrite \
                     --rate=${rate}m,${rate}m \
                     --bs=1m \
                     --iodepth=32 \
                     --offset=100G \
                     --size=100G \
                     --numjobs=4 \
                     --offset_increment=100G \
                     --name=read \
                     --rw=randread \
                     --bs=4k \
                     --iodepth=${depth} \
                     --size=100G \
                     --offset=0;  
       done; 
done
sudo PCI_ALLOWED="${SPDK_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;  
