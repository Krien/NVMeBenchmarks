#!/usr/bin/env python3

import matplotlib.pyplot as plt
import math
import numpy as np
import matplotlib.patches as mpatches
import os
import glob
import json

plt.rc('font', size=12)          # controls default text sizes
plt.rc('axes', titlesize=12)     # fontsize of the axes title
plt.rc('axes', labelsize=12)    # fontsize of the x and y labels
plt.rc('xtick', labelsize=12)    # fontsize of the tick labels
plt.rc('ytick', labelsize=12)    # fontsize of the tick labels
plt.rc('legend', fontsize=12)    # legend fontsize

def plot_throughput():
    x = np.arange(0, 2)

    # Data is in ../data/zbdench
    xfs_iops = [103.926, 56.749]
    f2fs_iops = [103.926, 56.749] # TEMP VALUES
    f2fs_zns_iops = [94.406, 81.127]
    zenfs_iops = [103.913, 92.196]

    fig, ax = plt.subplots()

    # With number avove bar
    # rects1 = ax.bar(x - 0.2, f2fs_iops, width=0.35, capsize=3, label="F2FS") 
    # rects2 = ax.bar(x + 0.2, zenfs_iops, width=0.35, capsize=3, label="ZenFS")
    # ax.bar_label(rects1, padding=3, fmt="%.1f")
    # ax.bar_label(rects2, padding=3, fmt="%.1f")

    ax.bar(x - 0.15, xfs_iops, width=0.1, capsize=3, color="#117733", label="xfs") 
    ax.bar(x - 0.05, f2fs_iops, width=0.1, capsize=3, color="#999933", label="F2FS") 
    ax.bar(x + 0.05, f2fs_zns_iops, width=0.1, capsize=3, color="#88CCEE", label="F2FS (ZNS)") 
    ax.bar(x + 0.15, zenfs_iops, width=0.1, capsize=3, color="#CC6677", label="ZenFS")

    fig.tight_layout()
    ax.set_axisbelow(True)
    ax.grid(which='major', linestyle='dashed', linewidth='1')
    ax.legend(loc='upper right', ncol=2)
    ax.xaxis.set_ticks(x)
    ax.xaxis.set_ticklabels(["fillrandom", "overwrite"])
    ax.set_ylim(bottom=0,top=120)
    ax.set_ylabel('KIOPS')
    plt.savefig(f'rocksdb-atc-eval.pdf', bbox_inches='tight')
    plt.clf()

if __name__ == '__main__':
    file_path = '/'.join(os.path.abspath(__file__).split('/')[:-1])

    plot_throughput()
