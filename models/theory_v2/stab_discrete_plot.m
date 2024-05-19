clearvars;

% Stability analysis
stab_discrete

% Plot
figure;
pbaspect([8,6,1])
set(gcf,'color', 'w');
set(gca, 'FontName', 'Helvetica');
set(gca,'Color',[1 0.988 0.949 0.4]);

hold on;

[~, c] = contourf(KO, BO, settle_err, [-1 -0.5 -0.25 -0.1:0.025:0.1 0.5 0.25 1],  '-k');
% clabel(M, c, "FontSize", 12, 'LabelSpacing', 550);
c.LineWidth = 0.5;
c.FaceAlpha = 0.4;
colormap(turbo);
clim([-0.1, 0.1])

p = plot(xHull,yHull,'Color', [0 0 0 0.5], 'LineWidth', 2); 

[M, c] = contour(KO, BO, z_val, [0.1 0.25 0.5 1 2 4 8], '--k');
clabel(M, c, "FontSize", 12, 'LabelSpacing', 550);
c.LineWidth = 0.5;

[M, c] = contour(KO, BO, settle_map_imp, [0.1 0.15 0.2 0.25 0.35 0.5 1 2 5], '-.k');
clabel(M, c, "FontSize", 12, 'LabelSpacing', 550);
c.LineWidth = 0.75;

xlim([xn, xm])
ylim([yn, ym])

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

xlabel('$w_0~\mathrm{[rad/s]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$b_\mathrm{e}~\mathrm{[rad/s^2]}$', 'Interpreter', 'latex', 'FontSize', 16)
