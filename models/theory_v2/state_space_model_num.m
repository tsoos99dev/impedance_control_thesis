clearvars;

J = 6.34e-7;
Bm = 2.7e-7;
Km = 15.4e-3;
R = 5.61;
V = 12;

A = [0 1; 0 -(Bm/J+Km^2/(J*R))];
B = [0 0; Km/(J*R) 1/J];
C = [0 1];
D = 0;

vmax = Km*V/(R*Bm+Km^2);

motor = ss(A, B, C, D);

opts = stepDataOptions('StepAmplitude',V);
step(motor(1), opts);
