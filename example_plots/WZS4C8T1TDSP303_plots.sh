#!/bin/bash

model=WZS4C8T1TDSP303_________________________
modelname=WZS4C8T1TDSP303

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit
cd .. || exit

# Create plot dir
mkdir -p plots
mkdir -p "plots/$modelname"

python_bin=python3

mkdir -p "plots/$modelname/tql"
# Throughput/Queuedepth/Latency plots
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf2 bs=4096" \
     -t "Latency and KIOPS of ${modelname} lbaf2, bs=4096" \
     -l 'spdk' 'io_uring' \
     -m ${model} ${model} \
     -f lbaf3 lbaf3 \
     -e spdk io_uring \
     -o append writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf2 bs=4096 log10" \
    -t "Latency (log10) and KIOPS of ${modelname} lbaf2, bs=4096" \
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
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf2 bs=8192" \
    -t "Latency and KIOPS of ${modelname} lbaf2, bs=8192" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf3 lbaf3 \
    -e spdk io_uring \
    -o append writemq \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=250 \
    -q 128 \
    -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf2 bs=8192 log10" \
    -t "Latency (log10) and KIOPS of ${modelname} lbaf2, bs=8192" \
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
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf0 bs=4096" \
     -t "Latency and KIOPS of ${modelname} lbaf0, bs=4096" \
     -l 'spdk' 'io_uring' \
     -m ${model} ${model} \
     -f lbaf0 lbaf0 \
     -e spdk io_uring \
     -o append writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf0 bs=4096 log10" \
    -t "Latency (log10) and KIOPS of ${modelname} lbaf0, bs=4096" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o append writemq \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=12 \
    --transform_y div1000log \
    -q 256 \
    -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf0 bs=8192" \
    -t "Latency and KIOPS of ${modelname} lbaf0, bs=8192" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o append writemq \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=250 \
    -q 128 \
    -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="$modelname/tql/lbaf0 bs=8192 log10" \
    -t "Latency (log10) and KIOPS of ${modelname} lbaf0, bs=8192" \
    -l 'spdk' 'io_uring' \
    -m ${model} ${model} \
    -f lbaf0 lbaf0 \
    -e spdk io_uring \
    -o append writemq \
    -c 1 1 \
    --upper_limit_x=350 --upper_limit_y=12 \
    --transform_y div1000log \
    -q 256 \
    -b 8192 8192

mkdir -p "plots/$modelname/bs"
# Throughput for various blocksizes plots
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=1" \
    -t "KIOPS of ${modelname} (QD=1)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf2' 'io_uring writemq lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=150 \
    -q 1 1 1 1
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=1 noscheduler" \
    -t "KIOPS of ${modelname} (QD=1) no scheduler" \
    -l 'spdk writes lbaf0' 'io_uring writes lbaf0' 'spdk writes lbaf2' 'io_uring writes lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o write write write write \
    -c 1 1 1 1 \
    --upper_limit_y=250 \
    -q 1 1 1 1
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=2" \
    -t "KIOPS of ${modelname} (QD=2)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf2' 'io_uring writemq lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=150 \
    -q 2 2 2 2
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=4" \
    -t "KIOPS of ${modelname} (QD=4)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf2' 'io_uring writemq lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=150 \
    -q 4 4 4 4
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=8" \
    -t "KIOPS of ${modelname} (QD=8)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf2' 'io_uring writemq lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=200 \
    -q 8 8 8 8
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=16" \
    -t "KIOPS of ${modelname} (QD=16)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf2' 'io_uring writemq lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -q 16 16 16 16
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=32" \
    -t "KIOPS of ${modelname} (QD=32)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf2' 'io_uring writemq lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -q 32 32 32 32
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=64" \
    -t "KIOPS of ${modelname} (QD=64)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf2' 'io_uring writemq lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -q 64 64 64 64
${python_bin} bs_kiops_plot.py --filename="$modelname/bs/bs=4096 QD=128" \
    -t "KIOPS of ${modelname} (QD=128)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf2' 'io_uring writemq lbaf2' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -q 128 128 128 128

mkdir -p "plots/$modelname/qd"
# Throughput for various queue depths plots
${python_bin} qd_kiops_plot.py --filename="$modelname/qd/bs=4096" \
    -t "KIOPS of ${modelname} (bs=4096)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf3' 'io_uring writemq lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -b 4096 4096 4096 4096 \
    -q 1 2 4 8 16 32 64 128
${python_bin} qd_kiops_plot.py --filename="$modelname/qd/bs=8192" \
    -t "KIOPS of ${modelname} (bs=8192)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf3' 'io_uring writemq lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -b 8192 8192 8192 8192 \
    -q 1 2 4 8 16 32 64 128
${python_bin} qd_kiops_plot.py --filename="$modelname/qd/bs=16384" \
    -t "KIOPS of ${modelname} (bs=16384)" \
    -l 'spdk appends lbaf0' 'io_uring writemq lbaf0' 'spdk appends lbaf3' 'io_uring writemq lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    -c 1 1 1 1 \
    --upper_limit_y=350 \
    -b 16384 16384 16384 16384 \
    -q 1 2 4 8 16 32 64 128

mkdir -p "plots/$modelname/zones"
# Througput concurrent zones
${python_bin} concurrent_zones_kiops_plot.py --filename="$modelname/zones/bs=4096 QD=1" \
    -t "KIOPS of ${modelname} (bs=4096)" \
    -l 'spdk appends lbaf0' 'io_uring writemqlbaf0' 'spdk appends lbaf3' 'io_uring writemqlbaf0 lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    --upper_limit_y=350 \
    -b 4096 4096 4096 4096 \
    -q 1 1 1 1
${python_bin} concurrent_zones_kiops_plot.py --filename="$modelname/zones/bs=4096 QD=8" \
    -t "KIOPS of ${modelname} (bs=4096) (QD=8)" \
    -l 'spdk appends lbaf0' 'io_uring writemqlbaf0 lbaf0' 'spdk appends lbaf3' 'io_uring writemqlbaf0 lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    --upper_limit_y=350 \
    -b 4096 4096 4096 4096 \
    -q 8 8 8 8
${python_bin} concurrent_zones_kiops_plot.py --filename="$modelname/zones/bs=8192 QD=1" \
    -t "KIOPS of ${modelname} (bs=8192)" \
    -l 'spdk appends lbaf0' 'io_uring writemqlbaf0 lbaf0' 'spdk appends lbaf3' 'io_uring writemqlbaf0 lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    --upper_limit_y=350 \
    -b 8192 8192 8192 8192 \
    -q 1 1 1 1
${python_bin} concurrent_zones_kiops_plot.py --filename="$modelname/zones/bs=8192 QD=8" \
    -t "KIOPS of ${modelname} (bs=8192) (QD=8)" \
    -l 'spdk appends lbaf0' 'io_uring writemqlbaf0 lbaf0' 'spdk appends lbaf3' 'io_uring writemqlbaf0 lbaf3' \
    -m ${model} ${model} ${model} ${model} \
    -f lbaf0 lbaf0 lbaf3 lbaf3 \
    -e spdk io_uring spdk io_uring \
    -o append writemq append writemq \
    --upper_limit_y=350 \
    -b 8192 8192 8192 8192 \
    -q 8 8 8 8