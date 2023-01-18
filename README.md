# ZNS NVMeBenchmarks

This repository contains benchmarks and benchmark data for ZNS:
* Benchmarks for NVMe ZNS devices that make use of the benchmark tool [fio](https://github.com/axboe/fio) with ioengines SPDK and io_uring.
* Results of the benchmarks in this repo for a number of devices. All fio jobs that were can be found in `jobs`, and all data can be found in `data`.
* Tooling that can easily generate/parse fio jobs
* Some python wrapppers around fio and NVMe

# Paper [TODO name] reproducibility

This benchmarking tooling/data is used in [TODO name] To ensure the work is reproducible we noted all relevant data. The benchmarks that were run for this paper can be found in `paper_results/run_jobs.sh` and the raw I/O jobs that were run for this paper can be found in `jobs/data/io_uring/zns-a` and `jobs/data/spdk/zns-a`. The resulting data can be found in `data/data/io_uring/zns-a` and `data/data/spdk/zns-a`. To continue, tool versions are noted down in the git submodules and OS/Hardware is maintained in `paper_results/specs.md`. Lastly, the plots can be found in `paper_results/gen_plots.sh`


## Dependancies/installation

We took great care to insure you do not need to install the plot dependencies on the hardware that you will use to run tests. Please follow the instructions for the relevant tool.

### For running the benchmarks

Please use the instructions from `./install.sh` and use the exact versions of the tools specified.
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
* grid_bench.py: works for NVMe/NVMe ZNS. Explores write/append performance at various request sizes/queue depths/concurrent zones/schedulers
* nvme_bench.sh: old shell variant of grid_bench.py. Used for nvme-a and nvme-b. 
* grid_bench_inteference.py and grid_bench_inteference_inverse.py: works for ZNS. Effect of writes/append on random reads
* grid_bench_read.py: sequential read performance at request sizes/depth
* concurrent_namespace.py: inteference effect of namespaces
* rand_write_bench.py: used for NVMe for random write performance, preconditioning/steady-state and after

# Directory structure

* All tools are maintained in `.`.
* paper_data contains paper relevant runs/data
* All data is maintained in `data` and organized as `data/engine/model_name/namespace_format/operation/concurrent_zones/queue_depth.json`
* All run fio jobs are maintained in `jobs` and organized as `jobs/engine/model_name/namespace_format/operation/concurrent_zones/queue_depth.fio`
* Generic/common jobs are in `predefined_jobs`
* Analysis contains Jupyter Notebooks for investigating/exploring the data
* example_runs and example_plots contain examples of running tests and generating plots respectively
* Utils for running benchmarks is maintained in `bench_utils`
* Utils for plotting is maintained in `plot_utils`


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



