syms Bm Km J L R s k1 k2 k3 ke1 ke2 ke3 real
syms s

A = [0 1 0; 0 -Bm/J Km/J; 0 -Km/L -R/L];
B = [0 0; 1/J 0; 0 1/L];
Bt = B(:, 1);
Bv = B(:, 2);
C = [1 0 0];
D = [0 0];

det(s*eye(3) - A)
tf = collect(C/(s*eye(3) - A)*B, s)




