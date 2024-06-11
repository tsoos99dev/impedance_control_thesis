import matplotlib.pyplot as plt
import numpy as np
from scipy import signal, stats

import matplotlib as mpl
from scipy.stats import linregress, t

from const import COUNTS_PER_TURN
from filter import smooth_derivative

mpl.use("tkagg")


def main():
    with open("duty_voltages.txt", mode="r", encoding='utf8') as file:
        data = file.read()

    data = data.splitlines()
    data = data[2:]
    data = np.array([np.fromstring(line, sep=",", dtype=np.float32) for line in data])
    dm = data[:, 0]
    vm = 12.00 - data[:, 1]

    v_reg_info = linregress(dm, vm)
    v_reg = v_reg_info.intercept + v_reg_info.slope * dm
    slope = v_reg_info.slope
    ci = stats.t.interval(0.95, len(vm)-2, loc=slope, scale=v_reg_info.stderr)
    rel_err = 100*(ci[1]-ci[0])/2/slope
    print(slope,ci,rel_err)

    fig, ax = plt.subplots()
    ax.set_xlabel("Duty [%]")
    ax.set_ylabel("Voltage (avg) [V]")
    ax.set_title("Driver voltage measurement")
    ax.grid(True)
    ax.plot(dm, v_reg)
    ax.scatter(dm, vm)
    ax.text(50, 4, f"Slope = {slope:.2f}±{rel_err:.2f}%")
    plt.show()


if __name__ == '__main__':
    main()
