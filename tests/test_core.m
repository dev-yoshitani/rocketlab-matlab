function tests = test_core
tests=functiontests(localfunctions);
end
function setupOnce(t)
startup_project; t.TestData.root=fileparts(fileparts(mfilename('fullpath')));
end
function [v,c]=unitBeam()
[v,c]=rocketlab.demo_config; v.members=v.members(1,:); v.members.s1=1;
v.members.thickness=.001; sec=rocketlab.tube_section(.05,.001,1,.33);
v.members.E=1/sec.I; v.joints=v.joints([],:);
c.points=rocketlab.point_loads([0;.5;1],[0,1,0;0,-2,0;0,1,0]); c.distributed=rocketlab.empty_distributed();
v=rocketlab.validate_vehicle(v);
end
function testC1Uniform(t)
[v,c]=unitBeam; r=rocketlab.beam_response(v,c,[0;.5;1],.5);
t.verifyEqual(r.wy([1,end]),[1;1]/24,'AbsTol',1e-12);
end
function testC2Step(t)
[v,c]=unitBeam; v.members=[v.members;v.members]; v.members.id=["a";"b"];
v.members.s0=[0;.5]; v.members.s1=[.5;1]; v.members.E(2)=v.members.E(2)*.01;
v=rocketlab.validate_vehicle(v); c.points.Fy=c.points.Fy*.001;
r=rocketlab.beam_response(v,c,linspace(0,1,5)',.5);
t.verifyEqual(r.wy(end),.001/(24*.01),'AbsTol',1e-12);
end
function testC3ThrustPosition(t)
[~,c]=unitBeam; c.points=rocketlab.point_loads([.2;.8;.6],[500,0,0;500,0,0;-1000,0,0]);
r=rocketlab.section_forces(c,[.1;.4;.7;.9]);
t.verifyEqual(r.N,[0;-500;500;0],'AbsTol',1e-12);
end
function testC4SignedStress(t)
s=rocketlab.signed_stress(-10e6,6e6,1,1);
t.verifyEqual(s.tension,0); t.verifyEqual(s.compression,16e6);
c=rocketlab.check("x","deflection",.008,.010,1,"specified");
t.verifyEqual(c.status,"pass"); t.verifyEqual(c.MS,.25,'AbsTol',1e-12);
end
function testC5FinDistribution(t)
a=rocketlab.fin_distribution(100,[50;0;50;0],"specified opposite fins");
t.verifyEqual(a.forces,[50;0;50;0]);
a=rocketlab.fin_distribution(100); t.verifyEqual(a.status,"not_evaluated");
t.verifyError(@()rocketlab.fin_distribution(100,[25;25],"bad sum"),'rocketlab:FinResultant');
end
function testMissingAllowable(t)
[v,c]=rocketlab.demo_config; v.members.compression(1)=NaN; r=rocketlab.analyze_case(v,c);
s=string({r.checks.status}); t.verifyEqual(nnz(s=="not_evaluated"),1);
t.verifyEqual(r.selectedEvaluationStatus,"incomplete"); t.verifyEqual(r.wholeVehicleStatus,"not_evaluated");
end
function testNoLoadAndMissing(t)
a=rocketlab.check("x","tension",0,1e6,1.5,"specified"); t.verifyEqual(a.status,"no_load"); t.verifyTrue(isnan(a.SF));
b=rocketlab.check("x","tension",0,NaN,1.5,"missing"); t.verifyEqual(b.status,"not_evaluated");
t.verifyTrue(contains(jsonencode(a),'"SF":null'));
end
function testCantileverTip(t)
[v,c]=unitBeam; c.mode="test"; c.boundary="cantilever"; c.points=rocketlab.point_loads(1,[0,-1,0]);
c=rocketlab.support_loads(c,1); r=rocketlab.beam_response(v,c,[0;1]);
t.verifyEqual(r.wy(end),-1/3,'AbsTol',1e-12);
end
function testUniformDistributed(t)
[v,c]=unitBeam; c.mode="test"; c.boundary="cantilever"; c.points=rocketlab.point_loads([],zeros(0,3));
c.distributed=array2table([0,1,0,-1,0,0,0,0],'VariableNames',c.distributed.Properties.VariableNames);
c=rocketlab.support_loads(c,1); r=rocketlab.beam_response(v,c,[0;1]);
t.verifyEqual(r.wy(end),-1/8,'AbsTol',1e-12);
end
function testSimplySupported(t)
[v,c]=unitBeam; c.mode="test"; c.boundary="simply_supported"; c.points=rocketlab.point_loads(.5,[0,-1,0]);
c=rocketlab.support_loads(c,1); r=rocketlab.beam_response(v,c,[0;.5;1]);
t.verifyEqual(r.wy(r.s==.5),[-1;-1]/48,'AbsTol',1e-12);
t.verifyEqual(r.wy([1,end]),[0;0],'AbsTol',1e-12);
end
function testRotationSpring(t)
[v,c]=unitBeam; v.joints=table(.5,100,10,'VariableNames',{'s','ky','kz'});
r=rocketlab.beam_response(v,c,[0;.5;1],.5); idx=find(r.s==.5);
t.verifyEqual(diff(r.thetaY(idx)),.5/10,'AbsTol',1e-12);
t.verifyEqual(diff(r.wy(idx)),0,'AbsTol',1e-12);
end
function testRejectUnbalanced(t)
[v,c]=unitBeam; c.points.Fy(2)=0;
t.verifyError(@()rocketlab.analyze_case(v,c),'rocketlab:Unbalanced');
end
function testMassProperties(t)
p=rocketlab.mass_properties([1;3],[0,0,0;2,0,0]);
t.verifyEqual(p.mass,4); t.verifyEqual(p.cg,[1.5,0,0]);
t.verifyEqual(p.inertia,diag([0,3,3]),'AbsTol',1e-12);
end
function testFreeFall(t)
p=rocketlab.inertial_loads([1;2],[0,0,0;1,0,0],zeros(3,3,2),[0,0,9.81],[0,0,0],[0,0,0],[0,0,9.81]);
t.verifyEqual(p{:,{'Fx','Fy','Fz','Mx','My','Mz'}},zeros(2,6),'AbsTol',1e-12);
end
function testRotatingRelief(t)
[~,c]=unitBeam; c.points=rocketlab.point_loads([.1;.9],[10,4,2;-1,3,-2]);
I=repmat(diag([.01,.02,.02]),1,1,2);
[c,~]=rocketlab.snapshot_loads(c,[1;2],[.2,0,0;.8,0,0],I,[0,0,9.81],[1,2,3]);
b=rocketlab.balance(c); t.verifyTrue(b.balanced);
end
function testFrameRemoval(t)
[v,c]=unitBeam; a=rocketlab.beam_response(v,c,[0;.5;1],.5); b=rocketlab.beam_response(v,c,[0;.5;1],0);
t.verifyEqual(a.Mz,b.Mz,'AbsTol',1e-12);
delta=a.wy-b.wy; t.verifyLessThan(max(abs(delta-(delta(1)+(delta(end)-delta(1))*a.s))),1e-12);
end
function testHash(t)
t.verifyEqual(rocketlab.hash('abc'),'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
end
function testThicknessUpdatesMass(t)
[v,c]=rocketlab.demo_config; a=rocketlab.sweep_thickness(v,c,[1;1.2]);
t.verifyGreaterThan(a.memberMass_kg(2),a.memberMass_kg(1));
t.verifyLessThan(a.maxDeflection_m(2),a.maxDeflection_m(1));
c.mode="predict"; t.verifyError(@()rocketlab.sweep_thickness(v,c,1.2),'rocketlab:StaleFlight');
end

function testInteriorDeflectionPeak(t)
[v,c]=unitBeam; c.mode="test"; c.boundary="simply_supported"; a=.37;
c.points=rocketlab.point_loads(a,[0,-1,0]); r=rocketlab.analyze_case(v,c);
x=1-sqrt((1-a*a)/3); expected=a*(1-x)/6*(1-a*a-(1-x)^2);
checks=r.checks(string({r.checks.mode})=="deflection");
t.verifyEqual(checks.station,x,'AbsTol',1e-8); t.verifyEqual(checks.demand,expected,'AbsTol',1e-10);
end
function testJSONNullAllowable(t)
[v,c]=rocketlab.demo_config; v.members.compression(1)=NaN;
v=jsondecode(jsonencode(v)); c=jsondecode(jsonencode(c));
r=rocketlab.analyze_case(v,c); t.verifyEqual(r.selectedEvaluationStatus,"incomplete");
end

function testAnalysisDependencies(t)
[v,c]=rocketlab.demo_config; v.members.density(:)=NaN; v.members.strengthFactor(1)=NaN;
r=rocketlab.analyze_case(v,c); modes=string({r.checks.mode}); ids=string({r.checks.memberId});
a=r.checks(modes=="deflection"&ids=="front"); t.verifyEqual(a.status,"pass");
a=r.checks(modes=="tension"&ids=="front"); t.verifyEqual(a.status,"not_evaluated");
t.verifyError(@()rocketlab.beam_modes(v,"free"),'rocketlab:MissingDensity');
end
