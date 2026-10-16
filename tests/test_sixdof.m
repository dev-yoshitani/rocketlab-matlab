function tests=test_sixdof
tests=functiontests(localfunctions);
end
function setupOnce(t)
startup_project; t.TestData.p=rocketlab.sixdof_demo_config; t.TestData.h=rocketlab.simulate_sixdof(t.TestData.p);
end
function testQuaternionConvention(t)
q=[cos(pi/4);0;0;sin(pi/4)]; R=rocketlab.quat_rotation(q);
t.verifyEqual(R*[1;0;0],[0;1;0],'AbsTol',1e-14);
t.verifyEqual(R,rocketlab.quat_rotation(-q),'AbsTol',1e-14); t.verifyEqual(det(R),1,'AbsTol',1e-14);
q=rocketlab.euler_quat([0;pi/2;0]); t.verifyEqual(rocketlab.quat_rotation(q)*[1;0;0],[0;0;-1],'AbsTol',1e-14);
S=diag([-1,1,-1]); u=[1;2;3]; v=[-.5;4;-2];
t.verifyEqual(cross(S*u,S*v),S*cross(u,v),'AbsTol',1e-14);
end
function testBallisticClosedForm(t)
p=vacuum(t.TestData.p); p.stopTime_s=.4; p.g_m_s2=9.80665; h=rocketlab.simulate_sixdof(p);
v=p.initialState(4:6)'; g=[0,0,p.g_m_s2];
expected=p.position0_NED_m'+h.time_s.*v+.5*h.time_s.^2.*g;
t.verifyEqual(h.state(:,1:3),expected,'AbsTol',1e-8);
t.verifyEqual(h.state(:,4:6),v+h.time_s.*g,'AbsTol',1e-9);
end
function testTorqueFreeConservation(t)
p=vacuum(t.TestData.p); p.stopTime_s=2; p.omega0_body_rad_s=[.3;.2;.4]; h=rocketlab.simulate_sixdof(p);
[L,E]=invariants(h);
t.verifyLessThan(max(vecnorm(L-L(1,:),2,2)),1e-9);
t.verifyLessThan(max(abs(E-E(1))),1e-9);
end
function testVariableInertiaAngularMomentum(t)
p=vacuum(t.TestData.p); p.massFlow_kg_s=t.TestData.p.massFlow_kg_s; p.stopTime_s=2.3;
p.propellantInertiaPerKg_S_m2=diag([.3,.4,.5]); p.omega0_body_rad_s=[.3;.2;.4];
h=rocketlab.simulate_sixdof(p); [L,~]=invariants(h);
t.verifyLessThan(max(vecnorm(L-L(1,:),2,2)),1e-8);
t.verifyGreaterThan(norm(h.state(end,11:13)-h.state(1,11:13)),.1);
end
function testExactFlowIntegralAndMassFloor(t)
p=t.TestData.p; a=rocketlab.sixdof_propulsion(.05,p);
t.verifyEqual(a.remaining_kg,.19-.5*(.1/.1)*.05^2,'AbsTol',1e-14);
a=rocketlab.sixdof_propulsion(3,p); t.verifyEqual(a.mass_kg,1.81,'AbsTol',1e-13);
t.verifyEqual(a.Idot_B,zeros(3)); p.propellantInitial_kg=.1;
t.verifyError(@()rocketlab.validate_sixdof(p),'rocketlab:MassFloor');
end
function testAeroAndWindSigns(t)
p=t.TestData.p; p.euler0_rad=zeros(3,1); p.omega0_body_rad_s=zeros(3,1); p.windNED_m_s=[0;2;0];
p=rocketlab.validate_sixdof(p); a=rocketlab.sixdof_forces(0,p.initialState,p);
t.verifyGreaterThan(a.aeroForce_B(2),0); t.verifyLessThan(a.aeroForce_B(1),0);
t.verifyLessThan(a.momentCG_B(3),0);
p.windNED_m_s(2)=-2; b=rocketlab.sixdof_forces(0,p.initialState,p);
t.verifyEqual(a.q_Pa,b.q_Pa,'AbsTol',1e-13);
t.verifyEqual(a.aeroForce_B(2),-b.aeroForce_B(2),'AbsTol',1e-13);
expected=.5*p.rho0_kg_m3*exp(p.position0_NED_m(3)/p.scaleHeight_m)*(20^2+2^2);
t.verifyEqual(a.q_Pa,expected,'AbsTol',1e-10);
end
function testRangeAndGroundGuards(t)
p=t.TestData.p; y=p.initialState; y(4:6)=rocketlab.quat_rotation(y(7:10))*[500;0;0];
t.verifyError(@()rocketlab.sixdof_forces(0,y,p),'rocketlab:AeroRange');
y=p.initialState; y(3)=1; t.verifyError(@()rocketlab.sixdof_forces(0,y,p),'rocketlab:GroundUnsupported');
p.thrust_N(end)=1; t.verifyError(@()rocketlab.validate_sixdof(p),'rocketlab:SixDOFPropulsion');
end
function testMovingCGRejected(t)
p=t.TestData.p; p.propellantStation_m=p.propellantStation_m+.01;
t.verifyError(@()rocketlab.validate_sixdof(p),'rocketlab:MovingCGUnsupported');
end
function testPostburnFullBalanceAndBothPlanes(t)
h=t.TestData.h; i=find(h.structuralEligible,1); c=rocketlab.sixdof_load_case(h,i);
b=rocketlab.balance(c); t.verifyTrue(b.balanced); t.verifyLessThan(norm(b.force),1e-9); t.verifyLessThan(norm(b.moment),1e-9);
r=rocketlab.analyze_case(h.parameters.vehicle,c);
t.verifyGreaterThan(max(abs(r.sections.My)),1e-5); t.verifyGreaterThan(max(abs(r.sections.Mz)),1e-5);
t.verifyGreaterThan(max(abs(r.sections.T)),1e-8); t.verifyEqual(r.wholeVehicleStatus,"not_evaluated");
t.verifyEqual(c.time_s,h.time_s(i));
end
function testBurningTransferRejected(t)
h=t.TestData.h; i=find(h.massFlow_kg_s>0,1);
t.verifyError(@()rocketlab.sixdof_load_case(h,i),'rocketlab:OpenSystemLoad');
% A zero-flow first sample is also outside the explicitly postburn scope.
t.verifyError(@()rocketlab.sixdof_load_case(h,1),'rocketlab:OpenSystemLoad');
end
function testBadAccelerationCannotBeBalanced(t)
h=t.TestData.h; i=find(h.structuralEligible,1); h.angularAcceleration_B_rad_s2(i,2)=h.angularAcceleration_B_rad_s2(i,2)+1;
t.verifyError(@()rocketlab.sixdof_load_case(h,i),'rocketlab:UnbalancedFlight');
end
function testEveryEligibleSampleAndEnvelopeOwner(t)
h=t.TestData.h; s=rocketlab.sixdof_structure_summary(h);
t.verifyEqual(s.samplesEvaluated,nnz(h.structuralEligible));
t.verifyTrue(all(h.time_s(s.envelope.My_sampleIndex)>=h.parameters.time_s(end)));
[~,iq]=max(h.q_Pa); t.verifyEqual(s.events.sampleIndex(s.events.event=="max_q"),iq);
[~,i]=max(s.history.bending_Nm); t.verifyEqual(s.maxBendingSampleIndex,s.history.sampleIndex(i));
j=ceil(height(s.envelope)/2); c=rocketlab.sixdof_load_case(h,s.envelope.My_sampleIndex(j));
a=rocketlab.section_forces(c,s.envelope.x(j),s.envelope.side(j));
t.verifyEqual(abs(a.My),s.envelope.My_abs(j),'AbsTol',1e-11);
end
function testParameterChangesRejectHistory(t)
h=t.TestData.h; i=find(h.structuralEligible,1); h.parameters.windNED_m_s(1)=3;
t.verifyError(@()rocketlab.sixdof_load_case(h,i),'rocketlab:StaleFlight');
end
function testQuaternionSignComparison(t)
h=t.TestData.h; b=h; b.state(:,7:10)=-b.state(:,7:10);
c=rocketlab.compare_sixdof_histories(h,b); t.verifyTrue(c.passed);
b.time_s(end)=b.time_s(end)+1;
t.verifyError(@()rocketlab.compare_sixdof_histories(h,b),'rocketlab:EventAlignment');
end
function testReversedHistoryRejected(t)
h=t.TestData.h; time=h.time_s; time(3)=time(2)/2;
t.verifyError(@()rocketlab.sixdof_history(h.parameters,time,h.state,h.engine),'rocketlab:FlightHistory');
end
function p=vacuum(p)
p.rho0_kg_m3=0; p.g_m_s2=0; p.angularDamping_Nms=zeros(3,1);
p.thrust_N(:)=0; p.massFlow_kg_s(:)=0; p.position0_NED_m=[0;0;-1000];
p.omega0_body_rad_s=zeros(3,1); p=rocketlab.validate_sixdof(p);
end
function [L,E]=invariants(h)
L=zeros(numel(h.time_s),3); E=zeros(numel(h.time_s),1);
for k=1:numel(h.time_s)
 a=rocketlab.sixdof_propulsion(h.time_s(k),h.parameters); w=h.state(k,11:13)';
 L(k,:)=(rocketlab.quat_rotation(h.state(k,7:10))*a.I_B*w)'; E(k)=.5*w'*a.I_B*w;
end
end
