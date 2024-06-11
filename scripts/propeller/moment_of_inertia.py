import numpy as np
from scipy import stats

# Oscillation period measurements for 30 periods [s]
PERIOD_COUNT = 30
periods = np.array([
    22.35,
    22.20,
    22.27,
    22.26,
    22.19
]) / PERIOD_COUNT


def main():
    period_avg = np.average(periods)
    period_stderr = stats.sem(periods)
    ci = stats.t.interval(0.95, len(periods) - 2, loc=period_avg, scale=period_stderr)
    print(ci)


if __name__ == '__main__':
    main()