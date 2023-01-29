# Install

Ensure SPDK is installed, custom or the submodule. When using the submodule built SPDK with:
```
cd submodules/spdk
sudo ./scripts//pkgdep.sh
./configure --with-lto --with-fio=../fio # We use fio from the submodule
make
```

Then built these tools with:
``` 
mkdir build && cd build
SPDK_PATH=../../submodules/spdk cmake ..
make
```
 
All tools are installed in `./bin`
# Usage

Use any of the generated tools, like `close_test` with:
```
sudo ./bin/close_test -t <traddr of the ZNS device>
``` 
Make sure the device is not attached to the kernel and SPDK is initialized, e.g. with:
```
cat /sys/block/<dev>/device/address # Copy this value to traddr
sudo PCI_ALLOWED=<traddr> ../submodules/spdk/scripts/setup.sh
```

# tools

- `close_test`: measure performance of close operation, prints cost of closing implicitly and explicitly opened zones - and writing a closed zone. 
- `explicit_versus_implicit`: maesure performance of writing/appending to an implicitly/explicitly opened zone
- `finish_test`: measure finish latency (partial zones) and resetting finished zones
- `partial_zone_reset`: maesure latency of resesetting (partial) zones
- `pure_read_test`: maesure random read latency (sanity)
- `pure_reset`: measure latency of resetting full zones
- `reset_inteference`: measure interference effects between resets and writes/appends/random reads
