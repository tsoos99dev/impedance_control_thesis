syms s

% Motor parameters
% This has the biggest effect on how distorted
% the torque response is.
Km = 0.998;
Jm = 1.44e-7;

Ifinal = 40.1e-3;
vfinal = 2*pi/60 * 6780;
vgear = 2*pi/60 * 80.4;
gr = vfinal/vgear;

Jl = 1e-4;
J = Jm + 1/gr^2 * Jl;

Bm = Km*Ifinal/vfinal;

L = 0.452e-3;
R = 10.6;

% Desired impedance model
Me = 2*J;
Be = 4*Me;
Ke = 4*Be;

impedance_model = tf(Ke, [Me Be Ke]);
Pe = pole(impedance_model)';

% Motor model
Aaa = 0;
Aab = [1 0]; 
Aba = [0; 0];
Abb = [-Bm/J Km/J; -Km/L -R/L];
A_b = [Aab; Abb];
A = [Aaa Aab; Aba Abb];

Bat = 0;
Bbt = [1/J; 0];
Bt = [Bat; Bbt];
Bav = 0;
Bbv = [0; 1/L];
Bv = [Bav; Bbv];
B = [Bt Bv];
C = [1 0 0];
D = [0 0];

% New poles
p = min(-Be/8/Me/0.05, -10*Me/J);
P = [Pe p];
Po = p * [1 1];

motor = ss(A, B, C, D, 'InputName', {'t', 'V'}, 'OutputName', 'a', 'StateName', {'a', 'w', 'i'});
% step(motor)
% ss2tf(A, B, C, D, 1)
% ss2tf(A, B, C, D, 2)

K = acker(A, Bv, P);
Ka = K(1);
Kb = K(2:end);

Ko = acker(Abb', Aab', Po)';

% Guarantees the correct torque response steady state value.
kc = (R+K(3))/Km-Ka/Ke;

% Observer-controller dynamics
AA = [A-Bv*K Bv*Kb; zeros(2, 3) Abb-Ko*Aab];
BB = [Bv*Ka; zeros(2, 1)];
CC = eye(5);
DD = zeros(5, 1);
c1 = ss(AA, BB, CC, DD, 'InputName', {'a0'}, 'OutputName', {'a', 'w', 'i', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ew', 'ei'});
pc1 = pole(c1);
% O = s*eye(6) - AA;
% vpa(subs(collect(CC/O*BB), s, 0))
% initial(c1(1, 1), [1; 0; 0; 0.5; 0; 0]);
% [num, den] = ss2tf(AA, BB, CC, DD, 1)

% ss2tf(AA, BB, CC, DD)

% Disturbance response
AA = [A-Bv*K Bv*Kb; zeros(2, 3) Abb-Ko*Aab];
BB = [Bt - Bv*kc; zeros(2, 1)];
CC = eye(5);
DD = zeros(5, 1);
c2 = ss(AA, BB, CC, DD, 'InputName', {'a0'}, 'OutputName', {'a', 'w', 'i', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ew', 'ei'});

palette = ["#79addc" "#ffc09f" "#ffee93" "#fcf5c7" "#adf7b6"];

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');
hold on;
ylim([0, 1.2])

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
    'Impedancia modell', 'Kalibrált szabályozó', ...
    'Location', 'southeast', 'FontSize', 10);
legend boxoff;
set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

set(gcf,'PaperPositionMode','auto')
export_fig("images/observer_controller_pos_resp_direct_comp_calib.png", "-png", "-m4", "-r300")

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');
hold on;

sf = 0.1/gr^2;
tmax = 5;
yline(1/Ke*sf, '--', Color='black', LineWidth=2, Alpha=0.2)
yline(dcgain(c2(1)*sf), '--', Color='black', LineWidth=2, Alpha=0.2)
[y, t] = step(impedance_model/Ke*sf, tmax);
s1 = plot(t, y, 'Color', palette(1), 'LineWidth', 2);
[y, t] = step(c2(1)*sf, tmax);
s2 = plot(t, y, 'Color', palette(2), 'LineWidth', 2);

xlabel('Id\H o $[\mathrm{s}]$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('Sz\"ogelfordul\''as $[\mathrm{rad}]$', 'Interpreter', 'latex', 'FontSize', 16)

hLegend = legend([s1, s2], ...
    'Impedancia modell', 'Kalibrált szabályozó', ...
    'Location', 'southeast', 'FontSize', 10);
legend boxoff;
set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

set(gcf,'PaperPositionMode','auto')
export_fig("images/observer_controller_torque_resp_direct_comp_calib.png", "-png", "-m4", "-r300")
