#!/bin/bash

model=WUS4B7696DSP303_________________________
modelname=WUS4B7696DSP303

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit
cd .. || exit

# Create plot dir
mkdir -p plots

python_bin=python3

# Throughput/Queuedepth/Latency plots
${python_bin} lat_kiops_plot.py -t "Latency and KIOPS of ${modelname} lbaf2 (log10)" \
    -l 'spdk' 'io_uring' \
    -m $model $model \
    -f lbaf3 lbaf3 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=12 \
    --transform_y div1000log \
    -q 512 \
    -b 4096 4096
${python_bin}  lat_kiops_plot.py -t "Latency and KIOPS of ${modelname} lbaf2" \
    -l 'spdk' 'io_uring' \
    -m $model $model \
    -f lbaf3 lbaf3 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=250 \
    -q 128 \
    -b 4096 4096
${python_bin} lat_kiops_plot.py -t "Latency and KIOPS of ${modelname} lbaf0 (log10)" \
    -l 'spdk' 'io_uring' \
    -m $model $model \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=12 \
    --transform_y div1000log \
    -q 512 \
    -b 4096 4096
${python_bin} lat_kiops_plot.py -t "Latency and KIOPS of ${modelname} lbaf0" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=250 \
    -q 128 \
    -b 4096 4096

# Throughput for blocksizes plots
${python_bin} bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=1)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o write write write write \
    -c 1 1 1 1 \
    --upper_limit_y=120 \
    -q 1 1 1 1
${python_bin} bs_kiops_plot.py -t "KIOPS of ${modelname} lbaf2 (QD=1)" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf3 lbaf3 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 1 1
${python_bin} bs_kiops_plot.py -t "KIOPS of ${modelname} lbaf0 (QD=1)" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 1 1

# Throughput for queue depth plots
${python_bin} qd_kiops_plot.py -t "KIOPS of ${modelname} (bs=4096)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o write write write write \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -b 4096 4096 4096 4096
${python_bin} qd_kiops_plot.py -t "KIOPS of ${modelname} (bs=4096) lbaf0" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_y=350 \
    -b 4096 4096
${python_bin} qd_kiops_plot.py -t "KIOPS of ${modelname} (bs=4096) lbaf3" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf3 lbaf3 \
    -e spdk io_uring \
    -o write write \
    -c 1 1 \
    --upper_limit_y=350 \
    -b 4096 4096
