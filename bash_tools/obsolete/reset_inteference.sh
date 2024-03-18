#!/bin/bash
# OBSOLETE! Kept to see what not to do.
# Measure reset inteference, replaced by custom tests in ./znst_state_machine_perf, which have higher accuracy and are more dynamic.

set -e

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
cd "$DIR" || exit;

SUBMOD_DIR=${DIR}/../submodules
DATA_DIR=${DIR}/.${DATA_DIR}

if [ -z "$1" ]; then
    echo "Args <NVMe_dev> missing"
    exit 1
fi

DEVICE=$1

sudo ./fio_spdk_wrapper.sh \
    --filename="/dev/${DEVICE}" \
    --ioengine=io_uring \
    --registerfiles=1  \
    --zonemode=zbd \
    --direct=1 \
    --size=904z \
    --group_reporting=1 \
    --write_lat_log=${DATA_DIR}/lat_log  \
    --name=fill \
    --rw=write \
    --iodepth=32 \
    --sqthread_poll=1 \
    --name=trim1 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall \
    --name=fil2 \
    --rw=write \
    --iodepth=32 \
    --stonewall=1 \
    --name=trim2 \
    --rw=trim \
    --bs=2147483648


sudo ./fio_spdk_wrapper.sh \
    --filename="/dev/${DEVICE}" \
    --ioengine=io_uring \
    --registerfiles=1 \
    --zonemode=zbd \
    --direct=1 \
    --size=$((904 - 256))z \
    --group_reporting=1 \
    --write_lat_log=${DATA_DIR}/lat_75_log \
    --name=fill \
    --rw=write \
    --iodepth=32 \
    --sqthread_poll=1 \
    --name=trim1 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall \
    --name=fil2 \
    --rw=write \
    --iodepth=32 \
    --stonewall=1 \
    --name=trim2 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall

sudo ./fio_spdk_wrapper.sh \
    --filename="/dev/${DEVICE}" \
    --ioengine=io_uring \
    --registerfiles=1 \
    --zonemode=zbd \
    --direct=1 \
    --size=$((904 - 452))z \
    --group_reporting=1 \
    --write_lat_log=${DATA_DIR}/lat_50_log \
    --name=fill \
    --rw=write \
    --iodepth=32 \
    --sqthread_poll=1 \
    --name=trim1 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall \
    --name=fil2 \
    --rw=write \
    --iodepth=32 \
    --stonewall=1 \
    --name=trim2 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall

sudo ./fio_spdk_wrapper.sh \
    --filename="/dev/${DEVICE}" \
    --ioengine=io_uring \
    --registerfiles=1 \
    --zonemode=zbd \
    --direct=1 \
    --size=$((10))z \
    --group_reporting=1 \
    --write_lat_log=${DATA_DIR}/lat_10_zones_log  \
    --name=fill \
    --rw=write \
    --iodepth=32 \
    --sqthread_poll=1 \
    --name=trim1 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall \
    --name=fil2 \
    --rw=write \
    --iodepth=32 \
    --stonewall=1 \
    --name=trim2 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall \
    --name=fill3 \
    --rw=write \
    --iodepth=32 \
    --sqthread_poll=1 \
    --name=trim3 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall \
    --name=fil4 \
    --rw=write \
    --iodepth=32 \
    --stonewall=1 \
    --name=trim4 \
    --rw=trim \
    --bs=2147483648 \
    --stonewal \
    --name=fill5 \
    --rw=write \
    --iodepth=32 \
    --sqthread_poll=1 \
    --name=trim5 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall \
    --name=fill6 \
    --rw=write \
    --iodepth=32 \
    --stonewall=1 \
    --name=trim6 \
    --rw=trim \
    --bs=2147483648 \
    --stonewall
