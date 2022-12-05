#!/bin/bash

model_nvme=Samsung_SSD_980_PRO_2TB_________________
model_zns_nvme=WUS4B7696DSP303_________________________
model_zns_zns=WZS4C8T1TDSP303_________________________


DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "$DIR" || exit
cd .. || exit

python_bin=python3

mkdir -p plots
mkdir -p plots/comparison


# WD NVMe ZNS SSD vs Samsung evo. Sanity check...
${python_bin} lat_kiops_plot.py --filename="comparison/1sanity" \
    -t "Latency and KIOPS of Samsung_SSD_980_PRO_2TB and WUS4B7696DSP303" \
    -l 'spdk WUS4B7696DSP303' 'spdk Samsung_SSD_980_PRO_2TB' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=700 \
    -q 128 \
    -b 512 512
${python_bin} lat_kiops_plot.py --filename="comparison/2sanity" \
    -t "Latency and KIOPS of Samsung_SSD_980_PRO_2TB and WUS4B7696DSP303" \
    -l 'spdk WUS4B7696DSP303' 'spdk Samsung_SSD_980_PRO_2TB' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=700 \
    -q 128 \
    -b 2048 2048
${python_bin} lat_kiops_plot.py --filename="comparison/3sanity" \
    -t "Latency and KIOPS of Samsung_SSD_980_PRO_2TB and WUS4B7696DSP303" \
    -l 'spdk WUS4B7696DSP303' 'spdk Samsung_SSD_980_PRO_2TB' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=250 \
    -q 128 \
    -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/4sanity" \
    -t "Latency and KIOPS of Samsung_SSD_980_PRO_2TB and WUS4B7696DSP303" \
    -l 'spdk WUS4B7696DSP303' 'spdk Samsung_SSD_980_PRO_2TB' \
    -m ${model_zns_nvme} ${model_nvme} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write write \
    -c 1 1 \
    --upper_limit_x=800 --upper_limit_y=250 \
    -q 128 \
    -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="comparison/5sanity" \
    -t "Latency and KIOPS of Samsung_SSD_980_PRO_2TB and WUS4B7696DSP303" \
    -l 'spdk WUS4B7696DSP303' 'spdk Samsung_SSD_980_PRO_2TB' \
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
     -t "Latency and KIOPS of WUS4B7696DSP303 and WZS4C8T1TDSP303" \
     -l 'spdk write WUS4B7696DSP303' 'spdk append WZS4C8T1TDSP303' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf3 lbaf3 \
     -e spdk spdk \
     -o write append \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf3" \
     -t "Latency and KIOPS of WUS4B7696DSP303 and WZS4C8T1TDSP303" \
     -l 'io_uring write WUS4B7696DSP303' 'io_uring writemq WZS4C8T1TDSP303' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf3 lbaf3 \
     -e io_uring io_uring \
     -o write writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf3 bs=8192" \
     -t "Latency and KIOPS of WUS4B7696DSP303 and WZS4C8T1TDSP303" \
     -l 'spdk write WUS4B7696DSP303' 'spdk append WZS4C8T1TDSP303' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf3 lbaf3 \
     -e spdk spdk \
     -o write append \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf3 bs=8192" \
     -t "Latency and KIOPS of WUS4B7696DSP303 and WZS4C8T1TDSP303" \
     -l 'io_uring write WUS4B7696DSP303' 'io_uring writemq WZS4C8T1TDSP303' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf3 lbaf3 \
     -e io_uring io_uring \
     -o write writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0" \
     -t "Latency and KIOPS of WUS4B7696DSP303 and WZS4C8T1TDSP303" \
     -l 'spdk write WUS4B7696DSP303' 'spdk append WZS4C8T1TDSP303' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf0 lbaf0 \
     -e spdk spdk \
     -o write append \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0" \
     -t "Latency and KIOPS of WUS4B7696DSP303 and WZS4C8T1TDSP303" \
     -l 'io_uring write WUS4B7696DSP303' 'io_uring writemq WZS4C8T1TDSP303' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf0 lbaf0 \
     -e io_uring io_uring \
     -o write writemq \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 4096 4096
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0 bs=8192" \
     -t "Latency and KIOPS of WUS4B7696DSP303 and WZS4C8T1TDSP303" \
     -l 'spdk write WUS4B7696DSP303' 'spdk append WZS4C8T1TDSP303' \
     -m ${model_zns_nvme} ${model_zns_zns} \
     -f lbaf0 lbaf0 \
     -e spdk spdk \
     -o write append \
     -c 1 1 \
     --upper_limit_x=350 --upper_limit_y=250 \
     -q 128 \
     -b 8192 8192
${python_bin} lat_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 bs=8192" \
     -t "Latency and KIOPS of WUS4B7696DSP303 and WZS4C8T1TDSP303" \
     -l 'io_uring write WUS4B7696DSP303' 'io_uring writemq WZS4C8T1TDSP303' \
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
    -l 'spdk write WUS4B7696DSP303' 'spdk append WZS4C8T1TDSP303' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write append \
    -c 1 1 \
    --upper_limit_y=150 \
    -q 1 1
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0 QD=4" \
    -t "KIOPS of ${modelname} (QD=4)" \
    -l 'spdk write WUS4B7696DSP303' 'spdk append WZS4C8T1TDSP303' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write append \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 4 4
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0 QD=8" \
    -t "KIOPS of ${modelname} (QD=8)" \
    -l 'spdk write WUS4B7696DSP303' 'spdk append WZS4C8T1TDSP303' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write append \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 8 8
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_spdk_lbaf0 QD=16" \
    -t "KIOPS of ${modelname} (QD=16)" \
    -l 'spdk write WUS4B7696DSP303' 'spdk append WZS4C8T1TDSP303' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e spdk spdk \
    -o write append \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 16 16

${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 QD=1" \
    -t "KIOPS of ${modelname} (QD=1)" \
    -l 'io_uring write WUS4B7696DSP303' 'io_uring writemq WZS4C8T1TDSP303' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e io_uring io_uring \
    -o write writemq \
    -c 1 1 \
    --upper_limit_y=150 \
    -q 1 1
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 QD=4" \
    -t "KIOPS of ${modelname} (QD=4)" \
    -l 'io_uring write WUS4B7696DSP303' 'io_uring writemq WZS4C8T1TDSP303' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e io_uring io_uring \
    -o write writemq \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 4 4
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 QD=8" \
    -t "KIOPS of ${modelname} (QD=8)" \
    -l 'io_uring write WUS4B7696DSP303' 'io_uring writemq WZS4C8T1TDSP303' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 io_uring \
    -e io_uring io_uring \
    -o write writemq \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 8 8
${python_bin} bs_kiops_plot.py --filename="comparison/zns_nvme_io_uring_lbaf0 QD=16" \
    -t "KIOPS of ${modelname} (QD=16)" \
    -l 'io_uring write WUS4B7696DSP303' 'io_uring writemq WZS4C8T1TDSP303' \
    -m ${model_zns_nvme} ${model_zns_zns} \
    -f lbaf0 lbaf0 \
    -e io_uring io_uring \
    -o write writemq \
    -c 1 1 \
    --upper_limit_y=350 \
    -q 16 16