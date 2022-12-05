#!/bin/bash

model=WZS4C8T1TDSP303_________________________
modelname=WZS4C8T1TDSP303

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit
cd .. || exit

# Create plot dir
mkdir -p plots

# Throughput/Queuedepth/Latency plots
python3 lat_kiops_plot.py -t "Latency and KIOPS of ${modelname} lbaf2" \
     -l 'spdk' 'io_uring' \
     -m ${model} ${model} \
     -f lbaf3 lbaf3 \
     -e spdk io_uring \
     -o append writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
python3 lat_kiops_plot.py -t "Latency and KIOPS of ${modelname} lbaf2 (log10)" \
     -l 'spdk' 'io_uring' \
     -m ${model} ${model} \
     -f lbaf3 lbaf3 \
     -e spdk io_uring \
     -o append writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=12 \
     --transform_y div1000log \
     -q 512 \
     -b 4096 4096
python3 lat_kiops_plot.py -t "Latency and KIOPS of ${modelname} lbaf2 (bs=8192)" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf3 lbaf3 \
    -e spdk io_uring \
    -o append writemq \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=250 \
    -q 128 \
    -b 8192 8192
python3 lat_kiops_plot.py -t "Latency and KIOPS of ${modelname} lbaf2 (log10) bs=8192" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf3 lbaf3 \
    -e spdk io_uring \
    -o append writemq \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=12 \
    --transform_y div1000log \
    -q 512 \
    -b 8192 8192

python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=1)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=150 \
    -q 1 1 1 1
python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=1) writes" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o write write write write \
    -c 1 1 1 1 \
    --upper_limit_y=250 \
    -q 1 1 1 1
python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=2)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=150 \
    -q 2 2 2 2
python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=4)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=150 \
    -q 4 4 4 4
python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=8)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=200 \
    -q 8 8 8 8
python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=16)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -q 16 16 16 16
python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=32)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -q 32 32 32 32
python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=64)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -q 64 64 64 64
python3 bs_kiops_plot.py -t "KIOPS of ${modelname} (QD=128)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -q 128 128 128 128

python3 qd_kiops_plot.py -t "Q KIOPS of ${modelname} (bs=4096)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -b 4096 4096 4096 4096 \
    -q 1 2 4 8 16 32 64 128
python3 qd_kiops_plot.py -t "Q KIOPS of ${modelname} (bs=8192)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -b 8192 8192 8192 8192 \
    -q 1 2 4 8 16 32 64 128
python3 qd_kiops_plot.py -t "Q KIOPS of ${modelname} (bs=16384)" \
    -l 'spdk lbaf0' 'io_uring lbaf0' 'spdk lbaf3' 'io_uring lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -b 16384 16384 16384 16384 \
    -q 1 2 4 8 16 32 64 128
