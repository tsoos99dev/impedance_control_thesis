clearvars;

MAX_VOLTAGE = 11.835;
MAX_SPEED_REF = 30000;

measurement = readmatrix("speed_profile_out.csv");
voltage = measurement(:, 1);
speed = measurement(:, 2);

N = numel(voltage);
sx = sum(voltage);
sy = sum(speed);
ssx = sum(voltage.^2);
sxy = sum(speed.*voltage);
delta = N.*ssx - sx.^2;
A = (ssx.*sy-sx.*sxy)/delta;
B = (N.*sxy-sx.*sy)/delta;
dS = sqrt(sum((speed - A - B*voltage).^2)/(N-2));
dA = dS * sqrt(ssx/delta);
dB = dS * sqrt(N/delta);

v_reg = 0:12;
s_reg = A + B*v_reg;

figure;
pbaspect([8,6,1])
set(gcf,'color', 'w');
set(gca, 'FontName', 'Helvetica');

hold on;

errorbar(voltage, speed, dS*ones(N), 'k')
scatter(voltage, speed, 'k', 'filled');
plot(v_reg, s_reg, 'k');

xlim([0, 12]);
ylim([0, 700]);

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

xlabel('$V_\mathrm{k}~\mathrm{[V]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$\omega~\mathrm{[rad/s^2]}$', 'Interpreter', 'latex', 'FontSize', 16)

set(gcf,'PaperPositionMode','auto')
export_fig("../images/speed_profile.png", "-png", "-m4", "-r300")