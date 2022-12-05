#!/bin/bash

# PLEASE change accordingly
FIO_DIR=~/opt/fio
SPDK_DIR=~/opt/spdk
NVME_DEV_LBAF0=nvme4n1
NVME_DEV_LBAF0_NS=1

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit
cd .. || exit

sudo FIO_DIR=$FIO_DIR SPDK_DIR=$SPDK_DIR  ./nvme_bench.sh \
    $NVME_DEV_LBAF0 NVMe $NVME_DEV_LBAF0_NS lbaf0 512

