import numpy as np
from scipy import signal


def smooth_derivative(x, fs: float, cutoff: float = 20):
    window = signal.butter(4, cutoff, fs=fs, output='sos')

    dx = np.gradient(x, 1/fs)
    dx = signal.sosfiltfilt(window, dx)
    return dx
