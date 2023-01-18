#!/bin/sh 
#
# As run for the paper, not in this order. These are just raw commands.
#

sudo nohup ./grid_bench.py -d nvme6n2 -m zns-a -f "${FIO_DIR}/fio" -s "/home/krijn/opt/spdk" -l lbaf0 --overwrite=1 < /dev/null &
sudo nohup ./grid_bench.py -d nvme6n2 -m zns-a -f "${FIO_DIR}/fio" -s "/home/krijn/opt/spdk" -l lbaf2 --overwrite=1 < /dev/null &

sudo nohup ./grid_bench_read.py -d nvme6n2 -m zns-a -f "${FIO_DIR}/fio" -s "/home/krijn/opt/spdk" -l lbaf0 --overwrite=1 < /dev/null &
sudo nohup ./grid_bench_read.py -d nvme6n2 -m zns-a -f "${FIO_DIR}/fio" -s "/home/krijn/opt/spdk" -l lbaf2 --overwrite=1 < /dev/null &

sudo nohup ./grid_bench_inteference.py -d nvme6n2 -m zns-a -f "${FIO_DIR}/fio" -s "/home/krijn/opt/spdk" -l lbaf2 --overwrite=1 < /dev/null &
sudo nohup ./grid_bench_inteference_reverse.py -d nvme6n2 -m zns-a -f "${FIO_DIR}/fio" -s "/home/krijn/opt/spdk" -l lbaf2 --overwrite=1 < /dev/null &
