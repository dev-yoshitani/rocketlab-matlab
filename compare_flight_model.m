function [comparison,flight]=compare_flight_model(p,outputRoot)
startup_project();
if nargin<1, p=rocketlab.flight_demo_config; end
root=fileparts(mfilename('fullpath')); if nargin<2, outputRoot=fullfile(root,'outputs'); end
p=rocketlab.validate_flight(p); path=build_flight_model(p,outputRoot); [folder,name]=fileparts(path);
manifest=jsondecode(fileread(fullfile(folder,'manifest.json')));
manifest.status="running"; manifest.kind="matlab_simulink_comparison";
rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
try
 load_system(path); cleanup=onCleanup(@()close_system(name,0));
 in=Simulink.SimulationInput(name); in=in.setVariable('flightParameters',p,'Workspace',name);
 out=sim(in); series=out.stateHistory;
 time=series.Time; state=series.Data;
 save(fullfile(folder,'raw_simulink.mat'),'series');
 apogeeTime=NaN;
 if state(end,1)>0 && abs(state(end,2))<=1e-4 && any(state(:,2)>0) && time(end)<p.maxTime
  apogeeTime=time(end);
 end
 flight=rocketlab.vertical_history(p,time,state,apogeeTime,"Simulink");
 ref=rocketlab.simulate_vertical(p);
 save(fullfile(folder,'flight_histories.mat'),'flight','ref');
 writetable(historyTable(flight),fullfile(folder,'simulink_history.csv'));
 writetable(historyTable(ref),fullfile(folder,'matlab_history.csv'));
 comparison=rocketlab.compare_vertical_histories(ref,flight);
 comparison.outputFolder=string(folder); comparison.modelPath=string(path);
 rocketlab.write_json(fullfile(folder,'comparison.json'),comparison);
 assert(comparison.passed,'rocketlab:FlightMismatch','MATLAB/Simulink comparison failed; raw histories and diagnostics have been saved.');
 rocketlab.plot_flight_comparison(ref,flight,folder);
 print(['-s' name],'-dpng',fullfile(folder,'model_diagram.png'));
 manifest.status="complete"; manifest.comparisonPassed=true;
 manifest.completedUTC=string(datetime('now','TimeZone','UTC'));
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
 fprintf('Simulink comparison: %s\n',folder);
catch e
 manifest.status="failed"; manifest.errorIdentifier=string(e.identifier); manifest.errorMessage=string(e.message);
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest); rethrow(e)
end
end
function t=historyTable(h)
t=table(h.time_s,h.altitude_m,h.velocity_m_s,h.mass_kg,h.q_Pa,h.mach,h.thrust_N,h.drag_N,h.acceleration_m_s2,h.phase, ...
 'VariableNames',{'time_s','altitude_m','velocity_m_s','mass_kg','q_Pa','mach','thrust_N','drag_N','acceleration_m_s2','phase'});
end
