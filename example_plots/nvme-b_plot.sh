#!/bin/bash

model=nvme-b
modelname=nvme-b

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit
cd ../analysis || exit

# Create plot dir
mkdir -p plots
mkdir -p "plots/$modelname"

python_bin=python3

mkdir -p "plots/$modelname/tql"
# Throughput/Queuedepth/Latency plots
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf0 bs=4096 log10" \
    -t "Latency and KIOPS of ${modelname} lbaf0 (log10)" \
    -l 'spdk' 'io_uring' \
    -m $model $model \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=12 \
    --transform_y div1000log \
    -q 512 \
    -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf0 bs=4096" \
    -t "Latency and KIOPS of ${modelname} lbaf0" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=250 \
    -q 128 \
    -b 4096 4096

mkdir -p "plots/$modelname/bs"
# Throughput for blocksizes plots
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/lbaf0 bs=4096 QD=1" \
    -t "KIOPS of ${modelname} lbaf0 (QD=1)" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_y=150 \
    -q 1 1

mkdir -p "plots/$modelname/qd"
# Throughput for queue depth plots
${python_bin} qd_kiops_plot.py --filename="$modelname/qd/lbaf0 bs=4096" \
    -t "KIOPS of ${modelname} (bs=4096) lbaf0" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_y=800 \
    -b 4096 4096

