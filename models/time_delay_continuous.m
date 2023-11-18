syms s

% Desired impedance model
Me = 0.015;
Be = 0.06;
Ke = Me*5.6;
% Be = 0.075;
% Ke = -0.15;

Aimp = [0 1; -Ke/Me -Be/Me];
Bimp = [0 0; Ke/Me 1/Me];
Cimp = eye(2);
Dimp = zeros(2);

impedance_model = tf(Ke, [Me Be Ke]);
Pe = pole(impedance_model)';

% Motor parameters
J = 0.01;
Km = 0.01;
Bm = 0.1;
L = 0.2;
R = 1;

% Motor model
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

% New poles
P = [Pe -15];
Po = -15 * [1 1];

% motor = ss(A, B, C, D, 'InputName', {'voltage', 'torque'}, 'OutputName', 'angle', 'StateName', {'angle', 'angular_velocity', 'current'});

K = acker(A, Bv, P);
Ka = K(1);
Kb = K(2:end);

Ko = acker(Abb', Aab', Po)';

xi = [0; 0; 0];
xai = xi(1);
xbi = xi(2:end);
nui = xbi - Ko*xai;

ei = [0; 0];
nutildei = nui - ei;

% Guarantees the correct torque response steady state value.
kc = (R+K(3))/Km-Ka/Ke;

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

% symp_sys = ss(AA, BB, CC, DD, 'InputName', {'voltage', 'torque'}, 'OutputName', 'angle');
% [num, den] = ss2tf(AA, BB, CC, DD, 1)

% controller = ss(Atilde, Btilde, -Ctilde, -Dtilde, 'InputName', {'angle_ref', 'angle', 'torque'}, 'OutputName', 'voltage');
% open_loop = series(controller, motor, 1, 1);
% closed_loop = feedback(open_loop, 1, 2, 1);

% [num, den] = ss2tf(closed_loop.A, closed_loop.B, closed_loop.C, closed_loop.D, 1)

% pole(closed_loop(1))

% hold on;
% step(impedance_model)
% step(closed_loop(1), [0 5])
% step(symp_sys(1, 1))