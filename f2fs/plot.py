#!/usr/bin/env python3

import matplotlib.pyplot as plt
import math
import numpy as np
import matplotlib.patches as mpatches
import os
import glob
import json
import getopt
import sys

plt.rc('font', size=12)          # controls default text sizes
plt.rc('axes', titlesize=12)     # fontsize of the axes title
plt.rc('axes', labelsize=12)    # fontsize of the x and y labels
plt.rc('xtick', labelsize=12)    # fontsize of the tick labels
plt.rc('ytick', labelsize=12)    # fontsize of the tick labels
plt.rc('legend', fontsize=12)    # legend fontsize

def parse_fio_data(data_path, data):
    if not os.path.exists(f'{data_path}') or \
            os.listdir(f'{data_path}') == []: 
        print(f'No data in {data_path}')
        return 0 
    file_counter = 0

    for file in glob.glob(f'{data_path}/*.log'): 
        data[file_counter] = []
        with open(file, 'r') as f:
            for index, line in enumerate(f, 1):
                newline = line.split()
                if len(newline) < 1:
                    break
                else:
                    data[file_counter].append(int(newline[1][:-1]))
        file_counter += 1

    return 1

def plot_bw(nvme_data, zns_data):
    nvme_bw = [] 
    nvme_bw_x = []
    zns_bw = [] 
    zns_bw_x = []

    total_bw = 0
    bw_iter_tracker = 0

    max_iter = 0
    for key, item in nvme_data.items():
        if max_iter == 0:
            max_iter = len(item) - 1
        elif max_iter > len(item) - 1:
            max_iter = len(item) - 1

    for iter in range(max_iter):
        for key, item in nvme_data.items(): 
            if iter >= len(item):
                break
            total_bw += item[iter]
        nvme_bw.append(total_bw/1024)
        bw_iter_tracker += total_bw/1024/1024/1024
        nvme_bw_x.append(bw_iter_tracker)
        total_bw = 0

    total_bw = 0
    bw_iter_tracker = 0

    max_iter = 0
    for key, item in zns_data.items():
        if max_iter == 0:
            max_iter = len(item) - 1
        elif max_iter > len(item) - 1:
            max_iter = len(item) - 1

    for iter in range(max_iter):
        for key, item in zns_data.items(): 
            if iter >= len(item):
                break
            total_bw += item[iter]
        zns_bw.append(total_bw/1024)
        bw_iter_tracker += total_bw/1024/1024/1024
        zns_bw_x.append(bw_iter_tracker)
        total_bw = 0

    nvme_bw_np = np.asarray(nvme_bw)
    nvme_bw_fmt = np.nanmean(np.pad(nvme_bw_np.astype(float), (0, 3 - nvme_bw_np.size%3), mode='constant', constant_values=np.NaN).reshape(-1, 3), axis=1)
    nvme_x_np = np.asarray(nvme_bw_x)
    nvme_x_fmt = np.nanmean(np.pad(nvme_x_np.astype(float), (0, 3 - nvme_x_np.size%3), mode='constant', constant_values=np.NaN).reshape(-1, 3), axis=1)
    zns_bw_np = np.asarray(zns_bw)
    zns_bw_fmt = np.nanmean(np.pad(zns_bw_np.astype(float), (0, 3 - zns_bw_np.size%3), mode='constant', constant_values=np.NaN).reshape(-1, 3), axis=1)
    zns_x_np = np.asarray(zns_bw_x)
    zns_x_fmt = np.nanmean(np.pad(zns_x_np.astype(float), (0, 3 - zns_x_np.size%3), mode='constant', constant_values=np.NaN).reshape(-1, 3), axis=1)

    fig, ax = plt.subplots()
    
    ax.errorbar(zns_x_fmt, zns_bw_fmt, label="F2FS (ZNS)", fmt="-")
    ax.errorbar(nvme_x_fmt, nvme_bw_fmt, label="F2FS", fmt="-")
    
    fig.tight_layout()
    ax.grid(which='major', linestyle='dashed', linewidth='1')
    ax.set_axisbelow(True)
    ax.legend(loc='upper right')
    ax.set_xlabel("Data Written (TiB)")
    ax.set_ylabel("Bandwidth (MiB/s)")
    ax.set_ylim(0, 1500)
    ax.set_xlim(0, 2.6)
    plt.savefig(f"f2fs_long_write_gc.pdf", bbox_inches="tight")
    plt.clf()

if __name__ == '__main__':
    """
    Plots the bandwidth over time with the total amount written.
    Requires the paths for the data containing the logs for F2FS and F2FS with ZNS.
    
    Arguments:
        -n: relative path normal NVMe SSD data
        -z: relative path to ZNS data
    """

    file_path = '/'.join(os.path.abspath(__file__).split('/')[:-1])
    
    nvme_path = None
    zns_path = None

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'n:z:', ['n=', 'z='])
    except getopt.GetoptError:
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-n':
            nvme_path = arg
        if opt == '-z':
            zns_path = arg

    if nvme_path == None or zns_path == None:
        print(f"Error, missing arguments. < -n nvme_data path > < -z zns_data path >")

    nvme_data = dict()
    zns_data = dict()
    parse_fio_data(f'{file_path}/{nvme_path}/', nvme_data)
    parse_fio_data(f'{file_path}/{zns_path}/', zns_data)

    plot_bw(nvme_data, zns_data)
