syms s

% Desired impedance model
Me = 1;
Be = 4;
Ke = 16;

impedance_model = tf(Ke, [Me Be Ke]);
Pe = pole(impedance_model)';

% Motor parameters
% This has the biggest effect on how distorted 
% the torque response is.
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
P = [Pe -6];
Po = -8 * [1 1.1];

motor = ss(A, B, C, D, 'InputName', {'t', 'V'}, 'OutputName', 'a', 'StateName', {'a', 'w', 'i'});
% step(motor)
% ss2tf(A, B, C, D, 1)
% ss2tf(A, B, C, D, 2)

K = place(A, Bv, P);
Ka = K(1);
Kb = K(2:end);

Ae = Abb - Bbt*[0 1 0]*A_b;
Ko = place(Ae', Aab', Po)';

% Guarantees the correct torque response steady state value.
kc = (R+K(3))/Km-Ka/Ke;

% Observer-controller dynamics
AA = [A-Bv*K Bv*(Kb-[0 1 0]*A_b*kc); zeros(2, 3) Ae-Ko*Aab];
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
AA = [A-Bv*K Bv*(Kb-[0 1 0]*A_b*kc); zeros(2, 3) Ae-Ko*Aab];
BB = [Bt - Bv*kc; zeros(2, 1)];
CC = eye(5);
DD = zeros(5, 1);
c2 = ss(AA, BB, CC, DD, 'InputName', {'a0'}, 'OutputName', {'a', 'w', 'i', 'ew', 'ei'}, 'StateName', {'a', 'w', 'i', 'ew', 'ei'});
O = s*eye(5) - AA;
vpa(subs(collect(CC/O*BB), s, 0))

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

xlabel('Id\H o $[s]$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('Sz\"ogelfordul\''as $\left[rad\right]$', 'Interpreter', 'latex', 'FontSize', 16)

hLegend = legend([s1, s2], ...
    'Impedancia modell', 'Pozíció szabályozó', ...
    'Location', 'southeast', 'FontSize', 10);
legend boxoff;
set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

% set(gcf,'PaperPositionMode','auto')
% export_fig("observer_controller_pos_resp.png", "-png", "-m4", "-r300")

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

xlabel('Id\H o $[s]$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('Sz\"ogelfordul\''as $\left[rad\right]$', 'Interpreter', 'latex', 'FontSize', 16)

hLegend = legend([s1, s2], ...
    'Impedancia modell', 'Pozíció szabályozó', ...
    'Location', 'southeast', 'FontSize', 10);
legend boxoff;
set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)
