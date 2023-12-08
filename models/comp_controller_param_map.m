J = 1;
pmin = -25;

Mmax = -0.1*J*pmin;

% m = linspace(1,10);
% b = linspace(1,10);
% [M,B] = meshgrid(m,b);
% P = B/M;
% contour(M,B,P,'ShowText','on')

m = linspace(0,3*J, 1000);
p = linspace(0,-30, 1000);
[M,P] = meshgrid(m,p);
B = -8*P.*M*0.05;
p1 = -10*m/J;
B(P > p1) = nan;
B(P < pmin) = nan;

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');
p2 = pmin*ones([1, length(m)]);
p2(p2 > p1) = nan;
p1(p1 < pmin) = nan;

hold on;
plot(m, p2, 'LineWidth', 2, 'Color', 'black');
plot(m, p1, 'LineWidth', 2, 'Color', 'black');
xline(Mmax, '--', 'Alpha', 0.5)

colormap("summer")
[M, c] = contourf(M,P,B,horzcat(J, linspace(0, 24*J, 11)),'ShowText',true);
c.LineWidth = 2;
c.FaceAlpha = 0.5;
clabel(M,c, 'FontSize', 12)

text(J,pmin-1,"$p_\mathrm{min} = " + pmin + "$", 'Interpreter','latex', 'FontSize', 16, 'HorizontalAlignment','center')
text(2*J,pmin/2,"$p_\mathrm{max} = -10 \cdot \frac{M_\mathrm{e}}{J}$", 'Interpreter','latex', 'FontSize', 16, 'HorizontalAlignment','center', 'VerticalAlignment','top')


xlabel('$\frac{M_\mathrm{e}}{J}~\mathrm{[-]}$', 'Interpreter', 'latex', 'FontSize', 16)
ylabel('$p~\mathrm{[rad \cdot s^{-1}]}$', 'Interpreter', 'latex', 'FontSize', 16)

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

set(gcf,'PaperPositionMode','auto')
export_fig("images/observer_controller_param_limits.png", "-png", "-m4", "-r300")

