#!/bin/bash

set -e

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
cd "$DIR" || exit;

# ... Setup tooling ...
if [ -z "$FIO_DIR" ]; then
    echo "Please provide a path to the FIO_DIR";
    exit 1;
fi

if [ -z "$SPDK_DIR" ]; then
    echo "Please provide a path to the SPDK_DIR";
    exit 1;
fi
fio="LD_PRELOAD=${SPDK_DIR}/build/fio/spdk_nvme  ${FIO_DIR}/fio";

DATA_DIR=data;
ENGINES=("spdk" "io_uring");

qds=(1 2 4 8 16 32 64 128 256 512)
bss=(512 1024 2048 4096 8192 16384 32768 65536 131072)
czones=(1 2 3 4 5)

# Used for small eval
# qds=(1 2)
# bss=(512 8192)
# czones=(1 3)

# Create data dirs
mkdir -p ${DATA_DIR}
for engine in "${ENGINES[@]}"; do
    mkdir -p "data/${engine}";
done

# ... Parse input ...
if [[ "$#" -ne 5 ]]; then
    echo "Please  specify <device name> <NVMe/ZNS> <ns> <lbaf> <page_size>"
    echo "device name should be in format nvme9"
    echo "namespace should be in format 1"
    echo "For the second arg type either NVMe or ZNS"
    echo "Lbaf should be in a format like lbaf0 or lbaf2"
    echo "Pagesize should be numeric like 512 or 4096"
    exit 1
fi
nvme_dev="$1";
type="$2";
ns="$3";
lbaf="$4";
page_size="$5";

model_str="/sys/block/${nvme_dev}/device/model";
model=$(cat ${model_str});
model="${model// /_}";

addr_str="/sys/block/${nvme_dev}/device/address";
addr=$(cat ${addr_str});

numa_str="/sys/block/${nvme_dev}/device/numa_node";
numa=$(cat ${numa_str});

echo "Running tests for model:${model}, addr:${addr}, numa node:${numa}";

# ... Create dir structure for device  ...
for engine in "${ENGINES[@]}"; do
    mkdir -p "data/${engine}/${model}";
    mkdir -p "data/${engine}/${model}/${lbaf}";
done

# ... Setup common fio args ...
default_args=(
    --rw=write
    --direct=1  
    --group_reporting=1
    --thread=1
    --output-format=json
    --time_based=1
    --runtime=30s
    --ramp_time=10s
    --numa_cpu_nodes="$numa"
    --numa_mem_policy="bind:${numa}"
)
if [[ "$type" == "ZNS"  ]]; then
    default_args+=(
        --size=20z 
        --zonemode=zbd
    );
else
    default_args+=(
        --size=40G
    );
fi 

io_uring_default_args=(
    --ioengine=io_uring 
    --filename="/dev/${nvme_dev}"
    --fixedbufs=1 
    --registerfiles=1 
    --hipri=1 
    --sqthread_poll=1
);

spdk_addr=$(echo $addr | sed 's/\:/./g')
spdk_default_args=(
    --ioengine=spdk 
);

# ... Setup engine dirs ...
for engine in "${ENGINES[@]}"; do
    mkdir -p "data/${engine}/${model}/${lbaf}/write";
    if [[ "$type" == "ZNS"  ]]; then
        mkdir -p "data/spdk/${model}/${lbaf}/append";
        mkdir -p "data/io_uring/${model}/${lbaf}/writemq";
    fi
done

# ... io_uring tests ...
for qd in "${qds[@]}"; do
    if [[ "$type" == "ZNS" ]]; then
        for bs in "${bss[@]}"; do
            output_dir="${DATA_DIR}/io_uring/${model}/${lbaf}/writemq/${bs}bs";
            mkdir -p "${output_dir}";
            for concurrent_zones in "${czones[@]}"; do
                sudo nvme zns reset-zone -a /dev/${nvme_dev}
                output_dir="${DATA_DIR}/io_uring/${model}/${lbaf}/writemq/${bs}bs/${concurrent_zones}zone";
                mkdir -p "${output_dir}";
                sudo $fio \
                    --name="qd${qd}" \
                    ${default_args[@]} \
                    ${io_uring_default_args[@]} \
                    --output="${output_dir}/${qd}.json" \
                    --ioscheduler=mq-deadline \
                    --iodepth=${qd} \
                    --numjobs=${concurrent_zones} \
                    --bs=${bs} \
                    --offset_increment=20z;
            done
        done
    else
        for bs in "${bss[@]}"; do
            output_dir="${DATA_DIR}/io_uring/${model}/${lbaf}/write/${bs}bs";
            mkdir -p "${output_dir}";
            output_dir="${DATA_DIR}/io_uring/${model}/${lbaf}/write/${bs}bs/1zone";
            mkdir -p "${output_dir}";
            sudo $fio \
                --name="qd${qd}" \
                ${default_args[@]} \
                ${io_uring_default_args[@]} \
                --output="${output_dir}/${qd}.json" \
                --ioscheduler=none \
                --bs=${bs} \
                --iodepth=${qd};
        done
    fi;
done
if [[ "$type" == "ZNS"  ]]; then
    for bs in "${bss[@]}"; do
        sudo nvme zns reset-zone -a /dev/${nvme_dev}
        output_dir="${DATA_DIR}/io_uring/${model}/${lbaf}/write/${bs}bs";
        mkdir -p "${output_dir}";
        output_dir="${DATA_DIR}/io_uring/${model}/${lbaf}/write/${bs}bs/1zone";
        mkdir -p "${output_dir}";
        sudo $fio \
            --name="write" \
            ${default_args[@]} \
            ${io_uring_default_args[@]} \
            --output="${output_dir}/1.json" \
            --ioscheduler=none \
            --iodepth=1;
    done;
fi

# ... SPDK tests ...
sudo PCI_ALLOWED="${addr}" ${SPDK_DIR}/scripts/setup.sh
for qd in "${qds[@]}"; do
    if [[ "$type" == "ZNS"  ]]; then
        for bs in "${bss[@]}"; do
            output_dir="${DATA_DIR}/spdk/${model}/${lbaf}/append/${bs}bs"
            mkdir -p "${output_dir}";
            for concurrent_zones in "${czones[@]}"; do
                output_dir="${DATA_DIR}/spdk/${model}/${lbaf}/append/${bs}bs/${concurrent_zones}zone"
                mkdir -p "${output_dir}";
                sudo $fio \
                    --name="qd${qd}" \
                    ${default_args[@]} \
                    ${spdk_default_args[@]} \
                    --filename="trtype=PCIe traddr=${spdk_addr} ns=${ns}" \
                    --output="${output_dir}/${qd}.json" \
                    --zone_append=1 \
                    --initial_zone_reset=1 \
                    --iodepth=${qd} \
                    --numjobs=${concurrent_zones} \
                    --bs=${bs} \
                    --offset_increment=20z;
            done
        done
    else
        for bs in "${bss[@]}"; do
            output_dir="${DATA_DIR}/spdk/${model}/${lbaf}/write/${bs}bs"
            mkdir -p "${output_dir}";
            output_dir="${DATA_DIR}/spdk/${model}/${lbaf}/write/${bs}bs/1zone"
            mkdir -p "${output_dir}";
            sudo $fio \
                --name="qd${qd}" \
                ${default_args[@]} \
                ${spdk_default_args[@]} \
                --filename="trtype=PCIe traddr=${spdk_addr} ns=${ns}" \
                --output="${output_dir}/${qd}.json" \
                --bs=${bs} \
                --iodepth=${qd};
        done
    fi;
done
if [[ "$type" == "ZNS" ]]; then
    for bs in "${bss[@]}"; do
        output_dir="${DATA_DIR}/spdk/${model}/${lbaf}/write/${bs}bs"
        mkdir -p "${output_dir}";
        output_dir="${DATA_DIR}/spdk/${model}/${lbaf}/write/${bs}bs/1zone"
        mkdir -p "${output_dir}";
        sudo $fio \
            --name="write" \
            ${default_args[@]} \
            ${spdk_default_args[@]} \
            --filename="trtype=PCIe traddr=${spdk_addr} ns=${ns}" \
            --output="${output_dir}/1.json" \
            --zone_append=0 \
            --initial_zone_reset=1 \
            --iodepth=1 \
            --numjobs=${concurrent_zones} \
            --bs=${bs} \
            --offset_increment=20z;
    done;
fi
sudo ${SPDK_DIR}/scripts/setup.sh reset
