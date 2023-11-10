kc = 1;
km = 4;
wn = 150;
z = 0.05;
T = 1/50;

A = -[0 1; -(1+kc/km)*wn^2 -2*z*wn];
Ad = -[0 0; -kc/km*wn^2 0];

opts = optimoptions("fsolve", "Algorithm","levenberg-marquardt");
Q = fsolve(@(Q) commutator(Q, A, Ad, T, kc, km, wn), [1 1; 1 1], opts);
% commutator(Q, A, Ad, T, kc, km, wn)

D = [lambertw(0, Q(1, 2)*kc/km*wn^2*T) 0; 0 0];
V = [0 -Q(1, 2)/Q(1, 1); 1 1];
W = V*D/V;
S = 1/T*W-A
Seig = vpa(eig(S))

vpa(eig([0 1; -33083 -0.24]))

function F = commutator(Q, A, Ad, T, kc, km, wn)
    V = [0 -Q(1, 2)/Q(1, 1); 1 1];
    D = [lambertw(0, Q(1, 2)*kc/km*wn^2*T) 0; 0 0];
    W = V*D/V;
    F = W*expm(W-A*T)+Ad*T;
end