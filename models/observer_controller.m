syms s

% Desired impedance model
Me = 1;
Be = 4;
Ke = 16;

impedance_model = tf(Ke, [Me Be Ke]);
Pe = pole(impedance_model)';

% Motor parameters
J = 0.01;
Km = 0.01;
Bm = 0.1;
L = 0.5;
R = 1;

% Motor model
A = [0 1 0; 0 -Bm/J Km/J; 0 -Km/L -R/L];
B = [0 0; 1/J 0; 0 1/L];
Bt = B(:, 1);
Bv = B(:, 2);
C = [1 0 0];
D = [0 0];

% New poles
P = [Pe -9];
Po = -10 * [1.1 1.2 1.3];

motor = ss(A, B, C, D, 'InputName', {'t', 'V'}, 'OutputName', 'a', 'StateName', {'a', 'w', 'i'});
% step(motor)
ss2tf(A, B, C, D, 1)
ss2tf(A, B, C, D, 2)

K = place(A, Bv, P);
Ke = place(A', C', Po)';

% Observer-controller dynamics
AA = [A-Bv*K Bv*K; zeros(3) A-Ke*C];
BB = [Bv*K(1); zeros(3, 1)];
CC = eye(6);
DD = zeros(6, 1);
c1 = ss(AA, BB, CC, DD, 'InputName', {'a0'}, 'OutputName', {'a', 'w', 'i', 'ea', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ea', 'ew', 'ei'});
pc1 = pole(c1);
O = s*eye(6) - AA;
vpa(subs(collect(CC/O*BB), s, 0))
% initial(c1(1, 1), [1; 0; 0; 0.5; 0; 0]);
% [num, den] = ss2tf(AA, BB, CC, DD, 1)

% ss2tf(AA, BB, CC, DD)

% Disturbance response
AA = [A-Bv*K Bv*K; zeros(3) A-Ke*C];
BB = [Bt; Bt];
CC = eye(6);
DD = zeros(6, 1);
c2 = ss(AA, BB, CC, DD, 'InputName', {'t'}, 'OutputName', {'a', 'w', 'i', 'ea', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ea', 'ew', 'ei'});
O = s*eye(6) - AA;
vpa(subs(collect(CC/O*BB), s, 0))
tzero(c2(1))

xl = [0, 5];
subplot(3, 2, 1)
step(impedance_model)
xlim(xl);
subplot(3, 2, 3)
step(c1(1))
xlim(xl);
subplot(3, 2, 5)
step(c2(1))
xlim(xl);

xl = [-30, 1];
subplot(3, 2, 2)
pzplot(impedance_model)
xlim(xl);
subplot(3, 2, 4)
pzplot(c1)
xlim(xl);
subplot(3, 2, 6)
pzplot(c2(1))
xlim(xl);

poles(K/(s*eye(3) - A + Ke*C + Bv*K)*Ke)
