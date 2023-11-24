syms s 
syms Me Be Ke J Km Bm L R t_d real
syms po real

sympref('PolynomialDisplayStyle','ascend');

% Desired impedance model
Me0 = 0.015;
Be0 = 0.06;
Ke0 = 0.24;
po0 = -15;

Aimp = [0 1; -Ke/Me -Be/Me];
Bimp = [0 0; Ke/Me 1/Me];
Cimp = [1 0];
Dimp = zeros(2);

impedance_model = Cimp/(s*eye(2) - Aimp)*Bimp + Dimp;

% Motor parameters
J0 = 0.01;
Km0 = 0.01;
Bm0 = 0.1;
L0 = 0.2;
R0 = 1;

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

sub = @(s) subs(s, [J Km Bm L R po], [J0 Km0 Bm0 L0 R0 po0]);

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
closed_loop = CC/(s*eye(5) - AA)*BB + DD;
% pretty(simplify((controller(1, 1))))
% pretty(simplify(closed_loop(1, 2)))

delay = exp(-s*t_d);
yC0 = 1-motor(1, 1)*controller(1, 3)*delay;
yCR = motor(1, 1)*controller(1, 1)*delay;
yCtau = motor(1, 2) + motor(1, 1)*controller(1, 2)*delay;

% y = 1/yC0*(yCR*ri + yCtau*taui);
[mn, md] = numden(motor(1, 1));
[nn, nd] = numden(controller(1, 3));

y = nd*md - nn*mn*delay;
% y = sub(y);
% pc = collect(y, s);
% coeff = fliplr(coeffs(pc, s));
% coeff = simplify(expand(coeff/coeff(1)))
% collect(expand(coeff(2)))
% collect(expand(coeff(3)))
% ca = coeffs(expand(coeff(4)), exp(-s*t_d));
% ca1 = simplify(coeffs(ca(1), [Be Ke]))
% latex(expand(ca1(1)))
% latex(expand(ca1(2)))
% latex(expand(ca1(3)))
% ca1 = simplify(coeffs(ca(2), [Be Ke]));
% latex(expand(ca1(1)))
% latex(expand(ca1(2)))
% latex(expand(ca1(3)))
% ca = coeffs(expand(coeff(5)), exp(-s*t_d));
% ca1 = simplify(coeffs(ca(1), [Be Ke]));
% latex(expand(ca1(1)))
% latex(expand(ca1(2)))
% latex(expand(ca1(3)))
% ca1 = simplify(coeffs(ca(2), [Be Ke]));
% latex(expand(ca1(1)))
% latex(expand(ca1(2)))
% latex(expand(ca1(3)))
% ca = coeffs(expand(coeff(6)), exp(-s*t_d));
% latex(expand(ca))

% sub = @(s) subs(s, [Me Be Ke J Km Bm L R po t_d], [1 5 10 J0 Km0 Bm0 L0 R0 po0 0]);
% vpasolve(sub(pc) == 0)

syms c_41 c_42 real
syms c_31 c_32 c_33 real
syms c_21 c_22 c_23 c_24 c_25 c_26 real
syms c_11 c_12 c_13 c_14 c_15 c_16 real
syms c_0 real
syms BM KM real
syms t real

c_0 = 3375;
c_11 = 3502499/400;
c_12 = 600600/400;
c_13 = 20020/400;
c_14 = -3502499/400;
c_15 = 749400/400;
c_16 = 249980/400;
c_21 = 82515/20;
c_22 = 10001/20;
c_23 = 300/20;
c_24 = -15015/20;
c_25 = 3499/20;
c_26 = 600/20;
c_31 = 675;
c_32 = 45;
c_33 = 1;
c_41 = 45;
c_42 = 1;
% t = 11.58;
% t_d = 0;

a4 = c_41 + c_42*BM;
a3 = c_31 + c_32*BM + c_33*KM;
a21 = c_21 + c_22*BM + c_23*KM;
a22 = c_24 + c_25*BM + c_26*KM;
a11 = c_11 + c_12*BM + c_13*KM;
a12 = c_14 + c_15*BM + c_16*KM;
a0 = c_0 * KM;

eq_real = a4*t.^4 - (a21 + a22*cos(t.*t_d)).*t.^2 + a12*sin(t.*t_d).*t + a0*cos(t.*t_d) == 0;
eq_imag = t.^5 - a3*t.^3 + a22*sin(t.*t_d).*t.^2 + (a11 + a12*cos(t.*t_d)).*t - a0*sin(t.*t_d) == 0;
sol = solve([eq_real eq_imag], [BM KM]);
% collect(sol.BM, t);
% collect(sol.KM, t);

% latex(simplify(sol.BM));
% latex(simplify(sol.KM));

% [num, den] = numden(sol.KM);
% collect(num, t);
% collect(den, t);
% 
% [num, den] = numden(sol.BM);
% collect(num, t);
% collect(den, t);

tdn = [0.1 0.2 0.4 0.6 1.0 2.0];
tns = [10; 7; 4.6; 3.6; 3; 2];
n = 200;
tln = [.68 .81 .90 .90 .75 0.6]*n;
tn = linspace(0, 1, n);
[TN, TDN] = meshgrid(tn, tdn);
TN = TN.*tns;
X = vpa(subs(sol.KM, {t, t_d}, {TN, TDN}));
Y = vpa(subs(sol.BM, {t, t_d}, {TN, TDN}));

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');

xlim([0, 100]);
ylim([0, 100]);

prevBoundX = [100 0];
prevBoundY = [0 0];

cn = summer(numel(tdn) + 1);

hold on;
for i=1:size(X, 1)
    fX = [X(i,:), prevBoundX];
    fY = [Y(i,:), prevBoundY];
    h = fill(fX, fY, cn(i, :));
    h.LineStyle = 'none';
    h.FaceAlpha = 0.5;
    prevBoundX = flip(X(i, :));
    prevBoundY = flip(Y(i, :));
end

fX = [0, prevBoundX];
fY = [0, prevBoundY];
h = fill(fX, fY, cn(end, :));
h.LineStyle = 'none';
h.FaceAlpha = 0.5;

for i=1:size(X, 1)
    tl = tln(i);
    angle = double(rad2deg(atan2(Y(i, tl + 1) - Y(i, tl), X(i, tl + 1) - X(i, tl))));

    th = text(X(i, tl), Y(i, tl), num2str(tdn(i)), 'Clipping', 'on', 'FontSize', 12, 'HorizontalAlignment','center', 'Rotation', angle);
    bb = th.Extent;
    x = X(i,:);
    y = Y(i,:);

    x(bb(1) < x & x < bb(1) + bb(3) & bb(2) < y & y < bb(2) + bb(4)) = nan;
    plot(x, y, 'Color', [0,0,0,0.3], 'LineWidth', 2)

end

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

xlabel('$\frac{K_\mathrm{e}}{M_\mathrm{e}}~\mathrm{[s^{-2}]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$\frac{B_\mathrm{e}}{M_\mathrm{e}}~\mathrm{[s^{-1}]}$', 'Interpreter', 'latex', 'FontSize', 16)

set(gcf,'PaperPositionMode','auto')
export_fig("images/time_delay_stab_map.png", "-png", "-m4", "-r300")





