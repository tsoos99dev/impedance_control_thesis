syms s

M = 0.5;
td = 0.1;
p = 0.1;
d = 0.4;
Pm = p*M/td^2;
Dm = d*M/td;

pole(tf(1, [M Dm Pm]))

B1 = Pm + Dm/td;
B2 = Dm/td;

b1 = B1*td^2/M;
b2 = B2*td^2/M;

Aaa = 0;
Aab = 1; 
Aba = 0;
Abb = 0;
A_b = [Aab; Abb];
A = [Aaa Aab; Aba Abb];

Ba = 0;
Bb = 1/M;
B = [Ba; Bb];
C = [1 0];
D = 0;

motor = C/(s*eye(2) - A)*B + D;

K = [Pm Dm];
Ka = K(1);
Kb = K(2:end);

po = 0;
pd = (Abb'-po)^2;
Cm = Aab';
Ko = (1/Cm*pd)';

xi = [1; 0];
xai = xi(1);
xbi = xi(2:end);
nui = xbi - Ko*xai;

ei = 0;
nutildei = nui - ei;

Ahat = Abb - Ko*Aab;
Bhat = Ahat*Ko + Aba - Ko*Aaa;
Fhat = Bb - Ko*Ba;
Chat = [0; 1];
Dhat = [1; Ko];

Atilde = Ahat - Fhat*Kb;
Btilde_r = Fhat*Ka;
Btilde_y = Bhat - Fhat*(Ka + Kb*Ko);
Btilde = [Btilde_r Btilde_y];
Ctilde = -Kb;
Dtilde = [Ka -(Ka + Kb*Ko)];

% AA = [A-Bv*K Bv*Kb; zeros([2, 3]) Abb - Ko*Aab];
% BB = [Bv*Ka Bt - Bv*kc; zeros([2, 2])];
% CC = eye(5);
% DD = zeros([5, 2]);

controller = Ctilde/(s - Atilde)*Btilde + Dtilde;

% Ad = expm(A*t_d);
% Bd = A\(Ad-eye(3))*B;

Md = expm([A B; zeros([1, 3])]*td);
Ad = Md(1:2, 1:2);
Bd = Md(1:2, 3:end);
Cd = C;
Dd = D;

Md = expm([Atilde Btilde; zeros([2, 3])]*td);
Adtilde = Md(1);
Bdtilde = Md(1, 2:end);
Bdtilder = Bdtilde(:, 1);
Bdtildey = Bdtilde(:, 2);

Cdtilde = Ctilde;
Ddtilde = Dtilde;

% Adaa = Ad(1, 1);
% Adab = Ad(1, 2:end);
% Adba = Ad(2:end, 1);
% Adbb = Ad(2:end, 2:end);
% 
% Bda = Bd(1, :);
% Bdb = Bd(2:end, :);
% 
% AAdx = [-Bd*K Bd*Kb Ad zeros(3, 2)];
% 
% AAdexa = Adba + Adtilde*Ko - Ko*Adaa - Bdtildey;
% AAdexb = Adbb - Adtilde - Ko*Adab;
% AAdex1 = -(Bdb-Ko*Bda)*K;
% AAdee = Adtilde;
% AAdee1 = (Bdb-Ko*Bda)*Kb;
% AAde = [AAdex1 AAdee1 AAdexa AAdexb AAdee];
% 
% AAd = [
%     zeros([3, 5]) eye(3) zeros([3, 2])
%     zeros([2, 5]) zeros([2,3]) eye(2)
%     AAdx
%     AAde
% ];
% 
