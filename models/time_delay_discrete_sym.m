syms s 
syms Me Be Ke J Km Bm L R t_d real
syms po real

Aimp = [0 1; -Ke/Me -Be/Me];
Bimp = [0 0; Ke/Me 1/Me];
Cimp = [1 0];
Dimp = zeros(2);

impedance_model = Cimp/(s*eye(2) - Aimp)*Bimp + Dimp;

Aaa = 0;
Aab = [1 0]; 
Aba = [0; 0];
Abb = [-Bm/J Km/J; -Km/L -R/L];
A_b = [Aab; Abb];
A = [Aaa Aab; Aba Abb];

Bta = 0;
Btb = [1/J; 0];
Bt = [Bta; Btb];
Bva = 0;
Bvb = [0; 1/L];
Bv = [Bva; Bvb];
B = [Bv Bt];
C = [1 0 0];
D = [0 0];

motor = C/(s*eye(3) - A)*B + D;

pd = (Me*A^3 + (Be-Me*po)*A^2 + (Ke-Be*po)*A - Ke*po*eye(3))/Me;
Cm = [Bv A*Bv A^2*Bv];

K = [0 0 1]/Cm*pd;
Ka = K(1);
Kb = K(2:end);
kc = (R+K(3))/Km-Ka/Ke;

pd = (Abb')^2-2*Abb'*po + eye(2)*po^2;
Cm = [Aab' Abb'*Aab'];
Ko = ([0 1]/Cm*pd)';

Ahat = Abb - Ko*Aab;
Bhat = Ahat*Ko + Aba - Ko*Aaa;
Fhat_tau = Btb - Ko*Bta;
Fhat_v = Bvb - Ko*Bva;
Chat = [zeros([1, 2]); eye(2)];
Dhat = [1; Ko];

Atilde = Ahat - Fhat_v*Kb;
Btilde_r = Fhat_v*Ka;
Btilde_y = Bhat - Fhat_v*(Ka + Kb*Ko);
Btilde_tau = Fhat_tau - Fhat_v*kc;
Btilde = [Btilde_r Btilde_tau Btilde_y];
Ctilde = -Kb;
Dtilde = [Ka -kc -(Ka + Kb*Ko)];

AA = [A-Bv*K Bv*Kb; zeros([2, 3]) Abb - Ko*Aab];
BB = [Bv*Ka Bt - Bv*kc; zeros([2, 2])];
CC = eye(5);
DD = zeros([5, 2]);

controller = Ctilde/(s*eye(2) - Atilde)*Btilde + Dtilde;

Ad = simplify(expm(Atilde*t_d));
Bd = simplify(Atilde\(Ad-eye(2))*Btilde);
Cd = Ctilde;
Dd = Dtilde;

delay = exp(-s*t_d);