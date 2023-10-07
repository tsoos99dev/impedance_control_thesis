P = 13;
D = 1;
d = 0.1;
m = 1;
l = 1;
g = 10;

opts = optimoptions("fsolve", "Algorithm","levenberg-marquardt");
s1 = fsolve(@(s) p1(s, P, D, d, m, l, g), 1+1i, opts);
s2 = fsolve(@(s) p2(s, P, D, d, m, l, g), 1+1i, opts);
function F = p1(s, P, D, d, m, l, g)
    F = sqrt(s+6*g/l)+1/d*lambertw(0, m*l*d/(6*D)*s*exp(-6*P*d/(m*l)))-P/D;
end


function F = p2(s, P, D, d, m, l, g)
    F = -sqrt(s+6*g/l)+1/d*lambertw(0, m*l*d/(6*D)*s*exp(-6*P*d/(m*l)))-P/D;
end