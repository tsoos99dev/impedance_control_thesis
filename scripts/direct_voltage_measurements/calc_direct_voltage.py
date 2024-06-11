import matplotlib.pyplot as plt
import numpy as np
from scipy import stats

import matplotlib as mpl
from scipy.stats import linregress

from const import COUNTS_PER_TURN
from filter import smooth_derivative

mpl.use("tkagg")


def main():
    with open("direct_voltage_response.txt", mode="r", encoding='utf8') as file:
        direct_voltage_response = file.read()

    with open("direct_voltages.txt", mode="r", encoding='utf8') as file:
        direct_voltages = file.read()

    data = direct_voltage_response.splitlines()
    data = data[1:-1]
    data = np.array([np.fromstring(line, sep=",", dtype=np.float32) for line in data])
    _, idx = np.unique(data[:, 0], return_index=True)
    data = data[idx]
    xp = data[:, 0]
    yp = np.unwrap(data[:, 1] - data[0, 1], period=65535)

    samples = len(xp)
    x = np.linspace(xp[0], xp[-1], samples)
    y = np.interp(x, xp, yp)

    dt = (x[-1] - x[0]) / samples * 1e-3  # s
    fs = float(1 / dt)

    dy = smooth_derivative(y, fs)
    dy = dy / COUNTS_PER_TURN * 60

    data = direct_voltages.splitlines()
    data = data[2:]
    data = np.array([np.fromstring(line, sep=",", dtype=np.float32) for line in data])
    tm = 1000*data[:, 0]
    vm = data[:, 1]
    am = data[:, 2]

    measurement_indices = [
        np.where(x > t)[0][0]
        for t in tm
    ]

    # 10 second average
    speed_average = [
        np.average(dy[ind:ind+10000])
        for ind in measurement_indices
    ]

    speed_linear_reg_info = linregress(vm, speed_average)
    speed_reg = speed_linear_reg_info.intercept + speed_linear_reg_info.slope*vm
    speed_constant = speed_linear_reg_info.slope
    ci = stats.t.interval(0.95, len(vm) - 2, loc=speed_constant, scale=speed_linear_reg_info.stderr)
    rel_err = 100 * (ci[1] - ci[0]) / 2 / speed_constant
    print(speed_constant, ci, rel_err)

    fig, ax = plt.subplots()
    ax.set_xlabel("Voltage [V]")
    ax.set_ylabel("Speed [rpm]")
    ax.set_title("Motor speed measurement")
    ax.grid(True)
    ax.plot(vm, speed_reg)
    ax.scatter(vm, speed_average)
    ax.text(0.6, 4, f"Slope = {speed_constant:.2f}±{rel_err:.2f}%")
    plt.show()


if __name__ == '__main__':
    main()
