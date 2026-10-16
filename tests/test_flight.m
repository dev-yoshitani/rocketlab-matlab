function tests=test_flight
tests=functiontests(localfunctions);
end
function setupOnce(~)
startup_project;
end
function testApogeeAndMass(t)
p=rocketlab.flight_demo_config; h=rocketlab.simulate_vertical(p);
t.verifyGreaterThan(h.apogee_s,p.time(end)); t.verifyLessThan(abs(h.velocity_m_s(end)),1e-6);
t.verifyEqual(h.mass_kg(end),p.dryMass,'AbsTol',1e-7);
t.verifyTrue(all(h.thrust_N(h.time_s>=p.time(end))==0));
t.verifyGreaterThan(max(h.altitude_m),0);
end
function testAeroBoundary(t)
p=rocketlab.flight_demo_config;
rocketlab.vertical_rhs(0,[0;p.soundSpeed*p.mach(end);2],p);
t.verifyError(@()rocketlab.vertical_rhs(0,[0;p.soundSpeed*(p.mach(end)+1e-8);2],p),'rocketlab:AeroRange');
p.dryMass=1; t.verifyError(@()rocketlab.validate_flight(p),'rocketlab:MassFlow');
end
function testConvergence(t)
p=rocketlab.flight_demo_config; a=rocketlab.simulate_vertical(p); p.maxStep=p.maxStep/2; b=rocketlab.simulate_vertical(p);
t.verifyLessThan(abs(a.apogee_s-b.apogee_s),1e-4);
t.verifyLessThan(abs(a.altitude_m(end)-b.altitude_m(end)),1e-3);
end
function testSimulinkCapability(t)
env=startup_project;
if ~env.simulink
 t.verifyError(@()build_flight_model,'rocketlab:SimulinkUnavailable');
else
 [~,token]=fileparts(tempname); probe=matlab.lang.makeValidName(['user_' token]);
 new_system(probe); cleanup=onCleanup(@()close_system(probe,0)); set_param(probe,'StopTime','13');
 dirty=get_param(probe,'Dirty');
 [r,h]=compare_flight_model; t.verifyEqual(h.mass_kg(end),h.parameters.dryMass,'AbsTol',5e-9); t.verifyTrue(r.passed); t.verifyTrue(isfile(r.modelPath));
 t.verifyTrue(bdIsLoaded(probe)); t.verifyEqual(get_param(probe,'Dirty'),dirty);
 manifest=jsondecode(fileread(fullfile(r.outputFolder,'manifest.json')));
 t.verifyEqual(string(manifest.status),"complete");
end
end

function testChangedThrustAndBurnout(t)
env=startup_project; t.assumeTrue(env.simulink,'Simulink is unavailable.');
p=rocketlab.flight_demo_config; p.thrust=p.thrust*.8;
[r,h]=compare_flight_model(p);
t.verifyTrue(r.passed); t.verifyEqual(h.mass_kg(end),p.dryMass,'AbsTol',5e-9);
consumed=zeros(size(h.time_s));
for k=1:numel(p.time)-1
 dt=max(0,min(h.time_s,p.time(k+1))-p.time(k));
 slope=(p.massFlow(k+1)-p.massFlow(k))/(p.time(k+1)-p.time(k));
 consumed=consumed+p.massFlow(k)*dt+.5*slope*dt.^2;
end
t.verifyLessThan(max(abs(h.mass_kg-(p.initial(3)-consumed))),5e-9);
for knot=p.time(2:end)', t.verifyLessThan(min(abs(h.time_s-knot)),1e-8); end
t.verifyTrue(all(h.thrust_N(h.time_s>=p.time(end))==0));
t.verifyLessThan(h.altitude_m(end),741);
end
function testFailedRunKeepsEvidence(t)
env=startup_project; t.assumeTrue(env.simulink,'Simulink is unavailable.');
root=fileparts(fileparts(mfilename('fullpath'))); folder=rocketlab.unique_run(fullfile(root,'work'),'missing-apogee');
p=rocketlab.flight_demo_config; p.maxTime=2.1;
t.verifyError(@()compare_flight_model(p,folder),'rocketlab:MissingApogee');
files=dir(fullfile(folder,'simulink_*','manifest.json')); t.verifyNumElements(files,1);
manifest=jsondecode(fileread(fullfile(files(1).folder,files(1).name)));
t.verifyEqual(string(manifest.status),"failed");
t.verifyTrue(isfile(fullfile(files(1).folder,'raw_simulink.mat')));
end
