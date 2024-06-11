import csv
import logging
import math
import subprocess
import time

import serial

from experiment.controller import FrameParser, Controller, CommandCode

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


BAUD_RATE = 921600


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

    sim_time = 95
    data = []
    with serial.Serial(selected_device, BAUD_RATE, timeout=0.5) as interface:
        parser = FrameParser()
        controller = Controller(parser, interface)

        controller.start()

        start = time.time()
        for loop_count, loop_timer_count, counter, voltage, speed_ref, direction in controller.listen():
            data.append((loop_count, loop_timer_count, counter, voltage, speed_ref, direction))
            print(f"{loop_count}:{loop_timer_count} - {counter}, {voltage}, {speed_ref}, {direction}")
            if time.time() - start > sim_time:
                break

        controller.stop()

    with open('controller_reference_measurement.csv', 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(data)


if __name__ == '__main__':
    main()