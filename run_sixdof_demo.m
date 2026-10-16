function result=run_sixdof_demo(engine,outputRoot)
startup_project; root=fileparts(mfilename('fullpath'));
if nargin<1, engine="Simulink"; end
if nargin<2, outputRoot=fullfile(root,'outputs'); end
engine=string(engine); assert(ismember(engine,["MATLAB","Simulink"]),'rocketlab:Engine','Choose MATLAB or Simulink.');
folder=rocketlab.unique_run(outputRoot,'sixdof_structure'); p=rocketlab.sixdof_demo_config;
manifest=struct('status',"running",'kind',"synthetic_sixdof_structure",'engine',engine, ...
 'codeHash',rocketlab.code_hash(root),'inputHash',rocketlab.hash(jsonencode(p)),'matlab',version,'scope',p.scope, ...
 'timeUTC',string(datetime('now','TimeZone','UTC')));
rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
try
 comparison=[]; modelPath="";
 if engine=="Simulink", [comparison,h]=compare_sixdof_model(p,folder); modelPath=comparison.modelPath;
 else, h=rocketlab.simulate_sixdof(p); end
 summary=rocketlab.sixdof_structure_summary(h);
 c=rocketlab.sixdof_load_case(h,summary.maxBendingSampleIndex); structure=run_case(p.vehicle,c,folder);
 writetable(rocketlab.sixdof_history_table(h),fullfile(folder,'flight_history.csv'));
 writetable(summary.events,fullfile(folder,'event_peaks.csv'));
 writetable(summary.history,fullfile(folder,'postburn_load_history.csv'));
 writetable(summary.envelope,fullfile(folder,'postburn_envelope.csv'));
 rocketlab.write_json(fullfile(folder,'parameters.json'),p);
 result=struct('outputFolder',string(folder),'engine',engine,'flight',h,'vehicle',p.vehicle, ...
 'summary',summary,'comparison',comparison,'modelPath',modelPath,'structure',structure);
 save(fullfile(folder,'pipeline.mat'),'result');
 manifest.status="complete"; manifest.wholeVehicleStatus="not_evaluated";
 manifest.samplesEvaluated=summary.samplesEvaluated; manifest.excludedSamples=summary.excludedSamples;
 manifest.maxForceResidual_N=summary.maxForceResidual_N; manifest.maxMomentResidual_Nm=summary.maxMomentResidual_Nm;
 manifest.structuralReport=string(fullfile(structure.outputFolder,'report.html')); manifest.modelPath=modelPath;
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
catch e
 manifest.status="failed"; manifest.errorIdentifier=string(e.identifier); manifest.errorMessage=string(e.message);
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest); rethrow(e)
end
end
