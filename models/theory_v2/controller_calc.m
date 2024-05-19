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

motor_model = ss(A, B, C, D);
Pm = pole(motor_model)';

% Pole placement
Pe_delta = (Me*A^2 + Be*A + Ke*eye(2))/Me;
Co = [Bv A*Bv];
K = [0 1]/Co*Pe_delta;
Ka = K(1);
Kb = K(2:end);

Po = 1.5*min(real(Pm));
Po_delta = Abb' - Po;
CoK = Aab';
Ko = (1/CoK * Po_delta)';

kc = (1-J/Me)*R/Km;

% Combined model
AA = [A-Bv*K Bv*Kb; zeros([1, 2]) Abb - Ko*Aab];
BB = [Bv*Ka Bt - Bv*kc; zeros([1, 2])];
CC = eye(3);
DD = zeros([3, 2]);

% Controller
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

% Digital controller
Adtilde = expm(Atilde*t_d);
Bdtilde = Atilde\(Adtilde-1)*Btilde;
Bdtilder = Bdtilde(:, 1);
Bdtildet = Bdtilde(:, 2);
Bdtildey = Bdtilde(:, 3);

Cdtilde = Ctilde;
Ddtilde = Dtilde;

% Digital motor model
Md = expm([A Bv; zeros([1, 3])]*t_d);
Ad = Md(1:2, 1:2);
Bd = Md(1:2, 3:end);
Cd = C;
Dd = D;

% Combined digital model
Adaa = Ad(1, 1);
Adab = Ad(1, 2:end);
Adba = Ad(2:end, 1);
Adbb = Ad(2:end, 2:end);

Bda = Bd(1, :);
Bdb = Bd(2:end, :);

AAdx = [-Bd*K Bd*Kb Ad zeros(2, 1)];

AAdexa = Adba + Adtilde*Ko - Ko*Adaa - Bdtildey;
AAdexb = Adbb - Adtilde - Ko*Adab;
AAdex1 = -(Bdb-Ko*Bda)*K;
AAdee = Adtilde;
AAdee1 = (Bdb-Ko*Bda)*Kb;
AAde = [AAdex1 AAdee1 AAdexa AAdexb AAdee];


AAd = [
    zeros(3, 3) eye(3)
    AAdx
    AAde
];