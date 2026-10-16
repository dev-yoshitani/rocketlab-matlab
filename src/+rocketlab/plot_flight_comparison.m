function plot_flight_comparison(ref,flight,folder)
f=figure('Visible','off','Color','w','Position',[60,60,1100,800]);
cleanup=onCleanup(@()close(f)); tiledlayout(f,2,2,'Padding','compact');
fields={'altitude_m','velocity_m_s','mass_kg','q_Pa'}; labels={'Altitude [m]','Upward velocity [m/s]','Mass [kg]','Dynamic pressure [Pa]'};
for k=1:4
 ax=nexttile; plot(ax,ref.time_s,ref.(fields{k}),'LineWidth',1.5); hold(ax,'on');
 plot(ax,flight.time_s,flight.(fields{k}),'--','LineWidth',1.2);
 xlabel(ax,'Time [s]'); ylabel(ax,labels{k}); grid(ax,'on'); legend(ax,'MATLAB','Simulink','Location','best');
 ax.Color='w'; ax.XColor=[.1,.15,.2]; ax.YColor=ax.XColor;
 ax.XLabel.Color=ax.XColor; ax.YLabel.Color=ax.XColor; ax.Legend.Color='w'; ax.Legend.TextColor=ax.XColor;
end
exportgraphics(f,fullfile(folder,'flight_comparison.png'),'Resolution',150,'BackgroundColor','white');
print(f,fullfile(folder,'flight_comparison.svg'),'-dsvg');
end
