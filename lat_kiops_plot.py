from bench_utils import *
from typing import List
import argparse

ALLOWED_QDS = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024]


class LatencyThroughputPlot(GenericPlot):
    def plot_line(self, subplotdefinition, kiops, lats, qds):
        plt.plot(
            kiops,
            lats,
            linewidth=3,
            label=subplotdefinition.label,
            color=subplotdefinition.color,
        )
        for i in range(len(kiops)):
            plt.plot(kiops[i], lats[i], "o", color=subplotdefinition.color)
            plt.text(
                kiops[i] * (1.01), lats[i] * (1.01), s="qd=" + str(qds[i]), fontsize=9
            )


@dataclass
class LatKIOPSSpec:
    """A specification for the data lat_kiops needs"""

    kiops: List[int]
    lats: List[int]
    plot_color: str


def plot_lot_kiops(
    filename: str,
    title: str,
    labels: List[str],
    models: List[str],
    lbafs: List[str],
    operations: List[str],
    engines: List[str],
    concurrent_zones: List[int],
    block_sizes: List[int],
    queue_depth_limit: int,
    lower_limit_y: int,
    upper_limit_y: int,
    lower_limit_x: int,
    upper_limit_x: int,
    prep_function_x: str,
    prep_function_y: str,
):
    # Plot
    colors = ["cyan", "magenta", "green", "red", "orange", "black", "gray", "yellow"]
    pick_color = iter(colors)
    qds = [qd for qd in ALLOWED_QDS if qd < queue_depth_limit]

    merged_dat = zip(
        labels, models, engines, lbafs, operations, concurrent_zones, block_sizes
    )
    plot_data = {}
    for (
        label,
        model,
        engine,
        lbaf,
        operation,
        concurrent_zone,
        block_size,
    ) in merged_dat:
        plot_data[label] = LatKIOPSSpec([], [], next(pick_color))
        for qd in qds:
            print(
                f"Adding to plot: label={label}, model={model}, engine={engine}, lbaf={lbaf}, op={operation}, zones={concurrent_zone}, qd={qd}, block_size={block_size}"
            )
            fio_dat = parse_fio_file(
                BenchPath(
                    string_to_io_engine(engine),
                    model,
                    lbaf,
                    operation,
                    concurrent_zone,
                    qd,
                    block_size,
                )
            )
            plot_data[label].kiops.append(
                prep_function(prep_function_x, fio_dat.iops_mean)
            )
            plot_data[label].lats.append(
                prep_function(prep_function_y, fio_dat.lat_mean)
            )

    plot = LatencyThroughputPlot(
        PlotDefinition(
            get_plot_path(filename),
            title,
            "Througput (KIOPS)",
            "Latency (micros)",
            lower_limit_y,
            upper_limit_y,
            lower_limit_x,
            upper_limit_x,
        )
    )

    for label in labels:
        lat_kiops = plot_data[label]
        plot.plot_line(
            SubplotDefinition(label, lat_kiops.plot_color),
            lat_kiops.kiops,
            lat_kiops.lats,
            qds,
        )

    plot.save_to_disk()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Plot latency and throughput of NVMe SSDs in one graph"
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
    parser.add_argument("-o", "--operations", type=str, nargs="+", required=True)
    parser.add_argument("-c", "--concurrent_zones", type=int, nargs="+", required=True)
    parser.add_argument("-b", "--block_sizes", type=int, nargs="+", required=True)
    parser.add_argument(
        "-q", "--queue_depth_limit", type=int, required=False, default=256
    )
    parser.add_argument("--lower_limit_y", type=int, required=False, default=0)
    parser.add_argument("--upper_limit_y", type=int, required=False, default=550)
    parser.add_argument("--lower_limit_x", type=int, required=False, default=0)
    parser.add_argument("--upper_limit_x", type=int, required=False, default=300)
    parser.add_argument(
        "--transform_x",
        type=str,
        required=False,
        choices=["none", "div1000", "div1000log"],
        default="div1000",
    )
    parser.add_argument(
        "--transform_y",
        type=str,
        required=False,
        choices=["none", "div1000", "div1000log"],
        default="div1000",
    )
    parser.add_argument("--filename", type=str, required=False, default="out")

    args = parser.parse_args()
    labels = args.labels
    models = args.models
    engines = args.engines
    lbafs = args.lbafs
    operations = args.operations
    concurrent_zones = args.concurrent_zones
    block_sizes = args.block_sizes
    if (
        len(labels) != len(models)
        or len(models) != len(lbafs)
        or len(engines) != len(lbafs)
        or len(engines) != len(operations)
        or len(operations) != len(concurrent_zones)
        or len(concurrent_zones) != len(block_sizes)
    ):
        print("List args must have equal length")
        exit(1)

    plot_lot_kiops(
        args.filename,
        args.title,
        labels,
        models,
        lbafs,
        operations,
        engines,
        concurrent_zones,
        block_sizes,
        args.queue_depth_limit,
        args.lower_limit_y,
        args.upper_limit_y,
        args.lower_limit_x,
        args.upper_limit_x,
        args.transform_x,
        args.transform_y,
    )
