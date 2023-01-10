setup_4k_namespaces() {
    tnvmcap=$(sudo nvme id-ctrl /dev/nvme2 | grep tnvmcap | awk '{print $3}')
    pagesize=4096
    randwritable_size=2147483648

    randwritable_pages=$((${randwritable_size} / ${pagesize}))
    znswritable_pages=$((${randwritable_size} / ${pagesize}))

    sudo nvme create-ns /dev/nvme2 -s ${randwritable_pages} -c ${randwritable_pages} -b ${pagesize} --csi=0
    sudo nvme create-ns /dev/nvme2 -s ${znswritable_pages} -c ${znswritable_pages} -b ${pagesize} --csi=2
    sudo nvme attach-ns /dev/nvme2 -c 0 -n 1
    sudo nvme attach-ns /dev/nvme2 -c 0 -n 2
}

setup_512_namespaces() {
    tnvmcap=$(sudo nvme id-ctrl /dev/nvme2 | grep tnvmcap | awk '{print $3}')
    pagesize=512
    randwritable_size=2147483648

    randwritable_pages=$((${randwritable_size} / ${pagesize}))
    znswritable_pages=$((${randwritable_size} / ${pagesize}))

    sudo nvme create-ns /dev/nvme2 -s ${randwritable_pages} -c ${randwritable_pages} -b ${pagesize} --csi=0
    sudo nvme create-ns /dev/nvme2 -s ${znswritable_pages} -c ${znswritable_pages} -b ${pagesize} --csi=2
    sudo nvme attach-ns /dev/nvme2 -c 0 -n 1
    sudo nvme attach-ns /dev/nvme2 -c 0 -n 2
}
