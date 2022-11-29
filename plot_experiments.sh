#!/bin/bash
# Creates the plots we see in plots

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit

mkdir -p plots

# KIOP latency plots
python3 lat_kiops_lot.py -t 'Latency and KIOPS of WUS4B7696DSP303' -l 'spdk lbaf0' 'spdk lbaf2' 'io_uring lbaf0' 'io_uring lbaf2' -m WUS4B7696DSP303 WUS4B7696DSP303 WUS4B7696DSP303 WUS4B7696DSP303 -f lbaf0 lbaf2 lbaf0 lbaf2 -e spdk spdk io_uring io_uring -o write write write write -c 1zone 1zone 1zone 1zone
python3 lat_kiops_lot.py -t 'Latency and KIOPS of WUS4B7696DSP303 (log10)' -l 'spdk lbaf0' 'spdk lbaf2' 'io_uring lbaf0' 'io_uring lbaf2' -m WUS4B7696DSP303 WUS4B7696DSP303 WUS4B7696DSP303 WUS4B7696DSP303 -f lbaf0 lbaf2 lbaf0 lbaf2 -e spdk spdk io_uring io_uring -o write write write write -c 1zone 1zone 1zone 1zone --transform_y div1000log --upper_limit=12 -q 1024
python3 lat_kiops_lot.py -t 'Latency and KIOPS of WUS4B7696DSP303 lbaf0' -l 'spdk' 'io_uring' -m WUS4B7696DSP303 WUS4B7696DSP303  -f lbaf0 lbaf0 -e spdk  io_uring -o write write -c 1zone 1zone
python3 lat_kiops_lot.py -t 'Latency and KIOPS of WUS4B7696DSP303 lbaf0 (log10)' -l 'spdk' 'io_uring' -m WUS4B7696DSP303 WUS4B7696DSP303  -f lbaf0 lbaf0 -e spdk  io_uring -o write write -c 1zone 1zone --transform_y div1000log --upper_limit=12 -q 1024
python3 lat_kiops_lot.py -t 'Latency and KIOPS of WUS4B7696DSP303 lbaf2' -l 'spdk' 'io_uring' -m WUS4B7696DSP303 WUS4B7696DSP303  -f lbaf2 lbaf2 -e spdk  io_uring -o write write -c 1zone 1zone
python3 lat_kiops_lot.py -t 'Latency and KIOPS of WUS4B7696DSP303 lbaf2 (log10)' -l 'spdk' 'io_uring' -m WUS4B7696DSP303 WUS4B7696DSP303  -f lbaf2 lbaf2 -e spdk  io_uring -o write write -c 1zone 1zone --transform_y div1000log --upper_limit=12 -q 1024
