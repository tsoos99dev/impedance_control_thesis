clearvars;

syms J Bm Km R s

A = [0 1; 0 -(Bm/J+Km^2/(J*R))];
B = [0 0; Km/(J*R) 1/J];
C = [0 1];
D = 0;

motor = C/(s*eye(2) - A)*B + D;
