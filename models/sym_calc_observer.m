syms Bm Km J L R s k1 k2 k3 ke1 ke2 ke3 real

A = [0 1 0; 0 -Bm/J Km/J; 0 -Km/L -R/L];
B = [0 0; 1/J 0; 0 1/L];
Bt = B(:, 1);
Bv = B(:, 2);
C = [1 0 0];
D = [0 0];

K = [k1 k2 k3];
Ke = [ke1 ke2 ke3]';

AA = [A-Bv*K Bv*K; zeros(3) A-Ke*C];
BB = [Bv*K(1); zeros(3, 1)];
CC = eye(6);
DD = zeros(6, 1);
O = s*eye(6) - AA;
subs(collect(CC/O*BB), s, 0)

AA = [A-Bv*K Bv*K; zeros(3) A-Ke*C];
BB = [Bt; Bt];
CC = eye(6);
DD = zeros(6, 1);
O = s*eye(6) - AA;
collect(CC/O*BB)
subs(collect(CC/O*BB), s, 0)




