# Artifact structure

In this artifact evaluation we first explain the setup, explain how to get the NVMe info, and then explain all evaluations.
For each evaluation we show how to reproduce the results and where the data is stored of the evaluation (will be overwritten if you evaluate).

All plots are available in `./artifact_plots.ipynb`. The plot name should match the section headers of the artifact steps.
Note that all steps in the notebook NEED to be done in order.

We recommend running all experiments with `nohup` as they can take a while.

# Setup dependencies

Run the following to install all dependencies (we DO NOT install SPDK, fio or NVMe-cli globally):

```bash
sudo apt-get install numactl

pushd ..
git submodule update --init --recursive
cd submodules

cd spdk
sudo scripts/pkgdep.sh
cd ..

cd fio
sudo apt-get install build-essentials libaio-devel
./configure
make
cd ..

cd spdk
./configure --with-fio=../fio --enable-lto
make 
cd ..

cd nvme-cli
meson setup --force-fallback-for=libnvme .build
meson compile -C .build

popd
```

Run the following to install plot dependencies:

```bash
sudo apt-get instal python3-venv
python3 -m venv ./venv
# Must be rerun each time a (new) shell is opened
source ./venv/bin/activate

pip3 install -r plot_requirements.txt
```

# NOTE on NUMA

If the benchmarked server/node has NUMA, it is essential to pin the scripts to exactly one numadomain!
Most scripts currently do not do this automatically. Therefore, run all scripts with:

```bash
sudo numactl -N <x> -m <x> <SCRIPT>
```

# Check NVMe devices

Look for ZNS-capable and non-ZNS-capable devices. We need both.
We also need multiple namespaces. It is not valid to use emulated devices in the experiments, as they are currently not accurate enough.

```bash
# Note down the names of the NVMe devices
sudo nvme zns list
# Note down the names of devices that are not ZNS capable
diff <(sudo nvme zns list) <(sudo nvme list)
```

We need both a ZNS device with a pagesize of 512 bytes and one with 4KiB pages. These can be found with:

```bash
sudo nvme zns list | grep "512"
sudo nvme zns list | grep "4 KiB"
# or
cat /sys/block/<nvmename>/queue/discard_granularity
```

If none are available with either 4k or 512, it is possible to reformat NVMe devices to a different namespace with the correct format. See [./scripts/setup_namespaces.sh](./scripts/setup_namespaces.sh) (change nvme2 with the correct name).

# Append and write performance

## How to reproduce?

```bash
python3 ./grid_bench.py -d <device with lbaf 512 byte pages> -m zns-a -f=./submodules/fio/fio -s=./submodules/spdk -l lbaf0  -o=1
python3 ./grid_bench.py -d <device with lbaf 4KiB byte pages> -m zns-a -f=./submodules/fio/fio -s=./submodules/spdk -l lbaf2  -o=1
```

## Where is the data?

Data for lbaf with 512 byte pages is stored in :

- `data/spdk/zns-a/lbaf0/append`: all data for appends with SPDK
- `data/spdk/zns-a/lbaf0/write`: all data for SPDK with writes
- `data/io_uring/zns-a/lbaf0/write`: all data for io_uring with none scheduler
- `data/io_uring/zns-a/lbaf0/writemq`: all data for io_uring with mq-deadline scheduler

Data for lbaf with 4KiB byte pages is stored in :

- `data/spdk/zns-a/lbaf2/append`: all data for appends with SPDK
- `data/spdk/zns-a/lbaf2/write`: all data for SPDK with writes
- `data/io_uring/zns-a/lbaf2/write`: all data for io_uring with none scheduler
- `data/io_uring/zns-a/lbaf2/writemq`: all data for io_uring with mq-deadline scheduler

In aforementioned directories data is stored in `<request size in bytes>bs/1zone/1.json`.
For example to retrieve 16KiB appends for lbaf2 open `data/spdk/zns-a/lbaf2/append/16384bs/1zone/1.json`.

# Scalability: Intra-zone versus inter-zone performance

## Intra-zone

### How to reproduce?

```bash
python3 ./grid_bench.py -d <device with lbaf 4KiB byte pages> -m zns-a -f=./submodules/fio/fio -s=./submodules/spdk -l lbaf2  -o=1
python3 ./grid_bench_rand_read.py -d <device with lbaf 4KiB byte pages> -m zns-a -f=./submodules/fio/fio -s=./submodules/spdk -l lbaf2  -o=1
```

### Where is the data?

- `data/spdk/zns-a/lbaf2/append/<request size>bs/1zone/<queue depth>.json`: all data for appends
- `data/io_uring/zns-a/lbaf2/writemq/<request size>bs/1zone/<queue depth>.json`: all data for writes with mq-deadline
- `data/spdk/zns-a/lbaf2/randread/<request size>bs/1zone/<queue depth>.json`: all data for concurrent random reads
Request sizes are specified in bytes and deph in integers. For example appending at queue depth 32 with 16KiB requests is found at `data/spdk/zns-a/lbaf2/append/16384bs/1zone/32.json`

## Inter-zone

### How to reproduce?

```bash
python3 ./grid_bench.py -d <device with lbaf 4KiB byte pages> -m zns-a -f=./submodules/fio/fio -s=./submodules/spdk -l lbaf2  -o=1
python3 ./grid_bench_rand_read.py -d <device with lbaf 4KiB byte pages> -m zns-a -f=./submodules/fio/fio -s=./submodules/spdk -l lbaf2  -o=1
# There was an error for 14zones, hence we used a different script for 14 zones.
python3 ./grid_bench_spdk_14zones.py -d <device with lbaf 4KiB byte pages> -m zns-a -f=./submodules/fio/fio -s=./submodules/spdk -l lbaf2  -o=1
```

### Where is the data?

- `data/spdk/zns-a/lbaf2/append/<request size>bs/<number of concurrent zones>zone/1.json`: all data for concurrent appends
- `data/spdk/zns-a/lbaf2/write/<request size>bs/<number of concurrent zones>zone/1.json`: all data for concurrent writes
- `data/spdk/zns-a/lbaf2/randread/<request size>bs/<number of concurrent zones>zone/1.json`: all data for concurrent random reads

Request sizes are specified in bytes and concurrent zones in integers. For example appending to 14 concurrent zones with 8KiB requests is found at `data/spdk/zns-a/lbaf2/append/8192bs/14zone/1.json`

# Zone State Machine Transition Costs

## Build benchmark and get traddr

Build the state machine benchmark with:

```bash
pushd zns_state_machine_perf
mkdir build && cd build
SPDK_PATH=../../submodules/spdk cmake ..
make
popd
```

The benchmark requires the traddr instead of the NVMe name.
Run to get the traddr:

```
cat /sys/block/<nvme with 4k pages>/address
```

## The cost of opening and closing zones

### How to reproduce?

```bash
sudo ./bin/close_test -t <traddr> > data/custom/zns/open_close/run<x>
sudo ./bin/explicit_versus_implicit -t <traddr> > data/custom/zns/explicit_versus_implicit/run<x>
sudo ./bin/pure_read -t <traddr> > data/custom/zns/pure_read/run<x> # We want the open data
sudo ./bin/reset_inteference_reads -t <traddr> > data/custom/zns/inteference/read_reset # We want the open data
sudo ./bin/reset_inteference_appends -t <traddr> > data/custom/zns/inteference/append_reset # We want the open data
sudo ./bin/reset_inteference_writes -t <traddr> > data/custom/zns/inteference/write_reset # We want the open data
```

### Where is the data?

Close data is in `data/custom/zns/open_close/run1` and `data/custom/zns/open_close/run2`.
Open data we reuse from our other tests: `data/custom/zns-a/inteference/write_reset_inteference_fill_opens`,
`data/custom/zns-a/inteference/append_reset_inteference_fill_opens`, `data/custom/zns-a/inteference/read_reset_inteference_fill_open`, and `data/custom/zns-a/inteference/read_reset_inteference_fill_open`.

Data from opening a zone and then filling a zone was retrieved by grepping `open` and catting it to a different file (to avoid git clutter). For example, in our case:

```bash
grep "open," data/custom/zns/inteference/run > data/custom/zns-a/inteference/read_reset_inteference_fill_open
grep "open," data/custom/zns/inteference/... >> data/custom/zns-a/inteference/read_reset_inteference_fill_open
```

Data about implicitly opening a zone and the difference between writing/appending to such a zone is encoded in `data/custom/zns/explicit_versus_implicit/`. As this file was too large for GitHub we did surgery on the file:

```bash
# This explicit_versus_implicit is too large for git, we splice it and only use a part (e.g. for run2 we did)
cd data/custom/zns/explicit_versus_implicit/
grep append_implicit_opened run2 > run2_append_implicitly_opened
grep write_implicit_opened run2 > run2_write_implicitly_opened
grep "append_implicit," run2 | tail -n 100000 > run2_append_implicit
grep "write_implicit," run2 | tail -n 100000 > run2_write_implicit
grep "write_explicit," run2 | tail -n 100000 > run2_write_explicit
grep "append_explicit," run2 | tail -n 100000 > run2_append_explicit
```

## Finish and Reset Latency Costs

### How to reproduce?

```bash
# With x up to the number of runs
sudo ./bin/partial_zone_reset -t <traddr> > data/custom/zns/partial_reset/run<x>
sudo ./bin/partial_zone_reset -t <traddr> > data/custom/zns/partial_reset/run<x+1>
...

sudo ./bin/finish_test -t <traddr> > data/custom/zns/partial_finish/run<x>
sudo ./bin/finish_test -t <traddr> > data/custom/zns/partial_reset/run<x+1>
...
```

### Where is the data?

Partial reset data is aint `data/custom/zns/partial_reset/`. Note that run1, run2, and run3 were run with only some zones and some occupancies (e.g. 100 zones with 25\%).
This can be done as well with:

```
sed -i 's/zone_cnt = zone_cnt - 1/zone_count = 100/g' zns_state_machine_perf.cpp
# Rebuild benchmarks
```

Most usable data is in run4.
Finish data is in `data/custom/zns/partial_finish`. The runs were large, so they are packed in "zips" extract with e.g. `unzip` to investigate (NOT needed for the plots).

# I/O inteference on random reads

## How to reproduce?

```bash
pushd bash_tools
./io_inteference_ratelimit_log.sh <nvmexny> <znsxy>
popd
```

## Where is the data?

- `data/custom/zns-a/long2/`: data for long heavy load inteference runs on ZNS
- `data/custom/zns-a/long3/`: data for long heavy load inteference runs on NVMe
- `data/custom/zns-a/rate_inteference/zns_{write_rate_limit}_{qd}`: data for ZNS with writes
- `data/custom/zns-a/rate_inteference/zns_appends_{write_rate_limit}_{qd}`: data for ZNS with appends
- `data/custom/zns-a/rate_inteference/nvme_{write_rate_limit}_{qd}`: data for NVMe with writes

Set `write_rate_limit` to a number in MiB - e.g., 500MiB to 500 - and set qd to queue depth as an integer - e.g. 32. For example to see the effect of appends rate limited to 250MiB/s on random reads issued at queue depth 32, check `data/custom/zns-a/rate_inteference/zns_appends_250_32`.

# Reset inteference

## Install

Follow build instructions for the `State Machine Transition Cost` experiments.

## How to reproduce

```bash
sudo ./bin/reset_inteference_reads -t <traddr> > data/custom/zns/inteference/read_reset
sudo ./bin/reset_inteference_appends -t <traddr> > data/custom/zns/inteference/append_reset
sudo ./bin/reset_inteference_writes -t <traddr> > data/custom/zns/inteference/write_reset

sudo ./bin/pure_read -t <traddr> > data/custom/zns/pure_read/run<x> # We want random read baseline
```

## Where is the data?

Data is in `data/custom/zns/inteference/`:

- `append_reset_inteference_fill_opens`: Opens when preparing
- `append_reset_inteference_fill_appends`: Appends when preparing (used as baseline without interference)
- `append_reset_inteference_appends`: Appends during resets
- `append_reset_inteference_resets`: Resets during appends
- `read_reset_inteference_fill_open`: Opens when preparing
- `read_reset_inteference_reads`: Reads during resets
- `read_reset_inteference_resets`: Resets during reads
- `write_reset_inteference_fill_opens`: Opens when preparing
- `write_reset_inteference_fill_writes`: Writes when preparing (used as baseline without interference)
- `write_reset_inteference_resets`: Writes during resets
- `write_reset_inteference_writes`: Resets during writes

It was retrieved from the runs with `greps` and `tails` as the original files were too large for GitHub:

```bash
pushd .
cd data/custom/zns/inteference/ 
(grep "reset" append_reset | head -n 100000) > append_reset_inteference_resets
(grep "append_int" append_reset | head -n 100000) > append_reset_inteference_appends
(grep "append," append_reset | head -n 100000) > append_reset_inteference_fill_appends
(grep "open," append_reset | head -n 100000) > append_reset_inteference_fill_opens
(grep "open," write_reset | head -n 100000) > write_reset_inteference_fill_opens
(grep "write," write_reset | head -n 100000) > write_reset_inteference_fill_writes
(grep "write_int" write_reset | head -n 100000) > write_reset_inteference_writes
(grep "reset" write_reset | head -n 100000) > write_reset_inteference_reset
(grep "reset" read_reset | head -n 100000) > read_reset_inteference_resets
(grep "read_int" read_reset | head -n 100000) > read_reset_inteference_reads
(grep "open" read_reset | head -n 100000) > read_reset_inteference_fill_open
(grep append_int append_reset | head -n 100000) > append_reset_inteference_appends
popd
cd data/custom/zns/pure_read/
(grep "read" run<x> | head -n 100000) > fil
```

## RocksDB Benchmark (not used in final paper)

This benchmark reproduces the result of Bjørling, Matias, et al. "ZNS: Avoiding the Block Interface Tax for Flash-based SSDs." USENIX Annual Technical Conference. 2021. (Figure 6). Therefore, we make use of their provided benchmarking setup at [zbdbench](https://github.com/westerndigitalcorporation/zbdbench). It has detailed instructions on setup and running, however we modify it slightly and therefore depict our modifications, and how we run it.

### Modifications

We make two main modifications:

1. Change the number of keys to 1.3 billion (from 3.8 billion) to scale with our device. The diff of the changes are:

```bash
diff --git a/benchs/usenix_atc_2021_zns_eval.py b/benchs/usenix_atc_2021_zns_eval.py
index 3fce92d..e07c068 100644
--- a/benchs/usenix_atc_2021_zns_eval.py
+++ b/benchs/usenix_atc_2021_zns_eval.py
@@ -24,7 +24,8 @@ class Run(Bench):
     # Original run on a 2TB ZNS SSD: (3.8B)
     # scale_num = 3800000000
     # The current state of ZenFS creates a bit more space amplification
-    scale_num = 3300000000
+    # scale_num = 3300000000
+    scale_num = 1300000000
```

2. As F2FS with ZNS requires a conventional (randomly writable) block device, the benchmark sets up a `nullblk` (250GiB in size), which we reduce to only be 10GiB in order to reduce data on the nullblk to only metadata and increase traffic to the ZNS device. The diff of the changes are:

```bash
diff --git a/benchs/usenix_atc_2021_zns_eval.py b/benchs/usenix_atc_2021_zns_eval.py
index 3fce92d..4e8786e 100644
--- a/benchs/usenix_atc_2021_zns_eval.py
+++ b/benchs/usenix_atc_2021_zns_eval.py
@@ -209,6 +210,8 @@ class Run(Bench):

     def create_f2fs_nullblk_dev(self, dev, container):
         dev_config_path = self.create_new_nullblk_dev_config_path()
+        with open(os.path.join(dev_config_path, 'size') , "w") as f:
+            f.write("10240")
```

### Running

With all required perquisites set up, we run as follows. Note, we do not have libraries (libzbd) installed globally and tools such as `db_bench` also not installed globally, therefore we pass the `LD_PRELOAD` and `PATH` for the respective install locations. This is not required when installing everything globally. Furthermore, we use a python virtual environment with installed packages, which is also not required with global installations. The benchmark will run respective benchmarks, depending on if the device is a ZNS or not, therefore the command is the same, only requiring the device name to be changed.

```bash
sudo LD_PRELOAD="/home/nty/local/lib/libzbd.so.2" env "PATH=$PATH" venv/bin/python3 ./run.py -d /dev/nvme4n1 -c no -b usenix_atc_2021_zns_eval
```

### Where to find the data

All generated data is in `data/zbdbench/` for each of the file systems evaluated.

### Plots

While the `zbdbench` framework has a plotting script, we have our own script, located in `analysis/zbdbench.py` to generate our figures. The values from the resulting data are coded into the script.
