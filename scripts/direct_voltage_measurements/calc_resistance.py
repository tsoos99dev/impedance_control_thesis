import matplotlib.pyplot as plt
import numpy as np
from scipy import signal, stats

import matplotlib as mpl
from scipy.stats import linregress, t

from const import COUNTS_PER_TURN
from filter import smooth_derivative

mpl.use("tkagg")


def main():
    with open("resistance_measurement.txt", mode="r", encoding='utf8') as file:
        data = file.read()

    data = data.splitlines()
    data = data[2:]
    data = np.array([np.fromstring(line, sep=",", dtype=np.float32) for line in data])
    vm = data[:, 0]
    am = data[:, 1]

    v_reg_info = linregress(am, vm)
    v_reg = v_reg_info.intercept + v_reg_info.slope * am
    resistance = v_reg_info.slope
    ci = stats.t.interval(0.95, len(vm)-2, loc=resistance, scale=v_reg_info.stderr)
    rel_err = 100*(ci[1]-ci[0])/2/resistance
    print(resistance,ci,rel_err)

    fig, ax = plt.subplots()
    ax.set_xlabel("Current [A]")
    ax.set_ylabel("Voltage [V]")
    ax.set_title("Motor resistance measurement")
    ax.grid(True)
    ax.plot(am, v_reg)
    ax.scatter(am, vm)
    ax.text(0.6, 4, f"R = {resistance:.2f}±{rel_err:.2f}%")
    plt.show()


if __name__ == '__main__':
    main()
