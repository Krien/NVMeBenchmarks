from nvmeutils import *
from typing import List
import argparse


class ConcurrentZonesThroughputPlot(GenericPlot):
    def plot_line(self, subplotdefinition, concurrent_zones, kiops):
        plt.plot(
            range(len(concurrent_zones)),
            kiops,
            linewidth=3,
            label=subplotdefinition.label,
            color=subplotdefinition.color,
        )
        plt.xticks(range(len(concurrent_zones)), concurrent_zones)


@dataclass
class ConcurrentZonesKIOPSSpec:
    """A specification for the data lat_kiops needs"""

    concurrent_zones: List[int]
    kiops: List[int]
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
        queue_depths,
        block_sizes,
    )
    plot_data = {}

    for (
        label,
        model,
        engine,
        lbaf,
        operation,
        qd,
        block_size,
    ) in merged_dat:
        plot_data[label] = ConcurrentZonesKIOPSSpec([], [], next(pick_color))
        for concurrent_zone in concurrent_zones:
            print(
                f"Adding to plot: label={label}, model={model}, engine={engine}, lbaf={lbaf}, op={operation}, zones={concurrent_zone}, qd={qd}, block_size={block_size}"
            )
            fio_dat = parse_fio_file(
                DataPath(
                    engine, model, lbaf, operation, concurrent_zone, qd, block_size
                )
            )
            plot_data[label].concurrent_zones.append(concurrent_zone)
            plot_data[label].kiops.append(
                prep_function(prep_function_y, fio_dat.iops_mean)
            )

    plot = ConcurrentZonesThroughputPlot(
        PlotDefinition(
            get_plot_path(filename),
            title,
            "Concurrent zones (striped)",
            "Througput (KIOPS)",
            lower_limit_y,
            upper_limit_y,
            0,
            len(concurrent_zones),
        )
    )

    for label in labels:
        concurrent_zones_kiops = plot_data[label]
        plot.plot_line(
            SubplotDefinition(label, concurrent_zones_kiops.plot_color),
            concurrent_zones_kiops.concurrent_zones,
            concurrent_zones_kiops.kiops,
        )

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
                        type=int, nargs="+", required=False, default=[1, 2, 3, 4, 5])
    parser.add_argument("-b", "--block_sizes", type=int,
                        nargs="+", required=True)
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
    parser.add_argument(
        "--filename",
        type=str,
        required=False,
        default="out"
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
        or len(operations) != len(block_sizes)
        or len(block_sizes) != len(queue_depths)
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
        queue_depths,
        args.lower_limit_y,
        args.upper_limit_y,
        args.transform_y,
    )
