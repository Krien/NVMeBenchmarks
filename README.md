# ZNS NVMeBenchmarks

This repository contains benchmarks and benchmark data for ZNS:

* Throughput and latency benchmarks for NVMe ZNS devices that make use of the benchmark tool [fio](https://github.com/axboe/fio) with ioengines SPDK and io_uring.
* Benchmarks to trigger GC for traditional NVMe devices.
* Benchmarks for ZNS state transitions, see [zns_state_machine_perf](./zns_state_machine_perf/).

# Artifact evaluation

This benchmarking tooling/data is used in [TODO name] to ensure the work is reproducible.
To run the artifacts see [artifact_evaluation](./artifacts/artifact_evaluation.md) and all of the raw data see [data](./data).

## Dependencies/installation

Experiments and plots can be run on seperate machines.

### For running the benchmarks

The experiments are only tested on Ubuntu 20 with Linux 5.17. Please run `./setup_deps.sh` and use the exact versions of the tools specified.
You do not need any of the python dependencies listed in the "requirements.txt" to run the code, just Python >= 3.8.

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

* `grid_bench.py`: works for NVMe/NVMe ZNS. Explores write/append performance at various request sizes/queue depths/concurrent zones/schedulers
* `io_inteference_ratelimit_log.sh` effect of writes/appends on random reads
* `grid_bench_read.py`: sequential read performance at request sizes/depth
* `concurrent_namespace.py`: inteference effect of namespaces
* `rand_write_bench.py`: used for NVMe for random write performance, preconditioning/steady-state and after
* `zns_state_machine_perf/bin/explicit_versus_implicit`: Cost of explicit/implicit zone opens
* `zns_state_machine_perf/bin/finish_test`: Cost of finishing zones
* `zns_state_machine_perf/bin/partial_zone_reset`: Cost of resets of (partially-filled) zones
* `zns_state_machine_perf/bin/pure_read_test`: Cost of sequential reads in zones
* `zns_state_machine_perf/bin/reset_inteference_appends`: I/O inteference of appends on resets and vice versa
* `zns_state_machine_perf/bin/reset_inteference_reads`: I/O inteference of reads on resets and vice versa
* `zns_state_machine_perf/bin/reset_inteference_appends`: I/O inteference of writes on resets and vice versa

# Directory structure

* All tools are maintained in `./*.py` for throughput/latency, `./bash_tools/*sh` for I/O inteference, `./zns_state_machine_perf` for ZNS states.
* `./artifacts` contains artifact evaluations.
* All data is maintained in `data` and organized as `data/engine/model_name/namespace_format/operation/concurrent_zones/queue_depth.json`
* All run fio jobs are maintained in `jobs` and organized as `jobs/engine/model_name/namespace_format/operation/concurrent_zones/queue_depth.fio`
* Generic/common jobs are in `predefined_jobs`
* Analysis contains `Jupyter Notebooks` for investigating/exploring the data
* `example_runs` and `example_plots` contain examples of running tests and generating plots respectively
* Utils for running Python benchmarks is maintained in `bench_utils`
* Utils for plotting in Python is maintained in `plot_utils`
* `tools/` contains the tracing tool to generate heatmaps of ZNS activity for zones

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
