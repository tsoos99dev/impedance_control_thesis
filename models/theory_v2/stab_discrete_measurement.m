clearvars;

% Stability analysis
stab_discrete

sweep_output = readmatrix("sweep_output1.csv");
mKO = sweep_output(:, 1);
mBO = sweep_output(:, 2);
msettle = sweep_output(:, 3) / 1000;
msettle_err = sweep_output(:, 4) / 1000;
mfrac_err = msettle_err ./ msettle;

% Plot
figure;
pbaspect([8,6,1])
set(gcf,'color', 'w');
set(gca, 'FontName', 'Helvetica');
set(gca,'Color',[1 0.988 0.949 0.4]);
histogram(mfrac_err * 100)
grid('on')
xlabel('$\delta t~\mathrm{[\%]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$N~\mathrm{[-]}$', 'Interpreter', 'latex', 'FontSize', 16)


figure;
pbaspect([8,6,1])
set(gcf,'color', 'w');
set(gca, 'FontName', 'Helvetica');
set(gca,'Color',[1 0.988 0.949 0.4]);

hold on;

% [~, c] = contourf(KO, BO, settle_err, [-1 -0.5 -0.25 -0.1:0.025:0.1 0.5 0.25 1],  '-k');
% % clabel(M, c, "FontSize", 12, 'LabelSpacing', 550);
% c.LineWidth = 0.5;
% c.FaceAlpha = 0.4;
% colormap(turbo);
% clim([-0.1, 0.1])

scatter_point_size = 50;

% Failed measurements
fcond = isnan(msettle);
fKO = mKO(fcond);
fBO = mBO(fcond);
scatter(fKO, fBO, scatter_point_size, 'k', 'x');

% Successful measurements
accept_threshold = 1.8;
reject_threshold = 2.5;

fcond = ~isnan(msettle);
fKO = mKO(fcond);
fBO = mBO(fcond);
fsettle = msettle(fcond);
fsettle_err = msettle_err(fcond);
fsettle_imp = interp2(KO, BO, settle_map_imp, fKO, fBO);
fsettle_model = interp2(KO, BO, settle_map, fKO, fBO);

measurement_discrepancy = abs(fsettle - fsettle_model)./fsettle_err;
accept_cond = measurement_discrepancy < accept_threshold;
inconclusive_cond = accept_threshold < measurement_discrepancy & measurement_discrepancy < reject_threshold;
reject_cond = reject_threshold < measurement_discrepancy;

aKO = fKO(accept_cond);
aBO = fBO(accept_cond);
scatter(aKO, aBO, scatter_point_size, [0.4660 0.6740 0.1880], 'filled');

aKO = fKO(inconclusive_cond);
aBO = fBO(inconclusive_cond);
scatter(aKO, aBO, scatter_point_size, [0.2 0.2 0.2], 'filled');

aKO = fKO(reject_cond);
aBO = fBO(reject_cond);
scatter(aKO, aBO, scatter_point_size, [0.6350 0.0780 0.1840], 'filled');

% Impedance parameter plots
p = plot(xHull,yHull,'Color', [0 0 0 0.5], 'LineWidth', 2); 

[M, c] = contour(KO, BO, z_val, [0.1 0.25 0.5 1 2 4 8], '--k');
clabel(M, c, "FontSize", 12, 'LabelSpacing', 550);
c.LineWidth = 0.5;

[M, c] = contour(KO, BO, settle_map_imp, [0.1 0.15 0.2 0.25 0.35 0.5 1 2 5], '-.k');
clabel(M, c, "FontSize", 12, 'LabelSpacing', 550);
c.LineWidth = 0.75;

% Utilisation
max_step = pi;
utilisation = 100 .* min(1,  30/25*max_step * N * CDdtilde(:, 1:3:end) / V);

xlim([xn, xm])
ylim([yn, ym])

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

xlabel('$w_0~\mathrm{[rad/s]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$b_\mathrm{e}~\mathrm{[rad/s^2]}$', 'Interpreter', 'latex', 'FontSize', 16)
