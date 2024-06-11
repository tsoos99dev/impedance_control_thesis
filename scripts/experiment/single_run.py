import csv
import logging
import math
import subprocess
import time

import serial
import numpy as np

from experiment.controller import FrameParser, Controller, CommandCode

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


BAUD_RATE = 921600
SIM_TIME = 2
POSITION_REFERENCE = math.pi / 3


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

    with open('model_params.csv', 'r') as model_params_file:
        lines = model_params_file.readlines()

    Aimp = float(lines[0])
    Bimp = [float(value) for value in lines[1].split(',')]
    Cimp = float(lines[2])
    Dimp = [float(value) for value in lines[3].split(',')]

    parser = FrameParser()
    with serial.Serial(selected_device, BAUD_RATE, timeout=0.5) as interface:
        controller = Controller(parser, interface)

        data = []

        controller.set_parameter(CommandCode.SET_A, Aimp)
        controller.set_parameter(CommandCode.SET_B0, Bimp[0])
        controller.set_parameter(CommandCode.SET_B1, Bimp[1])
        controller.set_parameter(CommandCode.SET_B2, Bimp[2])
        controller.set_parameter(CommandCode.SET_C, Cimp)
        controller.set_parameter(CommandCode.SET_D0, Dimp[0])
        controller.set_parameter(CommandCode.SET_D1, Dimp[1])
        controller.set_parameter(CommandCode.SET_D2, Dimp[2])
        controller.set_parameter(CommandCode.SET_POSITION_REFERENCE, POSITION_REFERENCE)
        controller.start()

        start = time.time()
        for loop_count, loop_timer_count, counter, voltage, speed_ref, direction in controller.listen():
            data.append((loop_count, loop_timer_count, counter, voltage, speed_ref, direction))
            print(f"{loop_count}:{loop_timer_count} - {counter}, {voltage}, {speed_ref}, {direction}")
            if time.time() - start > SIM_TIME:
                break

        try:
            controller.stop()
        except Exception:
            ...

    with open('controller_test1.csv', 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(data)


if __name__ == '__main__':
    main()