function [comparison,h]=compare_sixdof_model(p,outputRoot)
startup_project; root=fileparts(mfilename('fullpath'));
if nargin<1, p=rocketlab.sixdof_demo_config; end
if nargin<2, outputRoot=fullfile(root,'outputs'); end
p=rocketlab.validate_sixdof(p); path=build_sixdof_model(p,outputRoot); [folder,name]=fileparts(path);
manifest=jsondecode(fileread(fullfile(folder,'manifest.json'))); manifest.status="running";
rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
try
 load_system(path); cleanup=onCleanup(@()close_system(name,0));
 out=sim(name); series=out.stateHistory; save(fullfile(folder,'raw_simulink.mat'),'series');
 h=rocketlab.sixdof_history(p,series.Time,series.Data,"Simulink");
 ref=rocketlab.simulate_sixdof(p); save(fullfile(folder,'flight_histories.mat'),'h','ref');
 writetable(rocketlab.sixdof_history_table(h),fullfile(folder,'simulink_history.csv'));
 writetable(rocketlab.sixdof_history_table(ref),fullfile(folder,'matlab_history.csv'));
 comparison=rocketlab.compare_sixdof_histories(ref,h); comparison.outputFolder=string(folder); comparison.modelPath=string(path);
 rocketlab.write_json(fullfile(folder,'comparison.json'),comparison);
 assert(comparison.passed,'rocketlab:FlightMismatch','Native 6DOF and MATLAB differ; raw histories and diagnostics have been saved.');
 f=figure('Visible','off'); clean=onCleanup(@()close(f)); tiledlayout(2,2);
 nexttile; plot(ref.time_s,ref.altitude_m,'-',h.time_s,h.altitude_m,'--'); ylabel('Altitude [m]'); legend('MATLAB','Simulink'); grid on;
 nexttile; plot(ref.time_s,ref.state(:,11:13),'-'); hold on; plot(h.time_s,h.state(:,11:13),'--'); ylabel('Body angular rate [rad/s]'); grid on;
 nexttile; plot(h.time_s,[h.alpha_rad,h.beta_rad]*180/pi); ylabel('Air angles [deg]'); xlabel('Time [s]'); legend('alpha','beta'); grid on;
 nexttile; plot(h.time_s,h.quaternionNorm-1); ylabel('Quaternion norm - 1'); xlabel('Time [s]'); grid on;
 exportgraphics(f,fullfile(folder,'comparison.png'),'Resolution',150);
 print(['-s' name],'-dpng',fullfile(folder,'model_diagram.png'));
 manifest.status="complete"; manifest.comparisonPassed=true; rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
catch e
 manifest.status="failed"; manifest.errorIdentifier=string(e.identifier); manifest.errorMessage=string(e.message);
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest); rethrow(e)
end
end
