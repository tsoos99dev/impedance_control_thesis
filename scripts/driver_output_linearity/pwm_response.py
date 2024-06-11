import csv

import matplotlib.pyplot as plt
import numpy as np
from scipy import signal, stats

import matplotlib as mpl
from scipy.stats import linregress, t

from const import COUNTS_PER_TURN
from filter import smooth_derivative

mpl.use("tkagg")


def main():
    with open("motor_pwm_response20_2.txt", mode="r", encoding='utf8') as file:
        data = file.read()

    data = data.splitlines()
    data = data[1:-1]
    data = np.array([np.fromstring(line, sep=",", dtype=np.float32) for line in data])
    _, idx = np.unique(data[:, 0], return_index=True)
    data = data[idx]
    xp = data[:, 0] - data[0, 0]
    yp = np.unwrap(data[:, 1] - data[0, 1], period=65535)

    samples = len(xp)
    x = np.linspace(xp[0], xp[-1], samples)
    y = np.interp(x, xp, yp)

    dt = (x[-1] - x[0]) / samples * 1e-3  # s
    fs = float(1 / dt)

    dy = smooth_derivative(y, fs)
    dy = dy / COUNTS_PER_TURN * 60

    counters = 10000*np.arange(0, 41)
    indices = [np.where(x > counter)[0][0] for counter in counters]
    measurement_indices = np.int64(indices)+1000

    timestamps = x[measurement_indices]
    # 10 second average
    speed_average = [
        np.average(dy[ind:ind + 7000])
        for ind in measurement_indices
    ]

    duty = np.arange(0, 101, 2.5)

    with open('motor_pwm_response20_2_out.csv', 'w', encoding='utf8') as file:
        writer = csv.writer(file)
        writer.writerows(zip(duty, speed_average))

    fig, ax = plt.subplots()
    ax.set_xlabel("Duty [%]")
    ax.set_ylabel("Speed [rpm]")
    ax.set_title("Motor PWM response")
    ax.grid(True)
    # ax.plot(duty, speed_average)
    ax.scatter(duty, speed_average)
    # ax.text(50, 4, f"Slope = {slope:.2f}±{rel_err:.2f}%")
    plt.show()


if __name__ == '__main__':
    main()
