# NVMeBenchmarks

In this repository we maintain a set of benchmarks for NVMe devices. Notably we do a grid search over various parameters (Queue depth, block size, concurrent zones in the case of ZNS) with the help of Fio. Further on, in data we have stored the performance of a number of devices. We also come with a set of plotting tools to visualise the data.

# Parameters used for each NVMe device
Each NVMe device is tested with different block sizes and queue depths.
By default all tests are run with queue depths of 1,2,4,8,16,32,64,128,256 and 512. Block sizes are tested based on the pagesize of the device. It tests the following page sizes: 512,1024,2048,4096,8192,16384,32768,65536 and 131072. However, it skips all page sizes smaller than the page size supported by the device. Finally, all devices are tested with different storage engines.

# Storage engines

NVMeBenchmarks currently tests with two storage engines: `SPDK` and `io_uring`.
Io_uring is run in polling mode, with a kernel thread, fixedbuffers and registerfiles.

# NVMe ZNS

ZNS devices require special attention. Before each test the device is reset to ensure a clean slate. To make use of higher queue depth, we need a different method. Io_uring is run with the mq-deadline scheduler and the data is stored as the operation `writemq`. SPDK is run with the `append` operation, which is also aptly stored in the `append` directory.
Since ZNS supports writing to concurrent zones, we also test various zones concurrently in our grid exploration. Currently we test 1,2,3,4,5 concurrent zones.