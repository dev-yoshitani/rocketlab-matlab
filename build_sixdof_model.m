function modelPath=build_sixdof_model(parameters,outputRoot)
root=fileparts(mfilename('fullpath')); env=startup_project;
assert(env.simulink&&~isempty(which('aerolib6dof2')),'rocketlab:AerospaceUnavailable','Simulink and Aerospace Blockset are required.');
if nargin<1, parameters=rocketlab.sixdof_demo_config; end
if nargin<2, outputRoot=fullfile(root,'outputs'); end
p=rocketlab.validate_sixdof(parameters); folder=rocketlab.unique_run(outputRoot,'sixdof_simulink');
manifest=struct('status',"running",'kind',"native_aerospace_sixdof",'matlab',version, ...
 'codeHash',rocketlab.code_hash(root),'inputHash',rocketlab.hash(jsonencode(p)),'scope',p.scope, ...
 'timeUTC',string(datetime('now','TimeZone','UTC')));
rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
try
 [~,token]=fileparts(tempname); name=matlab.lang.makeValidName(['rocketlab6_' token]);
 assert(~bdIsLoaded(name),'rocketlab:ModelExists','Model name is already open.');
 new_system(name); cleanup=onCleanup(@()close_system(name,0));
 set_param(name,'Solver','ode45','StartTime','0','StopTime',num2str(p.stopTime_s,17), ...
 'RelTol',num2str(p.relTol,17),'AbsTol',num2str(p.absTol,17),'MaxStep',num2str(p.maxStep_s,17),'ReturnWorkspaceOutputs','on');
 workspace=get_param(name,'ModelWorkspace'); assignin(workspace,'sixdofParameters',p);
 load_system('aerolib6dof2');
 add_block('aerolib6dof2/Custom Variable Mass 6DOF (Quaternion)',[name '/RigidBody'], ...
  'units','Metric (MKS)','mtype','Custom Variable','vre_flag','off', ...
  'xme_0','sixdofParameters.position0_NED_m','Vm_0','sixdofParameters.velocity0_body_m_s', ...
  'eul_0','sixdofParameters.euler0_rad','pm_0','sixdofParameters.omega0_body_rad_s', ...
  'Position',[420,100,660,350]);
 add_block('simulink/User-Defined Functions/Level-2 MATLAB S-Function',[name '/AppliedLoads'], ...
  'FunctionName','rocketlab_sixdof_forces_sfun','Parameters','sixdofParameters','Position',[130,100,290,350]);
 add_block('simulink/Signal Routing/Mux',[name '/States'],'Inputs','4','Position',[780,100,785,320]);
 add_block('simulink/Sinks/To Workspace',[name '/History'],'VariableName','stateHistory','SaveFormat','Timeseries', ...
  'MaxDataPoints','inf','Decimation','1','Position',[885,120,1020,160]);
 % Native output ports: Ve, Xe, Euler, quaternion, DCMbe, Vb, omega.
 ports=[2,1,4,7];
 for k=1:4, add_line(name,['RigidBody/' num2str(ports(k))],['States/' num2str(k)],'autorouting','on'); end
 for k=1:5, add_line(name,['AppliedLoads/' num2str(k)],['RigidBody/' num2str(k)],'autorouting','on'); end
 for k=[3,5,6]
  add_block('simulink/Sinks/Terminator',[name '/Unused' num2str(k)],'Position',[710,370+30*k,730,390+30*k]);
  add_line(name,['RigidBody/' num2str(k)],['Unused' num2str(k) '/1'],'autorouting','on');
 end
 add_line(name,'States/1','AppliedLoads/1','autorouting','on'); add_line(name,'States/1','History/1','autorouting','on');
 add_block('simulink/Sources/Clock',[name '/PropulsionTime'],'Position',[100,430,130,460]);
 for k=2:numel(p.time_s)
  b=['PropulsionKnot' num2str(k-1)];
  add_block('built-in/HitCross',[name '/' b],'HitCrossingOffset',num2str(p.time_s(k),17), ...
   'HitCrossingDirection','rising','ShowOutputPort','off','ZeroCross','on','Position',[180+145*(k-2),420,290+145*(k-2),470]);
  add_line(name,'PropulsionTime/1',[b '/1'],'autorouting','on');
 end
 set_param(name,'SimulationCommand','update');
 modelPath=fullfile(folder,[name '.slx']); save_system(name,modelPath);
 rocketlab.write_json(fullfile(folder,'parameters.json'),p);
 manifest.status="model_generated"; manifest.modelFile=string([name '.slx']); manifest.modelSHA256=rocketlab.hash(modelPath,true);
 manifest.nativeBlockType=string(get_param([name '/RigidBody'],'BlockType'));
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
catch e
 manifest.status="failed"; manifest.errorIdentifier=string(e.identifier); manifest.errorMessage=string(e.message);
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest); rethrow(e)
end
end
