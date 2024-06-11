import csv
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import ticker
from scipy import signal, stats

import matplotlib as mpl
from scipy import signal

mpl.use("tkagg")


MAX_SPEED_REFERENCE = 30000


def least_squares_origin(x, y):
    n = len(x)

    sx = np.sum(np.square(x))
    sxy = np.sum(x*y)

    B = sxy / sx

    df = n - 1
    dy = np.sqrt((np.sum(np.square(y-B*x)))/df)
    dB = dy / np.sqrt(sx)
    return B, dB, dy


def main():
    with open("stall_current.csv", mode="r", encoding='utf8') as file:
        data = file.read()

    data = data.splitlines()
    data = np.array([np.fromstring(line, sep=",", dtype=np.float32) for line in data])
    voltage = np.asarray(data[:, 0])
    current = np.asarray(data[:, 1])

    B, dB, dI = least_squares_origin(voltage, current)
    R = 1 / B
    dR = dB / np.square(B)

    Ra = voltage / current

    dVf = 0.01/voltage
    dIf = 0.01/current
    dRa = Ra * np.sqrt(np.square(dVf) + np.square(dIf))
    wRa = 1/np.square(dRa)

    Rm = np.mean(Ra)
    dRm = stats.sem(Ra)

    Rw = np.average(Ra, weights=wRa)
    dRw = 1/np.sqrt(np.sum(wRa))

    print(R, dR)

    voltage_ext = np.linspace(0, min(voltage))

    fig, ax = plt.subplots()
    ax.set_xlabel("Current [A]")
    ax.set_ylabel("Voltage [V]")
    ax.set_title("Rotor resistance test")
    ax.grid(True)
    # ax.xaxis.set_major_locator(ticker.MultipleLocator(100))
    # ax.xaxis.set_minor_locator(ticker.MultipleLocator(20))
    # ax.yaxis.set_major_locator(ticker.MultipleLocator(1))
    # ax.yaxis.set_minor_locator(ticker.MultipleLocator(0.1))
    ax.set_xlim([0, 1.1*max(voltage)])
    ax.set_ylim([0, 1.1*max(current)])

    ax.errorbar(voltage, current, yerr=dI, capsize=2, fmt='o')
    ax.plot(voltage, B*voltage)
    ax.plot(voltage_ext, B*voltage_ext, '--')
    plt.show()


if __name__ == '__main__':
    main()
