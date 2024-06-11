import csv
import logging
import math
import subprocess
import time

import serial
import numpy as np
from scipy import stats

from experiment.controller import FrameParser, Controller, CommandCode, ControllerError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


BAUD_RATE = 921600

MIN_MEASUREMENTS = 6
MAX_MEASUREMENTS = 10
MAX_FAILURES = 10

THRESHOLD = 0.95

SAFETY_FACTOR = 1.05
V_MAX = 11.835
V_LIMIT = V_MAX * 25/30 / SAFETY_FACTOR
GEAR_RATIO = 4.4

CPT = 880

LOOP_COUNTER_FREQUENCY = 84e6  # MHz
LOOP_COUNTER_PRESCALER = 6
LOOP_COUNTER_AUTO_RELOAD_REGISTER = 59999
LOOP_COUNTER_PERIOD = 1e3 / LOOP_COUNTER_FREQUENCY * (LOOP_COUNTER_PRESCALER + 1) * (LOOP_COUNTER_AUTO_RELOAD_REGISTER + 1)
LOOP_COUNTER_STEP = 1e3 / LOOP_COUNTER_FREQUENCY * (LOOP_COUNTER_PRESCALER + 1)


def main():
    completed_process = subprocess.run("ls /dev/tty.*", shell=True, stdout=subprocess.PIPE)
    if completed_process.returncode != 0:
        logger.error("Failed to list devices")
        exit(1)

    devices = completed_process.stdout.decode("utf-8").splitlines()
    for ind, device in enumerate(devices):
        print(f"{ind} - {device}")

    selected_device = ''
    while True:
        device_ind = input("Select a device: ")
        try:
            device_ind = int(device_ind)
            selected_device = devices[device_ind]
        except (ValueError, IndexError):
            print("Invalid selection")
            continue

        break

    measurement_params = np.loadtxt('measurement_params.csv', delimiter=',')

    open('sweep_output.csv', 'w').close()

    parser = FrameParser()
    with (serial.Serial(selected_device, BAUD_RATE, timeout=0.5) as interface):
        controller = Controller(parser, interface)

        for w0, be, Aimp, Bimp0, Bimp1, Bimp2, Cimp, Dimp0, Dimp1, Dimp2, settling_time, sim_error in measurement_params:
            settling_time_measurements = []
            failures = 0

            while len(settling_time_measurements) < MAX_MEASUREMENTS and failures < MAX_FAILURES:
                data = np.empty((1, 6))

                sim_time = 2.5 * settling_time
                step = np.min([math.pi / SAFETY_FACTOR, V_LIMIT / (GEAR_RATIO * Dimp0)])

                interface.read_all()
                try:
                    controller.set_parameter(CommandCode.SET_A, Aimp)
                    controller.set_parameter(CommandCode.SET_B0, Bimp0)
                    controller.set_parameter(CommandCode.SET_B1, Bimp1)
                    controller.set_parameter(CommandCode.SET_B2, Bimp2)
                    controller.set_parameter(CommandCode.SET_C, Cimp)
                    controller.set_parameter(CommandCode.SET_D0, Dimp0)
                    controller.set_parameter(CommandCode.SET_D1, Dimp1)
                    controller.set_parameter(CommandCode.SET_D2, Dimp2)
                    controller.set_parameter(CommandCode.SET_POSITION_REFERENCE, step)
                    controller.start()
                except ControllerError:
                    break

                start = time.time()
                for loop_count, loop_timer_count, counter, voltage, speed_ref, direction in controller.listen():
                    data = np.append(data, [[loop_count, loop_timer_count, counter, voltage, speed_ref, direction]], axis=0)
                    print(f"{loop_count}:{loop_timer_count} - {counter}, {voltage}, {speed_ref}, {direction}")

                    if time.time() - start > sim_time:
                        break

                try:
                    controller.stop()
                except ControllerError:
                    ...

                time.sleep(0.5)

                time_ms, angle, voltage, speed_ref, direction = process_data(data[2:])
                measured_settling_time = settling_time_num(time_ms, angle, THRESHOLD, 0, step)

                if measured_settling_time is np.nan or measured_settling_time == 0:
                    failures += 1
                    continue

                settling_time_measurements.append(measured_settling_time)
                failures = 0

            if len(settling_time_measurements) < MIN_MEASUREMENTS:
                settling_time_measurements = []

            settling_time_measurements = np.array(settling_time_measurements)
            average_settling_time = np.average(settling_time_measurements)
            std_err = stats.sem(settling_time_measurements)

            with open('sweep_output.csv', 'a') as file:
                writer = csv.writer(file)
                writer.writerow([w0, be, average_settling_time, std_err])


def process_data(data):
    loop_count = data[:, 0] - data[0, 0]
    loop_timer_count = data[:, 1]
    time_ms = (loop_count - 1) * LOOP_COUNTER_PERIOD + loop_timer_count * LOOP_COUNTER_STEP
    counter = np.unwrap(data[:, 2] - data[0, 2], period=65535)
    voltage = data[:, 3]
    speed_ref = data[:, 4]
    direction = data[:, 5]

    angle = np.abs(counter / CPT * (2 * np.pi))

    return time_ms, angle, voltage, speed_ref, direction


def settling_time_num(t_data, y_data, threshold, y_initial, y_final):
    err = np.abs(y_data-y_final)
    tol = (1-threshold)*abs(y_final - y_initial)
    seti = np.argwhere(err > tol).flatten()
    ns = len(t_data)

    # Pure gain
    if seti.size == 0:
        return 0

    seti = seti[-1]
    # Has not settled
    if seti + 1 == ns:
        return np.nan

    return t_data[seti]


if __name__ == '__main__':
    main()