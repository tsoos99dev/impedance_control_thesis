clearvars;

syms s;

% Motor parameters
syms J Bm Km R V;

% Impedance parameters
syms Me Be Ke;

% Impedance model
Aimp = [0 1; -Ke/Me -Be/Me];
Bimp = [0 0; Ke/Me 1/Me];
Cimp = eye(2);
Dimp = zeros(2);

% Motor model
Aaa = 0;
Aab = 1; 
Aba = 0;
Abb = -(Bm/J+Km^2/(J*R));
A_b = [Aab; Abb];
A = [Aaa Aab; Aba Abb];

Bta = 0;
Btb = 1/J;
Bt = [Bta; Btb];
Bva = 0;
Bvb = Km/(J*R);
Bv = [Bva; Bvb];
B = [Bv Bt];
C = [1 0];
D = [0 0];

% Pole placement
syms Po 

Pe_delta = (Me*A^2 + Be*A + Ke*eye(2))/Me;
Co = [Bv A*Bv];
K = [0 1]/Co*Pe_delta;
Ka = K(1);
Kb = K(2:end);

Po_delta = Abb' - Po;
CoK = Aab';
Ko = (1/CoK * Po_delta)';

kc = (1-J/Me)*R/Km;


% Combined model
AA = [A-Bv*K Bv*Kb; zeros([1, 2]) Abb - Ko*Aab];
BB = [Bv*Ka Bt - Bv*kc; zeros([1, 2])];
CC = eye(3);
DD = zeros([3, 2]);

tf = CC/(s*eye(3) - AA)*BB+DD;

fv = simplify(tf(1, :));
