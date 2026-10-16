function result = run_case(vehicle,loadCase,outputRoot)
root=fileparts(mfilename('fullpath')); startup_project();
if nargin<3, outputRoot=fullfile(root,'outputs'); end
if ischar(vehicle)||isstring(vehicle), vehicle=jsondecode(fileread(vehicle)); end
if ischar(loadCase)||isstring(loadCase), loadCase=jsondecode(fileread(loadCase)); end
folder=rocketlab.unique_run(outputRoot,'case');
manifest=struct('runId',string(folder),'started',string(datetime('now','TimeZone','UTC')), ...
 'status',"running",'inputHash',rocketlab.hash(jsonencode(struct('vehicle',vehicle,'loadCase',loadCase))), ...
 'matlab',version,'release',version('-release'),'seed',[],'modelVersion',"0.1.0");
manifest.codeHash=rocketlab.code_hash(root);
rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
try
 result=rocketlab.analyze_case(vehicle,loadCase); result.outputFolder=folder;
 manifest.normalizedInputHash=rocketlab.hash(jsonencode(struct('vehicle',result.vehicle,'loadCase',result.loadCase)));
 result.manifest=manifest;
 save(fullfile(folder,'result.mat'),'result');
 export_report(result,folder);
 manifest.status="complete"; manifest.finished=string(datetime('now','TimeZone','UTC'));
 items=dir(folder); items=items(~[items.isdir]); manifest.outputs=string({items.name});
 result.manifest=manifest; save(fullfile(folder,'result.mat'),'result');
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
catch e
 manifest.status="failed"; manifest.errorIdentifier=string(e.identifier); manifest.errorMessage=string(e.message);
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest); rethrow(e)
end
end
