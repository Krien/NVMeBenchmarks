#!/bin/bash

trim_nvme() {
    dev=$1;
    sudo nvme format -s 1 $dev;
}

precondition_fill_nvme() {
    dev=$1;
    trim_nvme $dev;
    sudo $fio \
        --name "precondition_fill_nvme" \
        --filename=$dev \
        --size=100% \
        --bs=128K \
        --direct=1 \
        --rw=write \
        --thread=1 \
        --ioengine=io_uring \
        --fixedbufs=1 --registerfiles=1 --hipri;
}

precondition_rand_nvme() {
    dev=$1;
    size_prec=$2;
    mkdir -p data/steady_state;
    sudo $fio \
        --name "precondition_rand_nvme" \
        --filename=$dev \
        --size=100% \
        --loops=2 \
        --bs=$size_prec \
        --direct=1 \
        --rw=randwrite \
        --thread=1 \
        --ioengine=io_uring \
        --fixedbufs=1 --registerfiles=1 --hipri;
        --write_bw_log=data/steady_state/unsteady_state_${size_prec};
}

steady_state_nvme() {
    dev=$1;
    size_prec=$2;
    steady=$3;
    mkdir -p data/steady_state;
    sudo $fio \
        --name "steady_state_nvme" \
        --filename=$dev \
        --runtime=30m \
        --ss=iops:$steady \
        --ss_dur=30s \
        --ss_ramp=10s \
        --bs=$size_prec \
        --direct=1 \
        --rw=randwrite \
        --thread=1 \
        --ioengine=io_uring \
        --fixedbufs=1 --registerfiles=1 --hipri \
        --write_bw_log=data/steady_state/steady_state_${size_prec};
}

