#!/bin/bash
# OBSOLETE! Kept to see what not to do.
# Gets I/O inteferences using the rate limit method. This is not very effective to see the effect of writes on reads...

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

# Ordinary NVMe without interference
sudo PCI_ALLOWED="${NVME_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1;
for iodepth in 1 2 4 8 16 32 64 128 256; do
	sudo ./fio_spdk_wrapper \
		--ioengine=spdk \
		--thread=1 \
		--filename='trtype=PCIe traddr=${NVME_DEVICE_SPDK_ADDR} ns=1' \
		--direct=1 \
		--size=100% \
		--time_based=1 \
		--ramp_time=5s \
		--runtime=3m \
		--lat_percentiles=1  \
		--name=read  \
		--rw=randread \
		--bs=4k \
		--iodepth=${iodepth} \
		--output-format=json \
		--output=${DATA_DIR}/custom/zns-a/rate_inteference/nvme_0_${iodepth}; 
done;
sudo PCI_ALLOWED="${NVME_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;

# Ordinary NVMe
sudo PCI_ALLOWED="${NVME_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1;
for rate in 10 50 100 250 500; do
	for iodepth in 1 2 4 8 16 32 64 128 256; do
		sudo ./fio_spdk_wrapper \
				--ioengine=spdk \
				--thread=1 \
				--filename='trtype=PCIe traddr=${NVME_DEVICE_SPDK_ADDR} ns=1' \
				--direct=1 \
				--size=100% \
				--time_based=1 \
				--ramp_time=5s \
				--runtime=3m \
				--lat_percentiles=1\
				--name=fill \
				--rw=write \
				--bs=128k \
				--iodepth=1 \
				--rate=,${rate}m \
				--name=read  \
				--rw=randread \
				--bs=4k \
				--iodepth=${iodepth} \
				--output-format=json \
				--output=${DATA_DIR}/custom/zns-a/rate_inteference/nvme_${rate}_${iodepth};
	done; 
done;
sudo PCI_ALLOWED="${NVME_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;

# ZNS NVMe writes
for iodepth in 1 2 4 8 16 32 64 128 256; do
	sudo PCI_ALLOWED="${ZNS_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1; 
	sudo ./fio_spdk_wrapper \
			--ioengine=spdk \
			--thread=1 \
			--filename='trtype=PCIe traddr=${ZNS_DEVICE_SPDK_ADDR} ns=2' \
			--zonemode=zbd --direct=1  \
			--time_based=1 \
			--ramp_time=5s \
			--runtime=3m \
			--lat_percentiles=1 \
			--name=read \
			--rw=randread \
			--offset=0 \
			--size=400z \
			--bs=4k \
			--iodepth=${iodepth} \
			--output-format=json \
			--output=${DATA_DIR}/custom/zns-a/rate_inteference/zns_0_${iodepth};
	sudo PCI_ALLOWED="${ZNS_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;
	sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${NVME_DEVICE}";
done;

# ZNS NVMe writes
for rate in 10 50 100 250 500; do
	for iodepth in 1 2 4 8 16 32 64 128 256; do
		sudo PCI_ALLOWED="${ZNS_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh && sleep 1; 
		sudo ./fio_spdk_wrapper \
				--ioengine=spdk \
				--thread=1 \
				--filename='trtype=PCIe traddr=${ZNS_DEVICE_SPDK_ADDR} ns=2' \
				--zonemode=zbd \
				--direct=1 \
				--time_based=1 \
				--ramp_time=5s \
				--runtime=3m \
				--lat_percentiles=1 \
				--name=fill \
				--rw=write \
				--bs=128k \
				--iodepth=1 \
				--rate=,${rate}m \
				--offset=400z \
				--size=400z \
				--name=read \
				--rw=randread \
				--offset=0 \
				--size=400z \
				--bs=4k \
				--iodepth=${iodepth} \
				--output-format=json \
				--output=${DATA_DIR}/custom/zns-a/rate_inteference/zns_${rate}_${iodepth}; 
		sudo PCI_ALLOWED="${ZNS_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;
		sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${NVME_DEVICE}";
	done; 
done;

# ZNS NVMe appends
for iodepth in 1 2 4 8 16 32 64 128 256; do
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
			--runtime=3m \
			--lat_percentiles=1  \
			--name=read \
			--rw=randread \
			--offset=0 \
			--size=400z \
			--bs=4k \
			--iodepth=${iodepth} \
			--output-format=json \
			--output=${DATA_DIR}/custom/zns-a/rate_inteference/zns_append_0_${iodepth}; 
	sudo PCI_ALLOWED="${ZNS_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;
	sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${NVME_DEVICE}";
done;

# ZNS NVMe appends
for rate in 10 50 100 250 500; do
	for iodepth in 1 2 4 8 16 32 64 128 256; do
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
				--runtime=3m \
				--lat_percentiles=1 \
				--name=fill \
				--rw=write \
				--bs=128k \
				--iodepth=1 \
				--rate=,${rate}m \
				--offset=400z \
				--size=400z \
				--name=read \
				--rw=randread \
				--offset=0 \
				--size=400z \
				--bs=4k \
				--iodepth=${iodepth} \
				--output-format=json \
				--output=${DATA_DIR}/custom/zns-a/rate_inteference/zns_append_${rate}_${iodepth}; 
		sudo PCI_ALLOWED="${ZNS_DEVICE_ADDR}" ${SUBMOD_DIR}/spdk/scripts/setup.sh reset && sleep 1;
		sudo ${SUBMOD_DIR}/nvme-cli/.build/nvme zns finish-zone -a "/dev/${NVME_DEVICE}";
	done;
done;
