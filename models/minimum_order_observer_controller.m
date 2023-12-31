syms s

% Desired impedance model
Me = 1;
Be = 4;
Ke = 16;

impedance_model = tf(Ke, [Me Be Ke]);
Pe = pole(impedance_model)';

% Motor parameters
J = 0.01;
Km = 0.01;
Bm = 0.1;
L = 0.5;
R = 1;

% Motor model
Aaa = 0;
Aab = [1 0]; 
Aba = [0; 0];
Abb = [-Bm/J Km/J; -Km/L -R/L];
A = [Aaa Aab; Aba Abb];
Bt = [0; 1/J; 0];
Bv = [0; 0; 1/L];
B = [Bt Bv];
C = [1 0 0];
D = [0 0];

% New poles
P = [Pe -8];
Po = -8 * [1 1];

motor = ss(A, B, C, D, 'InputName', {'t', 'V'}, 'OutputName', 'a', 'StateName', {'a', 'w', 'i'});
% step(motor)
% ss2tf(A, B, C, D, 1)
% ss2tf(A, B, C, D, 2)

K = acker(A, Bv, P);
Ka = K(1);
Kb = K(2:end);
Kee = acker(Abb', Aab', Po)';

% Observer-controller dynamics
AA = [A-Bv*K Bv*Kb; zeros(2, 3) Abb-Kee*Aab];
BB = [Bv*K(1); zeros(2, 1)];
CC = eye(5);
DD = zeros(5, 1);
c1 = ss(AA, BB, CC, DD, 'InputName', {'a0'}, 'OutputName', {'a', 'w', 'i', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ew', 'ei'});
pc1 = pole(c1);
% O = s*eye(6) - AA;
% vpa(subs(collect(CC/O*BB), s, 0))
% initial(c1(1, 1), [1; 0; 0; 0.5; 0; 0]);
% [num, den] = ss2tf(AA, BB, CC, DD, 1)

% [N, D] = ss2tf(AA, BB, CC, DD)

% Disturbance response
AA = [A-Bv*K Bv*Kb; zeros(2, 3) Abb-Kee*Aab];
BB = [Bt; Bt(2:end)];
CC = eye(5);
DD = zeros(5, 1);
c2 = ss(AA, BB, CC, DD, 'InputName', {'a0'}, 'OutputName', {'a', 'w', 'i', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ew', 'ei'});
O = s*eye(5) - AA;
vpa(subs(collect(CC/O*BB), s, 0))
% tzero(c2(1))

palette = ["#79addc" "#ffc09f" "#ffee93" "#fcf5c7" "#adf7b6"];

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');
hold on;

tmax = 5;
yline(1, '--', Color='black', LineWidth=2, Alpha=0.2)
[y, t] = step(impedance_model, tmax);
s1 = plot(t, y, 'Color', palette(1), 'LineWidth', 2);
[y, t] = step(c1(1), tmax);
s2 = plot(t, y, 'Color', palette(2), 'LineWidth', 2);
% [y, t] = step(c1(5), tmax);
% s1 = plot(t, y, 'Color', palette(2), 'LineWidth', 2);
% [y, t] = step(c2(1), tmax);
% s3 = plot(t, y, 'Color', palette(2), 'LineWidth', 2);

xlabel('Id\H o $[\mathrm{s}]$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('Sz\"ogelfordul\''as $[\mathrm{rad}]$', 'Interpreter', 'latex', 'FontSize', 16)

hLegend = legend([s1, s2], ...
    'Impedancia modell', 'Pozíció szabályozó', ...
    'Location', 'southeast', 'FontSize', 10);
legend boxoff;
set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

set(gcf,'PaperPositionMode','auto')
export_fig("images/observer_controller_pos_resp.png", "-png", "-m4", "-r300")

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');
hold on;

tmax = 5;
yline(1/Ke, '--', Color='black', LineWidth=2, Alpha=0.2)
yline(dcgain(c2(1)), '--', Color='black', LineWidth=2, Alpha=0.2)
[y, t] = step(impedance_model/Ke, tmax);
s1 = plot(t, y, 'Color', palette(1), 'LineWidth', 2);
[y, t] = step(c2(1), tmax);
s2 = plot(t, y, 'Color', palette(2), 'LineWidth', 2);

xlabel('Id\H o $[\mathrm{s}]$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('Sz\"ogelfordul\''as $[\mathrm{rad}]$', 'Interpreter', 'latex', 'FontSize', 16)

hLegend = legend([s1, s2], ...
    'Impedancia modell', 'Pozíció szabályozó', ...
    'Location', 'southeast', 'FontSize', 10);
legend boxoff;
set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

set(gcf,'PaperPositionMode','auto')
export_fig("images/observer_controller_torque_resp.png", "-png", "-m4", "-r300")
% 
% % poles(K/(s*eye(3) - A + Ke*C + Bv*K)*Ke)
% 
% % figure;
% % xl = [-30, 1];
% % subplot(3, 2, 2)
% % pzmap(impedance_model)
% % xlim(xl);
% % subplot(3, 2, 4)
% % pzmap(c1(1))
% % xlim(xl);
% % subplot(3, 2, 6)
% % pzmap(c2(1))
% % xlim(xl);
