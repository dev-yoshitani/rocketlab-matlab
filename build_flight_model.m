function modelPath=build_flight_model(parameters,outputRoot)
root=fileparts(mfilename('fullpath')); env=startup_project();
assert(env.simulink && ~isempty(which('new_system')),'rocketlab:SimulinkUnavailable','Simulink is not installed. Model generation was not run.');
if nargin<1, parameters=rocketlab.flight_demo_config; end
if nargin<2, outputRoot=fullfile(root,'outputs'); end
p=rocketlab.validate_flight(parameters); folder=rocketlab.unique_run(outputRoot,'simulink');
manifest=struct('status',"running",'kind',"simulink_generation",'matlab',version, ...
 'codeHash',rocketlab.code_hash(root),'inputHash',rocketlab.hash(jsonencode(p)), ...
 'timeUTC',string(datetime('now','TimeZone','UTC')));
rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
try
 [~,token]=fileparts(tempname); name=matlab.lang.makeValidName(['rocketlab_' token]);
 assert(~bdIsLoaded(name),'rocketlab:ModelExists','Model name is already open.');
 new_system(name); cleanup=onCleanup(@()close_system(name,0));
 set_param(name,'Solver','ode45','StartTime','0','StopTime',num2str(p.maxTime,17), ...
  'RelTol',num2str(p.relTol,17),'AbsTol',num2str(p.absTol,17), ...
  'MaxStep',num2str(p.maxStep,17),'ReturnWorkspaceOutputs','on');
 workspace=get_param(name,'ModelWorkspace'); assignin(workspace,'flightParameters',p);
 add_block('simulink/User-Defined Functions/Level-2 MATLAB S-Function',[name '/Flight'], ...
  'FunctionName','rocketlab_vertical_sfun','Parameters','flightParameters','Position',[40 100 200 160]);
 add_block('simulink/Signal Routing/Demux',[name '/States'],'Outputs','3','Position',[250 90 255 170]);
 add_block('simulink/Sinks/To Workspace',[name '/History'],'VariableName','stateHistory','SaveFormat','Timeseries', ...
  'MaxDataPoints','inf','Decimation','1','Position',[270 250 390 290]);
 % Built-in type avoids a release-dependent line break in the library block name.
 add_block('built-in/HitCross',[name '/FallingVelocity'], ...
  'HitCrossingOffset','0','HitCrossingDirection','falling','ShowOutputPort','on', ...
  'HitCrossingOutputType','Signal','ZeroCross','on','Position',[335 125 425 155]);
 add_block('simulink/Logic and Bit Operations/Compare To Constant',[name '/Airborne'], ...
  'relop','>','const','1e-8','Position',[335 35 425 65]);
 add_block('simulink/Logic and Bit Operations/Logical Operator',[name '/Apogee'], ...
  'Operator','AND','Inputs','2','Position',[475 60 530 125]);
 add_block('simulink/Sinks/Stop Simulation',[name '/StopAtApogee'],'Position',[590 75 675 110]);
 add_block('simulink/Sinks/Terminator',[name '/MassMonitor'],'Position',[335 195 355 215]);
 add_line(name,'Flight/1','States/1','autorouting','on'); add_line(name,'Flight/1','History/1','autorouting','on');
 add_line(name,'States/1','Airborne/1','autorouting','on'); add_line(name,'States/2','FallingVelocity/1','autorouting','on'); add_line(name,'States/3','MassMonitor/1','autorouting','on');
 add_line(name,'Airborne/1','Apogee/1','autorouting','on'); add_line(name,'FallingVelocity/1','Apogee/2','autorouting','on'); add_line(name,'Apogee/1','StopAtApogee/1','autorouting','on');
 % Force solver visits to every continuous propulsion interpolation knot.
 % The reference ODE also restarts at these knots; no state or mass is reset.
 add_block('simulink/Sources/Clock',[name '/PropulsionTime'],'Position',[40 345 70 375]);
 for k=2:numel(p.time)
  block=[name '/PropulsionKnot' num2str(k-1)];
  add_block('built-in/HitCross',block,'HitCrossingOffset',num2str(p.time(k),17), ...
   'HitCrossingDirection','rising','ShowOutputPort','off','ZeroCross','on', ...
   'Position',[140+(k-2)*145,340,250+(k-2)*145,380]);
  add_line(name,'PropulsionTime/1',['PropulsionKnot' num2str(k-1) '/1'],'autorouting','on');
 end
 set_param(name,'SimulationCommand','update');
 modelPath=fullfile(folder,[name '.slx']); save_system(name,modelPath);
 rocketlab.write_json(fullfile(folder,'parameters.json'),p);
 manifest.status="model_generated"; manifest.diagramUpdated=true;
 manifest.modelFile=string([name '.slx']); manifest.modelSHA256=rocketlab.hash(modelPath,true);
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
catch e
 manifest.status="failed"; manifest.errorIdentifier=string(e.identifier); manifest.errorMessage=string(e.message);
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest); rethrow(e)
end
end
