import csv
import logging
import numpy as np

from sigfig import round

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def main():
    data = np.loadtxt('sweep_output1.csv', delimiter=',')

    params = np.round(data[:, 0:2], decimals=2)
    settling_time = data[:, 2]
    error = data[:, 3]

    output = [
        [
            f"{ke:.2f}",
            f"{be:.2f}",
            *(round(t, uncertainty=e, sep=list, type=str) if not np.isnan(t) and not np.isnan(e) else 2*["-"])
        ]
        for ke, be, t, e in zip(*params.T, settling_time, error)
    ]
    with open('sweep_output1_formatted.csv', 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(output)


if __name__ == '__main__':
    main()
