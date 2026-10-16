function result=run_flight_structure_demo(engine,outputRoot)
% Verified synthetic one-way handoff: vertical flight -> same-time axial loads.
startup_project(); root=fileparts(mfilename('fullpath'));
if nargin<1, engine="Simulink"; end
if nargin<2, outputRoot=fullfile(root,'outputs'); end
engine=string(engine); assert(ismember(engine,["MATLAB","Simulink"]),'rocketlab:Engine','Choose MATLAB or Simulink.');
folder=rocketlab.unique_run(outputRoot,'flight_structure'); p=rocketlab.flight_demo_config;
manifest=struct('status',"running",'kind',"synthetic_flight_structure",'engine',engine, ...
 'codeHash',rocketlab.code_hash(root),'inputHash',rocketlab.hash(jsonencode(p)),'matlab',version, ...
 'timeUTC',string(datetime('now','TimeZone','UTC')));
rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
try
 comparison=[]; modelPath="";
 if engine=="Simulink"
  [comparison,h]=compare_flight_model(p,folder); modelPath=comparison.modelPath;
 else
  h=rocketlab.simulate_vertical(p);
 end
 [v,d]=rocketlab.flight_structure_demo(p); summary=rocketlab.flight_structure_summary(h,v,d);
 c=rocketlab.vertical_load_case(h,summary.maxAxialSampleIndex,d,v.length);
 structure=run_case(v,c,folder);
 writetable(summary.events,fullfile(folder,'event_peaks.csv'));
 writetable(summary.history,fullfile(folder,'axial_load_history.csv'));
 rocketlab.write_json(fullfile(folder,'load_distribution.json'),d);
 result=struct('outputFolder',string(folder),'engine',engine,'flight',h,'vehicle',v, ...
  'distribution',d,'summary',summary,'comparison',comparison,'modelPath',modelPath,'structure',structure);
 save(fullfile(folder,'pipeline.mat'),'result');
 manifest.status="complete"; manifest.wholeVehicleStatus="not_evaluated";
 manifest.samplesEvaluated=summary.samplesEvaluated; manifest.maxForceResidual_N=summary.maxForceResidual_N;
 manifest.structuralCaseId=structure.caseId; manifest.structuralReport=string(fullfile(structure.outputFolder,'report.html'));
 manifest.modelPath=modelPath; rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
 fprintf('Flight -> structure demo: %s\n',folder);
catch e
 manifest.status="failed"; manifest.errorIdentifier=string(e.identifier); manifest.errorMessage=string(e.message);
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest); rethrow(e)
end
end
