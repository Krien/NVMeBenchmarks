from nvmeutils import *
from typing import List
import argparse


class BSThroughputPlot(GenericPlot):
    def plot_line(self, subplotdefinition, bss, kiops, width, offset):
        plt.bar(
            [x + offset for x in range(len(bss))],
            kiops,
            width=width,
            label=subplotdefinition.label,
            color=subplotdefinition.color,
        )

    def plot_axis(self, bss):
        plt.xticks([x + 0.5 for x in range(len(bss))], [str(bs) for bs in bss])


@dataclass
class BSKIOPSSpec:
    """A specification for the data lat_kiops needs"""

    bss: List[int]
    kiops: List[int]
    plot_color: str


def plot_lot_kiops(
    title: str,
    labels: List[str],
    models: List[str],
    lbafs: List[str],
    operations: List[str],
    engines: List[str],
    concurrent_zones: List[int],
    block_sizes: List[int],
    queue_depths: List[int],
    lower_limit_y: int,
    upper_limit_y: int,
    prep_function_y: str,
):
    # Plot
    colors = ["cyan", "magenta", "green", "red",
              "orange", "black", "gray", "yellow"]
    pick_color = iter(colors)

    merged_dat = zip(
        labels,
        models,
        engines,
        lbafs,
        operations,
        concurrent_zones,
        queue_depths,
    )
    plot_data = {}

    for (
        label,
        model,
        engine,
        lbaf,
        operation,
        concurrent_zone,
        qd,
    ) in merged_dat:
        plot_data[label] = BSKIOPSSpec([], [], next(pick_color))
        for bs in block_sizes:
            print(
                f"Adding to plot: label={label}, model={model}, engine={engine}, lbaf={lbaf}, op={operation}, zones={concurrent_zone}, qd={qd}, block_size={bs}"
            )
            try:
                fio_dat = parse_fio_file(
                    DataPath(engine, model, lbaf, operation,
                             concurrent_zone, qd, bs)
                )
                plot_data[label].bss.append(bs)
                plot_data[label].kiops.append(
                    prep_function(prep_function_y, fio_dat.iops_mean)
                )
            except:
                plot_data[label].bss.append(bs)
                plot_data[label].kiops.append(
                    prep_function(prep_function_y, 0))

    plot = BSThroughputPlot(
        PlotDefinition(
            get_plot_path(title),
            title,
            "Block size (bytes)",
            "Througput (KIOPS)",
            lower_limit_y,
            upper_limit_y,
            0,
            len(block_sizes),
        )
    )

    offset = 0.25 + (0.5 / len(labels)) / 2
    for label in labels:
        bs_kiops = plot_data[label]
        plot.plot_line(
            SubplotDefinition(label, bs_kiops.plot_color),
            bs_kiops.bss,
            bs_kiops.kiops,
            0.5 / len(labels),
            offset,
        )
        offset += 0.5 / len(labels)
    plot.plot_axis(block_sizes)

    plot.save_to_disk()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Plot queue depth and throughput of NVMe SSDs in one graph"
    )
    parser.add_argument("-t", "--title", type=str, required=True)
    parser.add_argument("-l", "--labels", type=str, nargs="+", required=True)
    parser.add_argument("-m", "--models", type=str, nargs="+", required=True)
    parser.add_argument("-f", "--lbafs", type=str, nargs="+", required=True)
    parser.add_argument(
        "-e",
        "--engines",
        type=str,
        nargs="+",
        choices=["spdk", "io_uring"],
        required=True,
    )
    parser.add_argument("-o", "--operations", type=str,
                        nargs="+", required=True)
    parser.add_argument("-c", "--concurrent_zones",
                        type=int, nargs="+", required=True)
    parser.add_argument(
        "-b",
        "--block_sizes",
        type=str,
        nargs="+",
        required=False,
        default=[512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072],
    )
    parser.add_argument("-q", "--queue_depths", type=int,
                        nargs="+", required=True)
    parser.add_argument("--lower_limit_y", type=int, required=False, default=0)
    parser.add_argument("--upper_limit_y", type=int,
                        required=False, default=550)
    parser.add_argument(
        "--transform_y",
        type=str,
        required=False,
        choices=["none", "div1000", "div1000log"],
        default="div1000",
    )

    args = parser.parse_args()
    labels = args.labels
    models = args.models
    engines = args.engines
    lbafs = args.lbafs
    operations = args.operations
    concurrent_zones = args.concurrent_zones
    block_sizes = args.block_sizes
    queue_depths = args.queue_depths
    if (
        len(labels) != len(models)
        or len(models) != len(lbafs)
        or len(engines) != len(lbafs)
        or len(engines) != len(operations)
        or len(operations) != len(concurrent_zones)
        or len(concurrent_zones) != len(queue_depths)
    ):
        print("List args must have equal length")
        exit(1)

    plot_lot_kiops(
        args.title,
        labels,
        models,
        lbafs,
        operations,
        engines,
        concurrent_zones,
        block_sizes,
        args.queue_depths,
        args.lower_limit_y,
        args.upper_limit_y,
        args.transform_y,
    )
