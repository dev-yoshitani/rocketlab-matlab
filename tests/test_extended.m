function tests=test_extended
tests=functiontests(localfunctions);
end
function setupOnce(~)
startup_project;
end
function v=uniform()
[v,~]=rocketlab.demo_config; v.members=v.members(1,:); v.members.s1=1; v.joints=v.joints([],:);
end
function testCantileverModes(t)
v=uniform; v=rocketlab.validate_vehicle(v);
r=rocketlab.beam_modes(v,"cantilever",24);
expected=1.87510406871196^2/(2*pi)*sqrt(v.members.EI/(v.members.density*v.members.A));
t.verifyEqual(r.rigidModeCount,0); t.verifyEqual(r.frequency_Hz(1),expected,'RelTol',.001);
end
function testFreeModes(t)
v=uniform; v=rocketlab.validate_vehicle(v);
r=rocketlab.beam_modes(v,"free",24);
expected=4.7300407448627^2/(2*pi)*sqrt(v.members.EI/(v.members.density*v.members.A));
t.verifyEqual(r.rigidModeCount,2); t.verifyEqual(r.frequency_Hz(1),expected,'RelTol',.001);
end
function testSymmetricLaminate(t)
plies=repmat([.001,0,140e9,10e9,5e9,.3],4,1); plies(:,2)=[0;pi/2;pi/2;0];
a=rocketlab.laminate_abd(plies); t.verifyLessThan(norm(a.B),1e-7);
t.verifyGreaterThan(min(eig(a.ABD)),0); t.verifyEqual(a.A(1,1),a.A(2,2),'RelTol',1e-12);
end
function testIsotropicLaminate(t)
E=70e9; nu=.3; G=E/(2*(1+nu));
a=rocketlab.laminate_abd([.001,0,E,E,G,nu]); b=rocketlab.laminate_abd([.001,.37,E,E,G,nu]);
t.verifyEqual(a.A,b.A,'AbsTol',1e-6);
end
function testEuler(t)
r=rocketlab.euler_column(1,1,1,"pinned ends"); t.verifyEqual(r.criticalLoad_N,pi^2,'AbsTol',1e-12);
t.verifyError(@()rocketlab.euler_column(1,1,1,""),'rocketlab:BoundaryBasis');
end
function testJointTest(t)
r=rocketlab.joint_test_fit((0:4)'*.001,(0:4)'*10,1:5,"synthetic linear interval");
t.verifyEqual(r.axialStiffness_N_m,10000,'RelTol',1e-12); t.verifyTrue(isnan(r.rotationalStiffness_Nm_rad));
end
function testWind(t)
a=rocketlab.relative_flow([100,0,0],[0,0,10],1.2,340,"snapshot");
t.verifyEqual(a.q_Pa,.5*1.2*10100,'AbsTol',1e-10);
t.verifyEqual(a.mach,sqrt(10100)/340,'AbsTol',1e-12);
t.verifyError(@()rocketlab.relative_flow([100,0,0],[0,0,10],1.2,340,"replay"),'rocketlab:ReplayWind');
end
function testEnvelope(t)
[v,c]=rocketlab.demo_config; root=fileparts(fileparts(mfilename('fullpath')));
r=rocketlab.load_envelope(v,[1;2;3],@loads,fullfile(root,'work'));
t.verifyEqual(r.progress.status,"complete");
t.verifyEqual(max(abs(r.maximum(:,1))),1500,'AbsTol',1e-8);
cancel=rocketlab.load_envelope(v,[1;2],@loads,fullfile(root,'work'),@()true);
t.verifyEqual(cancel.progress.status,"cancelled"); t.verifyEqual(cancel.progress.samplesCompleted,0);
 function x=loads(k,time)
  x=c; x.time_s=time;
  names={'Fx','Fy','Fz','Mx','My','Mz'}; x.points{:,names}=c.points{:,names}*k;
 end
end

function testFemRoundTripAndStale(t)
root=fileparts(fileparts(mfilename('fullpath'))); folder=rocketlab.unique_run(fullfile(root,'work'),'fem-test');
geometry=fullfile(folder,'dummy.step'); fid=fopen(geometry,'w'); fprintf(fid,'TEST FIXTURE, NOT A VALIDATED CAD MODEL'); fclose(fid);
packet=struct('configurationId',"synthetic",'geometryFile',geometry,'units',"SI",'materials',struct('E',1), ...
 'materialAxes',eye(3),'loadSurfaces',"face1",'supports',"face2",'analysisType',"static",'source',"test only");
exchange=fullfile(folder,'exchange'); packet=rocketlab.fem_exchange("export",packet,exchange);
result=struct('configurationId',packet.configurationId,'inputHash',packet.inputHash,'solverVersion',"fixture", ...
 'mesh',1,'convergence',false,'reactions',[0,0,0],'displacement',0,'evaluationLocations',0,'stress',0);
rocketlab.write_json(fullfile(exchange,'result.json'),result);
r=rocketlab.fem_exchange("import",packet,exchange); t.verifyEqual(r.verificationStatus,"external_result_requires_review");
result.inputHash="wrong"; rocketlab.write_json(fullfile(exchange,'result.json'),result);
t.verifyError(@()rocketlab.fem_exchange("import",packet,exchange),'rocketlab:StaleFEM');
end
function testRecoveryLimits(t)
T=table([0;1;2],[0;100;400],[0;10;20],ones(3,1),'VariableNames',{'time_s','q_Pa','speed_m_s','segment'});
h=struct('normalized',T); r=rocketlab.recovery_sensitivity(h,1,[0;1;2],1,2,1.5,"synthetic factor");
t.verifyEqual(r.equivalentOpeningForce_N(1:2),[300;1200]); t.verifyEqual(r.status(3),"outside_data");
end
