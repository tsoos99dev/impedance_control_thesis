m = 1;
g = 9.8;
l = 2;
d = 0.261;

dcrit1 = sqrt(l/(6*g));
dcrit2 = sqrt(l/(3*g));

xm = linspace(9.7, 10, 100);
ym = linspace(2.5, 2.6, 100);
[X,Y] = meshgrid(xm, ym);

% Taylor 1
c1 = @(x,y) 6*x/(m*l)-6*g/l;
c2 = @(x,y) 6*y/(m*l)-6*x*d/(m*l);
c3 = @(x,y) 1-6*y*d/(m*l);
cond = c1(X, Y) >= 0 & c2(X, Y) >= 0 & c3(X, Y) >= 0;

% Pade 1
c4 = @(x,y) 1-3*y*d/(m*l);
c5 = @(x,y) (1-3*y*d/(m*l)).*(6*y/(m*l)-3*g*d/l)-1/2*d*(6*x/(m*l)-6*g/l);
cond2 = c1(X, Y) >= 0 & c4(X, Y) >= 0 & c5(X, Y) >= 0;

% Taylor 2
c6 = @(x,y) 3*y*d^2/(m*l);
c7 = @(x,y) 1+3*x*d^2/(m*l)-6*y*d/(m*l);
c8 = @(x,y) (1+3*x*d^2/(m*l)-6*y*d/(m*l)).*(6*y/(m*l)-6*x*d/(m*l))-3*y*d^2/(m*l).*(6*x/(m*l)-6*g/l);
cond3 = c1(X, Y) >= 0 & c6(X, Y) >= 0 & c7(X, Y) >= 0 & c8(X, Y) >= 0;


% Pade 2
a0 = 1/12*d^2;
a1 = @(x,y) 1/2*(d+y*d^2/(m*l));
a2 = @(x,y) 1-1/2*g*d^2/l-3*y*d/(m*l)+1/2*x*d^2/(m*l);
a3 = @(x,y) 3*g*d/l+6*y*d/(m*l)-3*x*d/(m*l);
a4 = @(x,y) 6*x/(m*l)-6*g/l;
D2 = @(x,y) a2(x, y).*a1(x, y)-a0.*a3(x, y);
D3 = @(x,y) a3(x, y).*D2(x, y)-a1(x, y).*a1(x, y).*a4(x, y);
c9 = a1;
c10 = a3;
c11 = D3;

cond4 = c1(X, Y) >= 0 & c9(X, Y) >= 0 & c10(X, Y) >= 0 & c11(X, Y) >= 0;




subplot(2, 1, 1);
fimplicit(c1)
hold on;
% fimplicit(c2)
% fimplicit(c3)
% 
fimplicit(c4)
fimplicit(c5)

fimplicit(c6)
fimplicit(c7)
fimplicit(c8)

fimplicit(c9)
fimplicit(c10)
fimplicit(c11)
% scatter(X(cond), Y(cond), 'green', 'filled', 'o', 'MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3)
scatter(X(cond2), Y(cond2), 'blue', 'filled', 'o', 'MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
scatter(X(cond3), Y(cond3), 'blue', 'filled', 'o', 'MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
scatter(X(cond4), Y(cond4), 'green', 'filled', 'o', 'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
xlim([xm(1), xm(end)])
ylim([ym(1), ym(end)])

subplot(2, 1, 2);

P = 9.803;
D = 2.585;

tspan = [0, 100];
dde23(@(t, y, Z) ddefun(t,y,Z, P, D, m, l, g), d, @history, tspan);

% s = 10*cplxgrid(60);
% cplxmap(s, 1./(s.^2 + 6*(D*s+P).*exp(-s*d)-6*g))
% cplxmap(s, 1./(s.^2 + 6*(D*s+P).*(1-s*d)-6*g))
% cplxmap(s, 1./(s.^2 + 6*(D*s+P).*(1-s*d+1/2*(s*d).^2)-6*g))
% cplxmap(s, 1./(s.^2 + 6*(D*s+P).*(1-s*d+1/2*(s*d).^2-1/6*(s*d).^3)-6*g))
% cplxmap(s, 1./(1+exp(-s)))

function dydt = ddefun(t,y,Z, P, D, m, l, g)
  yd = Z(:,1);

  dydt = [
      y(2);
      6*g/l*y(1) - 6*D/(m*l)*yd(2) - 6*P/(m*l)*yd(1)
  ];
end

function s = history(t)
  s = [0.1, 0];
end