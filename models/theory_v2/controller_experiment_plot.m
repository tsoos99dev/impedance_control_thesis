clearvars;

tolerance = 0.95;

% Motor parameters
motor_params

% Impedance parameters
Me = 1*J;
be = 33.1;
w0 = 23.8;
Be = be*Me;
Ke = w0^2*Me;

% Controller
controller_calc

% Initial conditions
xi = [0; 0];
xai = xi(1);
xbi = xi(2);
nui = xbi - Ko*xai;

ei = 0;
nutildei = nui - ei;

impedance_model = ss(Aimp, Bimp, Cimp, Dimp);
imp_z = be/(2*w0);
imp_st = settling_time(imp_z, w0, tolerance);

measurement = readmatrix('controller_test1_angle_out.csv');
time = measurement(:, 1);
angle = measurement(:, 2);

measurement_voltage = readmatrix('controller_test1_voltage_out.csv');
time_voltage = measurement_voltage(:, 1);
voltage = measurement_voltage(:, 2);

control_voltage_sim_data = load("control_voltage_sim.mat");
control_voltage_sim = control_voltage_sim_data.control_voltage_sim;
control_voltage_sim.Time = control_voltage_sim.Time * 1000;

tfsim = 1000*imp_st*2.5;
x0sim = pi / 3;
xisim = [0 0 0 x0sim 0 0];
sys = ss(AAd,[],[0 0 0 1 0 0],[], t_d);
num_st = settling_time_num(sys, xisim, [0, tfsim], tolerance, x0sim, 0);
[ysim, tsim] = initial(sys, xisim, [0, tfsim]);
tsim = tsim * 1000;
ysim = x0sim - ysim;

display((num_st-imp_st)/imp_st*100)

stepOpts = RespConfig('StepAmplitude', x0sim);
[yimp, timp] = step(impedance_model(1, 1), [0, tfsim], stepOpts);
timp = timp * 1000;

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');
hold on;
plot(time, angle)
plot(tsim, ysim)
plot(timp, yimp)
yline(x0sim, '--')
yline(tolerance * x0sim, '--')
yline((2-tolerance) * x0sim, '--')
xline(1000*imp_st, '--')
xline(1000*num_st, '--')

xlim([0, tfsim])

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

title('Step response')
xlabel('$t~\mathrm{[ms]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$\theta~\mathrm{[rad]}$', 'Interpreter', 'latex', 'FontSize', 16)

legend('Mért', 'Szimulált digitális', 'Impedancia modell', 'Location','east')
set(gcf,'PaperPositionMode','auto')
export_fig("../images/step_response_experiment0005.png", "-png", "-m4", "-r300")

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');
hold on;
plot(time_voltage, voltage)
plot(control_voltage_sim)

xlim([0, tfsim])

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

title('Control voltage')
xlabel('$t~\mathrm{[ms]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$y~\mathrm{[V]}$', 'Interpreter', 'latex', 'FontSize', 16)
legend('Measurement', 'Simulated digital model')
