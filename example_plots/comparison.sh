#!/bin/bash

model_nvme=nvme-b
model_zns_nvme=nvme-a
model_zns_zns=zns-a


DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit
cd .. || exit

python_bin=python3

mkdir -p plots
mkdir -p plots/comparison


# WD NVMe ZNS SSD vs Samsung evo. Sanity check...
${python_bin} lat_kiops_plot.py --filename="comparison/1sanity" \
    -t "Latency and KIOPS of nvme-b and nvme-a" \
    -l 'spdk nvme-a' 'spdk nvme-b' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=700 \
    -q 128 \
    -b 512 512
${python_bin} lat_kiops_plot.py --filename="comparison/2sanity" \
    -t "Latency and KIOPS of nvme-b and nvme-a" \
    -l 'spdk nvme-a' 'spdk nvme-b' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=700 \
    -q 128 \
    -b 2048 2048
${python_bin} lat_kiops_plot.py --filename="comparison/3sanity" \
    -t "Latency and KIOPS of nvme-b and nvme-a" \
    -l 'spdk nvme-a' 'spdk nvme-b' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=250 \
    -q 128 \
    -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/4sanity" \
    -t "Latency and KIOPS of nvme-b and nvme-a" \
    -l 'spdk nvme-a' 'spdk nvme-b' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=250 \
    -q 128 \
    -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="comparison/5sanity" \
    -t "Latency and KIOPS of nvme-b and nvme-a" \
    -l 'spdk nvme-a' 'spdk nvme-b' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=100 --upper_limit_y=3000 \
    -q 128 \
    -b 131072 131072

# Check NVMe vs ZNS namespace as best as we can
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf3" \
     -t "Latency and KIOPS of nvme-a and zns-a" \
     -l 'spdk write nvme-a' 'spdk append zns-a' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf3 lbaf3 \
     -e spdk spdk \
     -o write append \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf3" \
     -t "Latency and KIOPS of nvme-a and zns-a" \
     -l 'io_uring write nvme-a' 'io_uring writemq zns-a' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf3 lbaf3 \
     -e io_uring io_uring \
     -o write writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf3 bs=8192" \
     -t "Latency and KIOPS of nvme-a and zns-a" \
     -l 'spdk write nvme-a' 'spdk append zns-a' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf3 lbaf3 \
     -e spdk spdk \
     -o write append \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf3 bs=8192" \
     -t "Latency and KIOPS of nvme-a and zns-a" \
     -l 'io_uring write nvme-a' 'io_uring writemq zns-a' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf3 lbaf3 \
     -e io_uring io_uring \
     -o write writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0" \
     -t "Latency and KIOPS of nvme-a and zns-a" \
     -l 'spdk write nvme-a' 'spdk append zns-a' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf0 lbaf0 \
     -e spdk spdk \
     -o write append \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0" \
     -t "Latency and KIOPS of nvme-a and zns-a" \
     -l 'io_uring write nvme-a' 'io_uring writemq zns-a' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf0 lbaf0 \
     -e io_uring io_uring \
     -o write writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0 bs=8192" \
     -t "Latency and KIOPS of nvme-a and zns-a" \
     -l 'spdk write nvme-a' 'spdk append zns-a' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf0 lbaf0 \
     -e spdk spdk \
     -o write append \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 bs=8192" \
     -t "Latency and KIOPS of nvme-a and zns-a" \
     -l 'io_uring write nvme-a' 'io_uring writemq zns-a' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf0 lbaf0 \
     -e io_uring io_uring \
     -o write writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 8192 8192

${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_spdk_lbaf0 QD=1" \
    -t "KIOPS of ${modelname} (QD=1)" \
    -l 'spdk write nvme-a' 'spdk append zns-a' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write append \
    -c 1 1 \
    --upper_limit_y=150 \
    -q 1 1
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0 QD=4" \
    -t "KIOPS of ${modelname} (QD=4)" \
    -l 'spdk write nvme-a' 'spdk append zns-a' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write append \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 4 4
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0 QD=8" \
    -t "KIOPS of ${modelname} (QD=8)" \
    -l 'spdk write nvme-a' 'spdk append zns-a' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write append \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 8 8
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0 QD=16" \
    -t "KIOPS of ${modelname} (QD=16)" \
    -l 'spdk write nvme-a' 'spdk append zns-a' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write append \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 16 16

${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 QD=1" \
    -t "KIOPS of ${modelname} (QD=1)" \
    -l 'io_uring write nvme-a' 'io_uring writemq zns-a' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e io_uring io_uring \
    -o write writemq \
    -c 1 1 \
    --upper_limit_y=150 \
    -q 1 1
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 QD=4" \
    -t "KIOPS of ${modelname} (QD=4)" \
    -l 'io_uring write nvme-a' 'io_uring writemq zns-a' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e io_uring io_uring \
    -o write writemq \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 4 4
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 QD=8" \
    -t "KIOPS of ${modelname} (QD=8)" \
    -l 'io_uring write nvme-a' 'io_uring writemq zns-a' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 io_uring \
    -e io_uring io_uring \
    -o write writemq \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 8 8
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 QD=16" \
    -t "KIOPS of ${modelname} (QD=16)" \
    -l 'io_uring write nvme-a' 'io_uring writemq zns-a' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e io_uring io_uring \
    -o write writemq \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 16 16
