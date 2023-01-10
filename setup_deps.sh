#!/bin/bash
git submodule update --init --recursive
cd submodules

cd libzbd
sh ./autogen.sh
./configure
make
cd ..

cd fio
./configure
make
cd ..

cd spdk
./configure --with-fio=../fio --enable-lto
make 
cd ..


