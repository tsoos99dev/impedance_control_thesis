td = 0.25;
t = 0:0.001:1+td/2;

palette = ["#79addc" "#ffc09f" "#ffee93" "#fcf5c7" "#adf7b6"];

figure;
pbaspect([8,6,1])
set(gcf,'color','w');
set(gca, 'FontName', 'Helvetica');

hold on;

f = td*1/2*(sawtooth(t*2*pi/td)+1)+td;
plot(t, f, 'Color', palette(1), 'LineWidth', 2)

yline(td, '--', 'Alpha', 0.8)
yline(3/2*td, '--', 'Alpha', 0.8)
yline(2*td, '--', 'Alpha', 0.8)
xlim([0 t(end)]);
ylim([0 0.75]);

xlabel('Id\H o', 'Interpreter', 'latex', 'FontSize', 16)
ylabel("Id\H ok\'e\'es", 'Interpreter', 'latex', 'FontSize', 16)

xticks([td, 2*td, 3*td, 4*td])
xticklabels({'\tau_{\rm{d}}', '2\tau_{\rm{d}}'})

yticks([td, 2*td])
yticklabels({'\tau_{\rm{d}}', '2\tau_{\rm{d}}'})


% legend('Szögelfordulás', 'Szabályozó jel', 'Location', 'southeast', 'FontSize', 10)
% legend boxoff;

set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], ...
    'LineWidth', 1)

set(gcf,'PaperPositionMode','auto')
export_fig("images/delay_zoh_example_discrete.png", "-png", "-m4", "-r300")