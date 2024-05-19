clearvars;

% Stability analysis
stab_discrete

% Measurement points
merr_max = 0.5;
msettle_max = 1;
mpn = 50;
mko = linspace(xn,xm, mpn);
mbo = linspace(yn,ym, mpn);
[MKO, MBO] = meshgrid(mko, mbo);

mstab = interp2(KO, BO, stab, MKO, MBO);
msettle_map = interp2(KO, BO, settle_map, MKO, MBO);
msettle_err = interp2(KO, BO, settle_err, MKO, MBO);

mcond = mstab <= 1 & msettle_map < msettle_max & abs(msettle_err) < merr_max;
MKO = MKO(mcond);
MBO = MBO(mcond);
msettle_map = msettle_map(mcond);
msettle_err = msettle_err(mcond);

mAdtilde = interp2(KO, BO, CAdtilde, MKO, MBO);
mBdtilde = cell2mat(arrayfun(@(i) interp2(KO, BO, CBdtilde(:, i:3:end), MKO, MBO), 1:3, 'UniformOutput', false));
mCdtilde = interp2(KO, BO, CCdtilde, MKO, MBO);
mDdtilde = cell2mat(arrayfun(@(i) interp2(KO, BO, CDdtilde(:, i:3:end), MKO, MBO), 1:3, 'UniformOutput', false));

mPoints = [MKO MBO mAdtilde mBdtilde mCdtilde mDdtilde msettle_map msettle_err];
writematrix(mPoints, "measurement_params.csv")
