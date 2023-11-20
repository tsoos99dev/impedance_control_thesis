t = 0:0.01:pi;
td = 0.25;
tj = 1.75;

x1 = 1.2*sin(t).^2.*(1-0.8*cos(t)) + 0.7*cos(2*t);

tn = 0:td:pi;
x2 = 0.8*cos(tn).^2.*(1-0.8*cos(tn+0.7)) - 0.2*cos(2*tn);

palette = ["#79addc" "#ffc09f" "#ffee93" "#fcf5c7" "#adf7b6"];

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');

hold on;

plot(t, x1, 'Color', palette(1), 'LineWidth', 2)
stairs(tn, x2, 'Color', palette(2), 'LineWidth', 2)

aw = 0.05;
ap = 3;
ai = 0:0.01:1;
a1t = tj-td+td*ai;
x10 = interp1(t, x1, tj-td);
x11 = interp1(tn, x2, tj);
a1 = spline([tj-td tj-0.75*td tj-0.25*td tj], [x10 x10+0.2*(x11-x10) x10+0.9*(x11-x10) x11], a1t);


a2t = tj+td*ai;
x20 = interp1(t, x1, tj);
x21 = interp1(tn, x2, tj+td);
a2 = spline([tj tj+0.25*td tj+0.75*td tj+td], [x20 x20+0.2*(x21-x20) x20+0.9*(x21-x20) x21], a2t);

plot(a1t, a1, 'Color', 'black', 'LineWidth', 2)
arrowh(a1t, a1, 'black');

plot(a2t, a2, 'Color', 'black', 'LineWidth', 2)
arrowh(a2t, a2, 'black');

xline(tj-td, '--', 'Alpha', 0.8)
xline(tj, '--', 'Alpha', 0.8)
xline(tj+td, '--', 'Alpha', 0.8)
text(tj-td, 0.05, '$t_\mathrm{j} - \tau_\mathrm{d}$', 'Interpreter','latex','BackgroundColor', 'white', 'FontSize',16, 'HorizontalAlignment','center')
text(tj, 0.05, '$t_\mathrm{j}$', 'Interpreter','latex','BackgroundColor', 'white', 'FontSize',16, 'HorizontalAlignment','center')
text(tj+td, 0.05, '$t_\mathrm{j} + \tau_\mathrm{d}$', 'Interpreter','latex','BackgroundColor', 'white', 'FontSize',16, 'HorizontalAlignment','center')
xlim([0 pi]);
ylim([0 1]);

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

set(gca,'Xticklabel',[]) 
set(gca,'Yticklabel',[]) 

set(gcf,'PaperPositionMode','auto')
export_fig("images/time_delay_example.png", "-png", "-m4", "-r300")