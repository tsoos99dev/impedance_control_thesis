N = 4.4;
S_MAX = N * 2 * pi / 60 * (12*140-70);

measurement = readmatrix("motor_pwm_response20_2_out.csv");
duty = measurement(:, 1);
speed = measurement(:, 2) * N * 2 * pi / 60;

figure;
pbaspect([8,6,1])
set(gcf,'color', 'w');
set(gca, 'FontName', 'Helvetica');

hold on;

scatter(duty, speed, 'k', 'filled');
plot(duty, S_MAX*duty/100, "--", LineWidth=2, Color=[0.0217, 0.0156, 0.0115]);

xlim([0, 100]);
ylim([0, 800]);

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

xlabel('$f~\mathrm{[\%]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$\omega_\mathrm{f}~\mathrm{[rad/s]}$', 'Interpreter', 'latex', 'FontSize', 16)

set(gcf,'PaperPositionMode','auto')
export_fig("../images/motor_pwm_response20.png", "-png", "-m4", "-r300")