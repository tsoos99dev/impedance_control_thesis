MAX_SPEED_REF = 30000;

measurement = readmatrix("driver_output_voltage.csv");
speed_ref = measurement(:, 1);
voltage = measurement(:, 2);

duty = speed_ref / MAX_SPEED_REF * 100;

N = numel(speed_ref);
sx = sum(duty);
sy = sum(voltage);
ssx = sum(duty.^2);
sxy = sum(duty.*voltage);
delta = N.*ssx - sx.^2;
A = (ssx.*sy-sx.*sxy)/delta;
B = (N.*sxy-sx.*sy)/delta;
dV = sqrt(sum((voltage - A - B*duty).^2)/(N-2));
dA = dV * sqrt(ssx/delta);
dB = dV * sqrt(N/delta);

d_reg = 0:100;
v_reg = A + B*d_reg;

v_reg(end)

figure;
pbaspect([8,6,1])
set(gcf,'color', 'w');
set(gca, 'FontName', 'Helvetica');

hold on;

scatter(duty, voltage, 'k', 'filled');
plot(d_reg, v_reg, 'k');

xlim([0, 100]);
ylim([0, 12]);

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

xlabel('$f~\mathrm{[\%]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$V_\mathrm{k}~\mathrm{[V]}$', 'Interpreter', 'latex', 'FontSize', 16)

set(gcf,'PaperPositionMode','auto')
export_fig("../images/driver_linearity.png", "-png", "-m4", "-r300")