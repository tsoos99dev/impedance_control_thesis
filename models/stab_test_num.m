syms p d real;

Astab = [
    1 1 1/2
    0 1 1
    -p -d 0
];

f = @(po, do) arrayfun(@(pi, di) max(abs(eig(double(subs(Astab, {p, d}, {pi, di}))))), po, do);

po = linspace(0,0.5);
do = linspace(0,1);
[PO, DO] = meshgrid(po, do);
stab = f(PO, DO);
PO(stab > 1) = nan;
DO(stab > 1) = nan;
scatter(PO, DO, 'black');

xlim([0, 0.5])
ylim([0, 1])
