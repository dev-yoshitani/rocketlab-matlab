function tests=test_sixdof_native
tests=functiontests(localfunctions);
end
function setupOnce(t)
env=startup_project; t.assumeTrue(env.simulink&&~isempty(which('aerolib6dof2')),'Aerospace Blockset unavailable.');
end
function testNativeVariableInertiaConservation(t)
p=rocketlab.sixdof_demo_config; p.rho0_kg_m3=0; p.g_m_s2=0; p.angularDamping_Nms=zeros(3,1);
p.thrust_N(:)=0; p.position0_NED_m=[0;0;-1000]; p.omega0_body_rad_s=[.3;.2;.4];
p.propellantInertiaPerKg_S_m2=diag([.3,.4,.5]); p.stopTime_s=2.3;
[r,h]=compare_sixdof_model(p); t.verifyTrue(r.passed);
L=zeros(numel(h.time_s),3);
for k=1:numel(h.time_s)
 a=rocketlab.sixdof_propulsion(h.time_s(k),h.parameters);
 L(k,:)=(rocketlab.quat_rotation(h.state(k,7:10))*a.I_B*h.state(k,11:13)')';
end
t.verifyLessThan(max(vecnorm(L-L(1,:),2,2)),1e-8);
t.verifyLessThan(abs(h.mass_kg(end)-p.dryMass_kg),1e-12);
for knot=p.time_s(2:end)', t.verifyLessThan(min(abs(h.time_s-knot)),1e-8); end
end
function testNativeBallisticAndExistingModel(t)
p=rocketlab.sixdof_demo_config; p.rho0_kg_m3=0; p.angularDamping_Nms=zeros(3,1);
p.thrust_N(:)=0; p.massFlow_kg_s(:)=0; p.omega0_body_rad_s=zeros(3,1); p.stopTime_s=.3;
[~,token]=fileparts(tempname); name=matlab.lang.makeValidName(['user_' token]);
new_system(name); cleanup=onCleanup(@()close_system(name,0)); set_param(name,'StopTime','17'); dirty=get_param(name,'Dirty');
[r,h]=compare_sixdof_model(p); t.verifyTrue(r.passed);
expected=p.initialState(1:3)'+h.time_s.*p.initialState(4:6)'+.5*h.time_s.^2.*[0,0,p.g_m_s2];
t.verifyEqual(h.state(:,1:3),expected,'AbsTol',1e-8);
t.verifyTrue(bdIsLoaded(name)); t.verifyEqual(get_param(name,'Dirty'),dirty); t.verifyEqual(get_param(name,'StopTime'),'17');
end
