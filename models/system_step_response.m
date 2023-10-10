% Motor parameters
J = 0.01;
Km = 0.01;
Bm = 0.1;
L = 0.5;
R = 1;

% Motor model
A = [0 1 0; 0 -Bm/J Km/J; 0 -Km/L -R/L];
B = [0 0; 1/J 0; 0 1/L];
Bt = B(:, 1);
Bv = B(:, 2);
C = [0 1 0];
D = [0 0];

motor = ss(A, B, C, D, 'InputName', {'t', 'V'}, 'OutputName', 'a', 'StateName', {'a', 'w', 'i'});
g = dcgain(motor);
si = stepinfo(motor, 'RiseTimeThreshold',[0.10 0.90]);

palette = ["#79addc" "#ffc09f" "#ffee93" "#fcf5c7" "#adf7b6"];

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica')

[y, t] = step(motor(1)/g(1), 4);
hold on;
s1 = plot(t, y, 'Color', palette(1), 'LineWidth', 2);
rt11 = interp1(y, t, 0.1);
rt21 = interp1(y, t, 0.9);
[y, t] = step(motor(2)/g(2), 4);
s2 = plot(t, y, 'Color', palette(2), 'LineWidth', 2);
rt12 = interp1(y, t, 0.1);
rt22 = interp1(y, t, 0.9);

% Extra markers
plot([rt11, rt11], [0, 0.9], '-.', 'Color', 'black')
plot([0, rt21], [0.1, 0.1], '-.', 'Color', 'black')
plot([rt21, rt21], [0, 0.9], '-.', 'Color', 'black')
plot([0, rt21], [0.9, 0.9], '-.', 'Color', 'black')
plot([rt12, rt12], [0, 0.9], '-.', 'Color', 'black')
plot([0, rt22], [0.1, 0.1], '-.', 'Color', 'black')
plot([rt22, rt22], [0, 0.9], '-.', 'Color', 'black')
plot([0, rt22], [0.9, 0.9], '-.', 'Color', 'black')
plot(rt11, 0.1, 'o', 'MarkerFaceColor', palette(1), 'MarkerEdgeColor', palette(1), 'MarkerSize', 10)
plot(rt21, 0.9, 'o', 'MarkerFaceColor', palette(1), 'MarkerEdgeColor', palette(1), 'MarkerSize', 10)
plot(rt12, 0.1, 'o', 'MarkerFaceColor', palette(2), 'MarkerEdgeColor', palette(2), 'MarkerSize', 10)
plot(rt22, 0.9, 'o', 'MarkerFaceColor', palette(2), 'MarkerEdgeColor', palette(2), 'MarkerSize', 10)
yline(1, '-.')
ylim([0 1.1])

xlabel('Id\H o $[s]$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('Sz\"ogsebess\''eg $\left[\frac{rad}{s}\right]$', 'Interpreter', 'latex', 'FontSize', 16)

hLegend = legend([s1, s2], ...
    'Nyomaték-szögsebesség', 'Feszültség-szögsebesség', ...
    'Location', 'southeast', 'FontSize', 10);
legend boxoff;
set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], 'YTick', 0:0.1:1.2, ...
    'LineWidth', 1)

set(gcf,'PaperPositionMode','auto')
export_fig("step_response.png", "-png", "-m4", "-r300")