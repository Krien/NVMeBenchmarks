# ZNS NVMeBenchmarks

This repository contains benchmarks and benchmark data for ZNS:

* Throughput and latency benchmarks for NVMe ZNS devices that make use of the benchmark tool [fio](https://github.com/axboe/fio) with ioengines SPDK and io_uring.
* Benchmarks to trigger GC for traditional NVMe devices.
* Benchmarks for ZNS state transitions, see [zns_state_machine_perf](./zns_state_machine_perf/).

## Dependencies/installation

Experiments and plots can be run on seperate machines.

### For running the benchmarks

The experiments are only tested on Ubuntu 20 with Linux 5.17. We do not guarantee functionality on other OS configurations.
To setup the dependencies of our framework, please run [./setup_deps.sh](./setup_deps.sh).
To use the tools it the dependencies in  [requirements.txt](./requirements.txt) are not needed, the only requirement is Python >= 3.8. The requirement file is for the notebooks.

### For plotting (as done in the paper)

```python
pip install -r plot_requirements.txt
```

### For interactive plotting

```python
pip install -r plot_requirements_jupyter.txt
jupyter nbextension enable --py --sys-prefix widgetsnbextension 
```

# Notable benchmarks

* [grid_bench.py](./grid_bench.py): works for NVMe/NVMe ZNS. Explores write/append performance at various request sizes/queue depths/concurrent zones/schedulers
* [io_inteference_ratelimit_log,sh](./bash_tools/io_inteference_ratelimit_log.sh): effect of writes/appends on random reads
* [grid_bench_seq_read.py](./grid_bench_seq_read.py): sequential read performance at request sizes/depth
* [grid_bench_rand_read.py](./grid_bench_rand_read.py): random read performance at request sizes/depth
* [concurrent_namespace.py](./concurrent_namespace.py): inteference effect of namespaces
* [rand_write_bench.py](./rand_write_bench.py): used for NVMe for random write performance, preconditioning/steady-state and after
* [explicit_versus_implicit](./zns_state_machine_perf/bin/explicit_versus_implicit.cpp): Cost of explicit/implicit zone opens
* [finish_test](./zns_state_machine_perf/finish_test.cpp): Cost of finishing zones
* [partial_zone_reset](./zns_state_machine_perf/partial_zone_reset.cpp): Cost of resets of (partially-filled) zones
* [pure_read_test](./zns_state_machine_perf/pure_read_test.cpp): Cost of sequential reads in zones
* [reset_inteference_appends](./zns_state_machine_perf/reset_inteference_appends.cpp): I/O inteference of appends on resets and vice versa
* [reset_inteference_reads](./zns_state_machine_perf/reset_inteference_reads.cpp): I/O inteference of reads on resets and vice versa
* [reset_inteference_appends](./zns_state_machine_perf/reset_inteference_appends.cpp): I/O inteference of writes on resets and vice versa

# Directory structure

* All tools are maintained in `./*.py` for throughput/latency, `./bash_tools/*sh` for I/O inteference, `./zns_state_machine_perf` for ZNS states.
* [artifacts](./artifacts) contains code to reproduce the results of [IEEE Cluster 2023](https://ieeexplore.ieee.org/abstract/document/10319951).
* All benchmark data is maintained in [data](./data) and organized in the following format `data/engine/model_name/namespace_format/operation/concurrent_zones/queue_depth.json`
* All run fio jobs are maintained in [jobs](./jobs) and organized in the following format `jobs/engine/model_name/namespace_format/operation/concurrent_zones/queue_depth.fio`
* Generic/common jobs are stored in [predefined_jobs](./predefined_jobs)
* [analysis](./analysis) contains `Jupyter Notebooks` for investigating/exploring the data
* [example_runs](example_runs) and [example_plots](example_plots) contain examples of running tests and generating plots respectively
* Utils for running Python benchmarks are maintained in [bench_utils](./bench_utils/)
* Utils for plotting in Python are maintained in [plot_utils](./plot_utils)
* [tools](./tools) contains the tracing tool to generate heatmaps of ZNS activity for zones

# About testing NVMe ZNS

ZNS devices require special attention. We note down the biggest issues here.

## Preconditioning

There is no default peconditioning method for NVMe. Instead, we try to come close by first filling all zones multiple times (4x). As a result the device should always be close to filled.

## Write queue depth

In ZNS we can not make use of writes with higher queue depth, unless we make use of a scheduler or the append operation. SPDK is the only engine that currently enables appends, but does not allow for a scheduler like mq-deadline. Therefore, Io_uring is run with the `mq-deadline` scheduler when we require a high queue depth, defined as the operation `writemq` in jobs/plots/data. SPDK is run with the `append` operation, which is also aptly defined as the `append` operatio.

## Leaking active zones

Fio does not always ensure that all of it zones are finished or filled once the job finishes, therefore we do it manually.
Between most write tests we finish zones to prevent leaking active zones in fio.

# Storage engines opions

NVMeBenchmarks currently tests with two storage engines: `SPDK` and `io_uring`.
Io_uring is run in polling mode (hipri), with a kernel thread (sqthread_poll), fixedbuffers and registerfiles to achieve optimal performance.

# Artifact evaluation

This benchmarking tooling/data is used in [IEEE Cluster 2023](https://ieeexplore.ieee.org/abstract/document/10319951) to ensure the work is reproducible.
To reproduce the results of the paper see [artifact_evaluation](./artifacts/artifact_evaluation.md) and all of the raw data see [data](./data).
