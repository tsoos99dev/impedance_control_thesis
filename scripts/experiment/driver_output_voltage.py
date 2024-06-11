import csv
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import ticker
from scipy import signal, stats

import matplotlib as mpl
from scipy import signal

mpl.use("tkagg")


MAX_SPEED_REFERENCE = 30000


def main():
    with open("driver_output_voltage.csv", mode="r", encoding='utf8') as file:
        data = file.read()

    data = data.splitlines()
    data = np.array([np.fromstring(line, sep=",", dtype=np.float32) for line in data])
    speed_ref = data[:, 0]
    voltage = data[:, 1]

    v_reg_info = stats.linregress(speed_ref, voltage)
    v_reg = v_reg_info.intercept + v_reg_info.slope * speed_ref
    alpha_s = v_reg_info.slope
    beta_s = v_reg_info.intercept

    V_max = alpha_s * MAX_SPEED_REFERENCE + beta_s
    V_max_err = np.sqrt(np.square(MAX_SPEED_REFERENCE*v_reg_info.stderr) + np.square(v_reg_info.intercept_stderr))

    fig, ax = plt.subplots()
    ax.set_xlabel("Speed reference [-]")
    ax.set_ylabel("Voltage [V]")
    ax.set_title("Driver output test")
    ax.grid(True)
    # ax.xaxis.set_major_locator(ticker.MultipleLocator(100))
    # ax.xaxis.set_minor_locator(ticker.MultipleLocator(20))
    # ax.yaxis.set_major_locator(ticker.MultipleLocator(1))
    # ax.yaxis.set_minor_locator(ticker.MultipleLocator(0.1))

    frac = speed_ref / MAX_SPEED_REFERENCE * 100

    ax.scatter(frac, voltage)
    ax.plot(frac, v_reg)
    plt.show()


if __name__ == '__main__':
    main()
