#!/bin/bash

# PLEASE change accordingly
FIO_DIR=~/opt/fio
SPDK_DIR=~/opt/spdk
NVME_DEV_LBAF0=nvme4n1
NVME_DEV_LBAF0_NS=1
NVME_DEV_LBAF2=nvme6n1
NVME_DEV_LBAF2_NS=1

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit
cd .. || exit

sudo FIO_DIR=$FIO_DIR SPDK_DIR=$SPDK_DIR  ./run_experiments.sh \
    $NVME_DEV_LBAF0 ZNS $NVME_DEV_LBAF0_NS lbaf0 512
sudo FIO_DIR=$FIO_DIR SPDK_DIR=$SPDK_DIR  ./run_experiments.sh \
    $NVME_DEV_LBAF2 ZNS $NVME_DEV_LBAF2_NS lbaf2 4096
