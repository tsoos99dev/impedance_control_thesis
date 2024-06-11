import csv
import matplotlib.pyplot as plt
import numpy as np
from scipy import signal

import matplotlib as mpl

mpl.use("tkagg")

CPT = 880


def main():
    with open("motor_speed.txt", mode="r", encoding='utf8') as file:
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

    window = signal.butter(4, 20, fs=fs, output='sos')

    dy = np.gradient(y, dt)
    dy = dy / CPT * 60
    dy_filt = signal.sosfiltfilt(window, dy)

    fig, ax = plt.subplots()
    ax.set_xlabel("Time [ms]")
    ax.set_ylabel("Position [rad]")
    ax.set_title("Step response")
    ax.grid(True)
    ax.plot(x, y)

    with open("controller_test1_out.csv", mode="w", encoding='utf8') as file:
        writer = csv.writer(file, delimiter=',', lineterminator='\n')
        writer.writerows(zip(x, y))

    # fig, ax = plt.subplots()
    # ax.set_xlabel("Time [ms]")
    # ax.set_ylabel("Speed [rpm]")
    # ax.set_title("Motor driver test 1")
    # ax.grid(True)
    # ax.plot(x, dy)
    # ax.plot(x, dy_filt)

    # fig, ax = plt.subplots()
    # ax.set_xlabel("Frequency [Hz]")
    # ax.set_ylabel("PSD [-]")
    # ax.set_title("Motor encoder test 1")
    # ax.grid(True)
    # ax.psd(dy, 512, fs)
    plt.show()


if __name__ == '__main__':
    main()
