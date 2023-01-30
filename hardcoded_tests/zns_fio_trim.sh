#!/bin/bash

FIO_DIR="./submodule/fio"

sudo ${FIO_DIR}/fio --filename=/dev/nvme6n2 --ioengine=io_uring --registerfiles=1  --zonemode=zbd \
    --direct=1 --size=904z --group_reporting=1 --write_lat_log=./lat_log  --name=fill --rw=write \
    --iodepth=32 --sqthread_poll=1  --name=trim1 --rw=trim --bs=2147483648 --stonewall --name=fil2 \
    --rw=write --iodepth=32 --stonewall=1 --name=trim2 --rw=trim --bs=2147483648


sudo ${FIO_DIR}/fio --filename=/dev/nvme6n2 --ioengine=io_uring --registerfiles=1  --zonemode=zbd \
    --direct=1 --size=$((904 - 256))z --group_reporting=1 --write_lat_log=./lat_75_log  --name=fill \
    --rw=write --iodepth=32 --sqthread_poll=1  --name=trim1 --rw=trim --bs=2147483648 --stonewall --name=fil2 \
    --rw=write --iodepth=32 --stonewall=1 --name=trim2 --rw=trim --bs=2147483648 --stonewall

sudo ${FIO_DIR}/fio --filename=/dev/nvme6n2 --ioengine=io_uring --registerfiles=1  --zonemode=zbd --direct=1 \
    --size=$((904 - 452))z --group_reporting=1 --write_lat_log=./lat_50_log  --name=fill --rw=write --iodepth=32 \
    --sqthread_poll=1  --name=trim1 --rw=trim --bs=2147483648 --stonewall --name=fil2 --rw=write --iodepth=32 --stonewall=1 \
    --name=trim2 --rw=trim --bs=2147483648 --stonewall

sudo ${FIO_DIR}/fio --filename=/dev/nvme6n2 --ioengine=io_uring --registerfiles=1  --zonemode=zbd --direct=1 --size=$((10))z \
    --group_reporting=1 --write_lat_log=./lat_10_zones_log  --name=fill --rw=write --iodepth=32 --sqthread_poll=1  --name=trim1 \
    --rw=trim --bs=2147483648 --stonewall --name=fil2 --rw=write --iodepth=32 --stonewall=1 --name=trim2 --rw=trim --bs=2147483648 \
    --stonewall --name=fill3 --rw=write --iodepth=32 --sqthread_poll=1  --name=trim3 --rw=trim --bs=2147483648 --stonewall \
    --name=fil4 --rw=write --iodepth=32 --stonewall=1 --name=trim4 --rw=trim --bs=2147483648 --stonewal --name=fill5 --rw=write \
    --iodepth=32 --sqthread_poll=1  --name=trim5 --rw=trim --bs=2147483648 --stonewall --name=fill6 --rw=write --iodepth=32 \
    --stonewall=1 --name=trim6 --rw=trim --bs=2147483648 --stonewall