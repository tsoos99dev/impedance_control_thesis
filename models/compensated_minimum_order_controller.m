syms s

% Desired impedance model
Me = 1;
Be = 4;
Ke = 10;

impedance_model = tf(Ke, [Me Be Ke]);
Pe = pole(impedance_model)';

% Motor parameters
% This has the biggest effect on how distorted 
% the torque response is.
J = 0.75;

Km = 0.01;
Bm = 0.1;
L = 0.5;
R = 1;

% Motor model
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

% New poles
P = [Pe -6];
Po = -7 * [1 1.1];

motor = ss(A, B, C, D, 'InputName', {'t', 'V'}, 'OutputName', 'a', 'StateName', {'a', 'w', 'i'});
% step(motor)
% ss2tf(A, B, C, D, 1)
% ss2tf(A, B, C, D, 2)

K = place(A, Bv, P);
Ka = K(1);
Kb = K(2:end);

Ae = Abb - Bbt*[0 1 0]*A_b;
Ko = place(Ae', Aab', Po)';

% Guarantees the correct torque response steady state value.
kc = (R+K(3))/Km-Ka/Ke;

% Observer-controller dynamics
AA = [A-Bv*K Bv*(Kb-[0 1 0]*A_b*kc); zeros(2, 3) Ae-Ko*Aab];
BB = [Bv*Ka; zeros(2, 1)];
CC = eye(5);
DD = zeros(5, 1);
c1 = ss(AA, BB, CC, DD, 'InputName', {'a0'}, 'OutputName', {'a', 'w', 'i', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ew', 'ei'});
pc1 = pole(c1);
% O = s*eye(6) - AA;
% vpa(subs(collect(CC/O*BB), s, 0))
% initial(c1(1, 1), [1; 0; 0; 0.5; 0; 0]);
% [num, den] = ss2tf(AA, BB, CC, DD, 1)

% ss2tf(AA, BB, CC, DD)

% Disturbance response
AA = [A-Bv*K Bv*(Kb-[0 1 0]*A_b*kc); zeros(2, 3) Ae-Ko*Aab];
BB = [Bt - Bv*kc; zeros(2, 1)];
CC = eye(5);
DD = zeros(5, 1);
c2 = ss(AA, BB, CC, DD, 'InputName', {'a0'}, 'OutputName', {'a', 'w', 'i', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ew', 'ei'});
% O = s*eye(6) - AA;
% vpa(subs(collect(CC/O*BB), s, 0))
% tzero(c2(1))

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
pzmap(impedance_model)
xlim(xl);
subplot(3, 2, 4)
pzmap(c1(1))
xlim(xl);
subplot(3, 2, 6)
pzmap(c2(1))
xlim(xl);

pc1
