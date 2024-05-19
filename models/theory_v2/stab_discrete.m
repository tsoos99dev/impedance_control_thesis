% Motor parameters
motor_params

% Impedance parameters
syms Be Ke;
Me = 1*J;

% Controller
controller_calc

% Stability map
tolerance = 0.95;
max_sti = 10;

pn = 300;
xn = 0;
xm = 75;
yn = 0;
ym = 2*xm;
ko = linspace(xn,xm, pn);
bo = linspace(yn,ym, pn);
[KO, BO] = meshgrid(ko, bo);
KN = KO.^2*Me;
BN = BO * Me;

fAAd = matlabFunction(AAd);
CAAd = arrayfun(@(ki, bi) fAAd(bi, ki), KN, BN, 'UniformOutput', false);

fAdtilde = matlabFunction(Adtilde);
fBdtilde = matlabFunction(Bdtilde);
fCdtilde = matlabFunction(Cdtilde);
fDdtilde = matlabFunction(Ddtilde);
CAdtilde = cell2mat(arrayfun(@(bi) fAdtilde(bi), BN, 'UniformOutput', false));
CBdtilde = cell2mat(arrayfun(@(ki, bi) fBdtilde(bi, ki), KN, BN, 'UniformOutput', false));
CCdtilde = cell2mat(arrayfun(@(bi) fCdtilde(bi), BN, 'UniformOutput', false));
CDdtilde = cell2mat(arrayfun(@(ki, bi) fDdtilde(bi, ki), KN, BN, 'UniformOutput', false));

stab = nan(size(KO));
settle_map_imp = nan(size(KO));
settle_map = nan(size(KO));

tic
parfor ii = 1:numel(KO)
    ki = KO(ii);
    bi = BO(ii);
    Ki = KN(ii);
    Bi = BN(ii);
    AAdn = CAAd{ii};
    stab(ii) = max(abs(eig(AAdn)));
    sti = settling_time(bi/(2*ki), ki, tolerance);
    settle_map_imp(ii) = sti;
    if sti < max_sti
        settle_map(ii) = settle_map_num(AAdn, sti, t_d, tolerance);
    end
end
toc

KOs = KO(stab <= 1);
BOs = BO(stab <= 1);

settle_err = (settle_map - settle_map_imp)./settle_map_imp;
settle_err(isnan(settle_err)) = inf;
settle_err(stab > 1 | settle_map_imp > max_sti) = nan;

DT = delaunayTriangulation([KOs, BOs]);
k = convexHull(DT);
xHull = DT.Points(k,1);
yHull = DT.Points(k,2);

z_val = BO./(2*KO);

function st = settle_map_num(A, sti, t_d, tol)
    x0 = 1;
    xf = 0;
    xi = [0 0 0 x0 0 0]';
    tf = 2*sti;
    sys = ss(A,[],[0 0 0 1 0 0],[], t_d);
    st = settling_time_num(sys, xi, tf, tol, x0, xf);
end
