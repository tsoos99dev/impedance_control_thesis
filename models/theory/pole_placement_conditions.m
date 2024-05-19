syms s t
syms Me Be Ke Bm Km J L R real
syms po Kr real

sympref('PolynomialDisplayStyle','ascend');

impedance_model = Ke/(s^2*Me + s*Be + Ke);

Aaa = 0;
Aab = [1 0]; 
Aba = [0; 0];
Abb = [-Bm/J Km/J; -Km/L -R/L];
A = [Aaa Aab; Aba Abb];
Bt = [0; 1/J; 0];
Bv = [0; 0; 1/L];
B = [Bt Bv];
C = [1 0 0];
D = [0 0];

pd = (Me*A^3 + (Be-Me*po)*A^2 + (Ke-Be*po)*A - Ke*po*eye(3))/Me;
Cm = [Bv A*Bv A^2*Bv];

K = [0 0 1]/Cm*pd;
Ka = K(1);
Kb = K(2:end);

pd = (Abb')^2-2*Abb'*po + eye(2)*po^2;
Cm = [Aab' Abb'*Aab'];
Kee = ([0 1]/Cm*pd)';

kc = (R + K(3))/Km - K(1)/Ke;
simplify(kc)

% vpa(subs(Kee, [L R J Km Bm Me Be Ke po], [0.2 1 0.01 0.01 0.1 1 4 16 -2]))

AA = [A-Bv*K Bv*Kb; zeros(2, 3) Abb-Kee*Aab];
BB = [Bv*Kr; zeros(2, 1)];
CC = eye(5);
DD = zeros(5, 1);

% pc = det(s*eye(3)-A+Bv*K)
% det(s*eye(2)-Abb+Kee*Aab)

s1 = simplify(CC/(s*eye(5)-AA)*BB + DD);
ds1 = s1(1, 1);
pretty(ds1)
% pretty(partfrac(ds1));
% pretty(simplify(ilaplace(ds1/s)));
% fplot(subs(ilaplace(ds1/s), [L R J Km Bm Me Be Ke po], [0.5 1 0.01 0.01 0.1 1 4 16 -8]), [0 5])
% hold on;
% fplot(subs(ilaplace(impedance_model/s), [L R J Km Bm Me Be Ke po], [0.5 1 0.01 0.01 0.1 1 4 16 -8]), [0 5])
% 
% pretty(ilaplace(Ke/s/(Me*s^2+Be*s+Ke)));
