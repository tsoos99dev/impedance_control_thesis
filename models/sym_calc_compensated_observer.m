syms Bm Km J L R s k1 k2 k3 ke1 ke2 kc real

Aaa = 0;
Aab = [1 0]; 
Aba = [0; 0];
Abb = [-Bm/J Km/J; -Km/L -R/L];
A_b = [Aab; Abb];
A = [Aaa Aab; Aba Abb];

Bat = 0;
Bbt = [1/J; 0];
Bt = [Bat; Bbt];
Bav = 0;
Bbv = [0; 1/L];
Bv = [Bav; Bbv];
B = [Bt Bv];
C = [1 0 0];
D = [0 0];

K = [k1 k2 k3];
Ke = [ke1 ke2]';

AA = [A-Bv*K Bv*(Kb-[0 1 0]*A_b*kc); zeros(2, 3) Ae-Ke*Aab];
BB = [Bt - Bv*kc; zeros(2, 1)];
CC = eye(5);
DD = zeros(5, 1);
O = s*eye(5) - AA;
subs(collect(CC/O*BB), s, 0)
