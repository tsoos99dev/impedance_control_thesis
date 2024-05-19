syms s mu eta
syms Me Be Ke J Km Bm L R t_d real
syms po real

Me0 = 0.015;

Aimp = [0 1; -Ke/Me -Be/Me];
Bimp = [0 0; Ke/Me 1/Me];
Cimp = [1 0];
Dimp = zeros(2);

impedance_model = Cimp/(s*eye(2) - Aimp)*Bimp + Dimp;

J = 0.01;
Km = 0.01;
Bm = 0.1;
L = 0.2;
R = 1;

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

po = -15;
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

Md = expm([A Bv; zeros([1, 4])]*t_d);
Ad = Md(1:3, 1:3);
Bd = Md(1:3, 4:end);
Cd = C;
Dd = D;

Adtilde = expm(Atilde*t_d);
Bdtilde = Atilde\(Adtilde-eye(2))*Btilde;
Bdtilder = Bdtilde(:, 1);
Bdtildet = Bdtilde(:, 2);
Bdtildey = Bdtilde(:, 3);

Adaa = Ad(1, 1);
Adab = Ad(1, 2:end);
Adba = Ad(2:end, 1);
Adbb = Ad(2:end, 2:end);

Bda = Bd(1, :);
Bdb = Bd(2:end, :);

AAdx = [-Bd*K Bd*Kb Ad zeros(3, 2)];

AAdexa = Adba + Adtilde*Ko - Ko*Adaa - Bdtildey;
AAdexb = Adbb - Adtilde - Ko*Adab;
AAdex1 = -(Bdb-Ko*Bda)*K;
AAdee = Adtilde;
AAdee1 = (Bdb-Ko*Bda)*Kb;
AAde = [AAdex1 AAdee1 AAdexa AAdexb AAdee];


AAd = [
    zeros([3, 5]) eye(3) zeros([3, 2])
    zeros([2, 5]) zeros([2,3]) eye(2)
    AAdx
    AAde
];

td = 0.1;
AAd = subs(AAd, [Me, t_d], [Me0, td]);
fAAd = matlabFunction(AAd);
% f = max(abs(eig(double(subs(AAd, {Ke, Be}, {ki, bi}));
f = @(ko, bo) arrayfun(@(ki, bi) max(abs(eig(double(fAAd(bi, ki))))), ko, bo);

pn = 150;
xm = 0.5;
ym = 0.2;
ko = linspace(0,xm, pn);
bo = linspace(0,ym, pn);
[KO, BO] = meshgrid(ko, bo);
stab = f(KO, BO);
KOs = KO(stab <= 1);
BOs = BO(stab <= 1);

tmax = 100;
te = 8*Me0./BO;
relT = (td.*log(0.02)./log(stab))./te;
relT(stab >= 1) = inf;
% KOc = KO(stabt < tmax);
% BOc = BO(stabt < tmax);

% tmin = min(stabt, [], 'all');
% [tminx,tminy] = find(stabt==tmin);
% tmink = KO(tminx, tminy);
% tminb = BO(tminx, tminy);
% tminI = 4/(0.5*tminb/Me);

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');

palette = summer(5);
DT = delaunayTriangulation([KOs, BOs]);
vertices = DT.Points;
faces = DT.ConnectivityList;
vi = nearestNeighbor(DT, vertices);
col = interp2(KO, BO, relT, vertices(:, 1), vertices(:, 2));

hold on;
patch('Faces', faces, 'Vertices', vertices,'FaceColor', "#EDB120", 'EdgeColor', 'none', 'FaceAlpha', 0.5)

k = convexHull(DT);
xHull = DT.Points(k,1);
yHull = DT.Points(k,2);
p = plot(xHull,yHull,'Color', [0 0 0 0.5], 'LineWidth', 2); 

labelfun = @(v) arrayfun(@(v) num2str(-v) + "", v);
[M, c] = contourf(KO, BO, -relT, -[0.9 1 2 4 8 16 32], "ShowText",true, "LabelFormat", labelfun);
clabel(M, c, "FontSize", 14, 'labelspacing', 200);
c.LineWidth = 2;
c.FaceAlpha = 0.5;
c.EdgeAlpha = 0.4;

% patch('Faces', faces, 'Vertices', vertices, 'FaceVertexCData',col,'FaceColor','interp', 'EdgeColor', 'none')
colormap(flipud(summer));

% plot(tmink,tminb,'.', 'Color', 'black', 'MarkerSize', 16)
% xline(tmink, '--', 'Color',[0 0 0 0.4])
% yline(tminb, '--', 'Color',[0 0 0 0.4])

xlim([0, xm])
ylim([0, ym])

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

xlabel('$K_\mathrm{e}~\mathrm{[kg \cdot m^{2} \cdot s^{-2}]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$B_\mathrm{e}~\mathrm{[kg \cdot m^{2} \cdot s^{-1}]}$', 'Interpreter', 'latex', 'FontSize', 16)

set(gcf,'PaperPositionMode','auto')
export_fig("images/time_delay_stab_map_discrete_diff.png", "-png", "-m4", "-r300")



% pcd = collect(subs(charpoly(AAd, mu), mu, (eta+1)/(eta-1))*(eta-1)^10, eta);
% c = vpa(subs(coeffs(pcd, eta), t_d, 0.1));
% c = fliplr(c);
% 
% f0 = @(k, b) double(subs(c(end), {Ke, Be}, {k, b}));
% fimplicit(f0, [0,100,0,100]);

% vpa(subs(pcd, [Be Ke t_d], [0.06, Me*4.6, 0.1]))

