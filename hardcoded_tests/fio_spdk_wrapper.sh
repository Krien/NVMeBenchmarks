#!/bin/bash

LD_PRELOAD=./submodule/spdk/build/fio/spdk_nvme ./submodule/fio/fio "$@"
