ad = 0.8;
h = 1;
a = -1;

s0 = 1/h*lambertw(ad*h*exp(-a*h)) + a;
s11 = 1/h*lambertw(1, ad*h*exp(-a*h)) + a;
s12 = 1/h*lambertw(-1, ad*h*exp(-a*h)) + a;

tspan = [0, 5];
dde23(@(t, y, Z) ddefun(t, y, Z, ad, a), h, @history, tspan);

% s = 10*cplxgrid(60);
% cplxmap(s, 1./(s.^2 + 6*(D*s+P).*exp(-s*d)-6*g))
% cplxmap(s, 1./(s.^2 + 6*(D*s+P).*(1-s*d)-6*g))
% cplxmap(s, 1./(s.^2 + 6*(D*s+P).*(1-s*d+1/2*(s*d).^2)-6*g))
% cplxmap(s, 1./(s.^2 + 6*(D*s+P).*(1-s*d+1/2*(s*d).^2-1/6*(s*d).^3)-6*g))
% cplxmap(s, 1./(1+exp(-s)))

function dydt = ddefun(t,y,Z, ad, a)
  yd = Z(:,1);

  dydt = [
      a*y(1)+ad*yd(1)
  ];
end

function s = history(t)
  s = [1];
end