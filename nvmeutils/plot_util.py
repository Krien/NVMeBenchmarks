import os
import matplotlib.pyplot as plt
from dataclasses import dataclass


def savefig_to_path(fig, path):
    fig.savefig(path + ".png")
    fig.savefig(path + ".svg")


PLOT_PATH = f"{os.path.realpath(os.path.dirname(__file__))}/../plots"


def get_plot_path(name):
    return f"{PLOT_PATH}/{name}"


@dataclass
class PlotDefinition:
    """Plot definition"""

    path: str
    title: str
    xlabel: str
    ylabel: str
    miny: int
    maxy: int
    minx: int
    maxx: int


@dataclass
class SubplotDefinition:
    """A target for plotting"""

    label: str
    color: str


class GenericPlot:
    def __init__(self, plotdefinition):
        self.plotdefinition = plotdefinition
        self.fig, self.ax = plt.subplots()
        plt.xlabel(self.plotdefinition.xlabel)
        plt.ylabel(self.plotdefinition.ylabel)
        plt.title(self.plotdefinition.title)
        self.ax.grid(True)

    def save_to_disk(self):
        plt.xlim(self.plotdefinition.minx, self.plotdefinition.maxx)
        plt.ylim(self.plotdefinition.miny, self.plotdefinition.maxy)
        plt.legend()
        savefig_to_path(plt, self.plotdefinition.path)
