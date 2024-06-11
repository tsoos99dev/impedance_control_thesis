import csv
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import ticker

import matplotlib as mpl
from scipy import signal

mpl.use("tkagg")

CPT = 880

LOOP_COUNTER_FREQUENCY = 84e6  # MHz
LOOP_COUNTER_PRESCALER = 6
LOOP_COUNTER_AUTO_RELOAD_REGISTER = 59999
LOOP_COUNTER_PERIOD = 1e3 / LOOP_COUNTER_FREQUENCY * (LOOP_COUNTER_PRESCALER + 1) * (LOOP_COUNTER_AUTO_RELOAD_REGISTER + 1)
LOOP_COUNTER_STEP = 1e3 / LOOP_COUNTER_FREQUENCY * (LOOP_COUNTER_PRESCALER + 1)


def main():
    with open("controller_test1.csv", mode="r", encoding='utf8') as file:
        data = file.read()

    data = data.splitlines()
    data = data[1:-1]
    data = np.array([np.fromstring(line, sep=",", dtype=np.float32) for line in data])
    # _, idx = np.unique(data[:, 0], return_index=True)
    # data = data[idx]
    loop_count = data[:, 0] - data[0, 0]
    loop_timer_count = data[:, 1]
    time_ms = (loop_count - 1) * LOOP_COUNTER_PERIOD + loop_timer_count * LOOP_COUNTER_STEP
    counter = np.unwrap(data[:, 2] - data[0, 2], period=65535)
    voltage = data[:, 3]
    speed_ref = data[:, 4]
    direction = data[:, 5]

    angle = np.abs(counter / CPT * (2 * np.pi))

    samples = len(time_ms)
    dt = (time_ms[-1] - time_ms[0]) / samples * 1e-3  # s
    fs = float(1 / dt)

    window = signal.butter(4, 10, fs=fs, output='sos')

    dy = np.gradient(4.4*angle, dt)
    dy_filt = signal.sosfiltfilt(window, dy)

    fig, ax = plt.subplots()
    ax.set_xlabel("Time [ms]")
    ax.set_ylabel("Speed [rad]")
    ax.set_title("Step response")
    ax.grid(True)
    ax.xaxis.set_major_locator(ticker.MultipleLocator(100))
    ax.xaxis.set_minor_locator(ticker.MultipleLocator(20))
    ax.yaxis.set_major_locator(ticker.MultipleLocator(1))
    ax.yaxis.set_minor_locator(ticker.MultipleLocator(0.1))

    # K0 = 1.7665
    # ax.plot(time_ms, voltage + K0*4.4*angle)
    # ax.plot(time_ms, dy_filt)
    ax.plot(time_ms, angle)
    # ax.plot(time_ms, direction)

    with open("controller_test1_angle_out.csv", mode="w", encoding='utf8') as file:
        writer = csv.writer(file, delimiter=',', lineterminator='\n')
        writer.writerows(zip(time_ms, angle))

    with open("controller_test1_voltage_out.csv", mode="w", encoding='utf8') as file:
        writer = csv.writer(file, delimiter=',', lineterminator='\n')
        writer.writerows(zip(time_ms + LOOP_COUNTER_PERIOD, voltage))

    plt.show()


if __name__ == '__main__':
    main()
