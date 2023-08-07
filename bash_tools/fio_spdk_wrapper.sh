#!/bin/bash
# This scripts loads fio with SPDK already preloaded

DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd);
SUBMOD_DIR=${DIR}/../submodules
LD_PRELOAD=${SUBMOD_DIR}/spdk/build/fio/spdk_nvme ${SUBMOD_DIR}/fio/fio "$@"
