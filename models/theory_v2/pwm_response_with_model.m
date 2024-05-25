B = 2.7e-7;
R = 8.5;
L = 492e-6;
K = 15.4e-3;
V = 12;
N = 4.4;
fp = 20e3;
tp = 1/fp;
tau_f = 1.5e-4;
measurement = readmatrix("motor_pwm_response20_2_out.csv");
duty = measurement(:, 1);
speed = measurement(:, 2) * N * 2 * pi / 60;

optimal_response = S_MAX*duty/100;
theta_crit = V/K*(1-exp(duty/100*tp/(L/R)))./(1-exp(tp/(L/R)));
discont_t = @(f,y) B*y + tau_f - K/2*(V-K*y)/R.*(1-exp(-f/100*tp/(L/R))).* ...
    L/R/tp.*log(1 + V./(K*y).*(exp(f/100*tp/(L/R))-1));
cont_t = @(f,y) B*y + tau_f - K/2*((V-K*y)/R.*(1-exp(-f/100*tp/(L/R)))+ ...
    (V/R*(1-exp(f/100*tp/(L/R)))./(1-exp(tp/(L/R)))-K*y/R).*(1+exp(-f/100*tp/(L/R))));


figure;
pbaspect([8,6,1])
set(gcf,'color', 'w');
set(gca, 'FontName', 'Helvetica');

hold on;

% plot(duty, optimal_response, "-.", LineWidth=2, Color='#F37748');
plot(duty, theta_crit, "--", LineWidth=2, Color='#ECC30B');
fimplicit(cont_t, LineWidth=2, Color='#C7D66D');
fimplicit(discont_t, LineWidth=2, Color='#75B9BE');
scatter(duty, speed, 'k', 'filled');

xlim([0, 100]);
ylim([0, 800]);

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

xlabel('$f~\mathrm{[\%]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$\omega_\mathrm{f}~\mathrm{[rad/s]}$', 'Interpreter', 'latex', 'FontSize', 16)
legend('Kritikus szögsebesség', 'Folytonos üzemmód', 'Szakaszos üzemmód', 'Mérés', 'Location', 'southeast')

set(gcf,'PaperPositionMode','auto')
export_fig("../images/motor_pwm_response20_with_model.png", "-png", "-m4", "-r300")