import csv
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import ticker
from scipy import signal, stats

import matplotlib as mpl
from scipy import signal

mpl.use("tkagg")

CPT = 880

LOOP_COUNTER_FREQUENCY = 84e6  # MHz
LOOP_COUNTER_PRESCALER = 6
LOOP_COUNTER_AUTO_RELOAD_REGISTER = 59999
LOOP_COUNTER_PERIOD = 1e3 / LOOP_COUNTER_FREQUENCY * (LOOP_COUNTER_PRESCALER + 1) * (LOOP_COUNTER_AUTO_RELOAD_REGISTER + 1)
LOOP_COUNTER_STEP = 1e3 / LOOP_COUNTER_FREQUENCY * (LOOP_COUNTER_PRESCALER + 1)

MAX_VOLTAGE = 11.835
MAX_SPEED_REFERENCE = 30000

GEAR_RATIO = 4.4
R = 8.7
Km = 15.4e-3


def main():
    with open("controller_reference_measurement.csv", mode="r", encoding='utf8') as file:
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

    angle = -counter / CPT * (2 * np.pi)

    samples = len(time_ms)
    dt = (time_ms[-1] - time_ms[0]) / samples * 1e-3  # s
    fs = float(1 / dt)

    window = signal.butter(4, 10, fs=fs, output='sos')

    dy = np.gradient(-counter, dt)
    dy = dy / CPT * 60
    dy_filt = signal.sosfiltfilt(window, dy)

    tmax_ind = np.where(time_ms > 88e3)[0][0]
    measurement_offsets = np.linspace(0, tmax_ind, 45, dtype=int)
    measurement_window_width = measurement_offsets[1] - measurement_offsets[0]
    measurement_offsets += measurement_window_width // 2
    speed_reference_values = np.array([speed_ref[start] for start in measurement_offsets])
    speed_measurements = np.array([np.average(dy_filt[start:start+measurement_window_width // 2]) for start in measurement_offsets])

    applied_voltage = speed_reference_values * MAX_VOLTAGE / MAX_SPEED_REFERENCE
    speed_rotor = GEAR_RATIO*2*np.pi/60*speed_measurements

    with open("speed_profile_out.csv", "w") as file:
        writer = csv.writer(file)
        writer.writerows(zip(np.round(applied_voltage, 2), np.round(speed_rotor, 1)))

    speed_reg_info = stats.linregress(applied_voltage, speed_rotor)
    speed_reg = speed_reg_info.intercept + speed_reg_info.slope * speed_reference_values
    alpha_s = speed_reg_info.slope
    beta_s = speed_reg_info.intercept
    B_fit = Km/R*(1/alpha_s - Km)
    B_fit_err = Km / (R*np.power(alpha_s, 2)) * speed_reg_info.stderr
    tau_fit = -Km/R*beta_s/alpha_s
    V_comp = -beta_s / alpha_s
    V_comp_err = np.sqrt(np.power(beta_s / np.power(alpha_s, 2) * speed_reg_info.stderr, 2) + np.power(speed_reg_info.intercept_stderr / alpha_s, 2))
    speed_ref_comp = V_comp * MAX_SPEED_REFERENCE / MAX_VOLTAGE
    speed_ref_comp_err = V_comp_err * MAX_SPEED_REFERENCE / MAX_VOLTAGE

    fig, ax = plt.subplots()
    ax.set_xlabel("Time [ms]")
    ax.set_ylabel("Speed [rad]")
    ax.set_title("Step response")
    ax.grid(True)
    # ax.xaxis.set_major_locator(ticker.MultipleLocator(100))
    # ax.xaxis.set_minor_locator(ticker.MultipleLocator(20))
    # ax.yaxis.set_major_locator(ticker.MultipleLocator(1))
    # ax.yaxis.set_minor_locator(ticker.MultipleLocator(0.1))

    # ax.plot(time_ms, dy_filt)
    # ax.vlines(time_ms[measurement_offsets], 0, np.max(dy_filt), linestyles='dashed')

    ax.scatter(applied_voltage, speed_rotor)
    plt.show()


if __name__ == '__main__':
    main()
