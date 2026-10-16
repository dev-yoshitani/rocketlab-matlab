function c=sixdof_load_case(h,index)
% Only the closed-mass postburn interval is eligible for this inertia relief.
assert(isscalar(index)&&index==floor(index)&&index>=1&&index<=numel(h.time_s),'rocketlab:SampleIndex','Choose one recorded sample.');
p=h.parameters;
assert(string(h.parameterHash)==string(rocketlab.hash(jsonencode(p))),'rocketlab:StaleFlight','Flight parameters changed after integration.');
assert(h.time_s(index)>=p.time_s(end)&&h.massFlow_kg_s(index)==0,'rocketlab:OpenSystemLoad','Burning-phase structural transfer requires an internal flow/momentum model.');
assert(h.accelerationConvention=="coordinate acceleration including gravity",'rocketlab:AccelerationConvention','Explicit coordinate acceleration is required.');
y=h.state(index,:)'; a=rocketlab.sixdof_forces(h.time_s(index),y,p); S=diag([-1,1,-1]);
mass=[p.dryPartMass_kg;a.remaining_kg]; s=[p.partStation_m;p.propellantStation_m];
I=cat(3,p.dryPartInertia_S_kgm2,a.remaining_kg*p.propellantInertiaPerKg_S_m2);
props=rocketlab.mass_properties(mass,[s,zeros(numel(s),2)],I);
assert(abs(props.mass-h.mass_kg(index))<1e-9&&norm(S*props.inertia*S'-a.I_B)<1e-9,'rocketlab:MassDistribution','Mass/inertia mismatch.');
w=S*y(11:13); alpha=S*h.angularAcceleration_B_rad_s2(index,:)';
aCG=S*a.R_BN'*h.acceleration_NED_m_s2(index,:)'; cg=props.cg';
aNose=aCG-cross(alpha,cg)-cross(w,cross(w,cg));
external=rocketlab.point_loads([p.thrustStation_m;p.cpStation_m], ...
 [S*a.thrustForce_B,S*a.aeroForce_B]',[zeros(3,1),S*a.aeroCouple_B]');
external.id=["net-thrust";"aero-resultant"]; external.partId=["motor-interface";"aero"];
inertia=rocketlab.inertial_loads(mass,[s,zeros(numel(s),2)],I,aNose,w,alpha,S*a.gravity_B);
inertia.partId=[string(p.partIds(:));"propellant"];
c=struct('id',h.id+"-"+h.engine+"-sample-"+string(index),'time_s',h.time_s(index),'mode',"predict", ...
 'configurationHash',string(p.vehicleHash),'boundary',"free",'points',[external;inertia], ...
 'distributed',rocketlab.empty_distributed(),'reference',props.cg(1), ...
 'assumptions',p.source+" / postburn fixed-mass 6DOF inertia relief; lumped axis masses; synthetic aero; equivalent motor interface; local shell excluded", ...
 'flightSource',struct('historyId',h.id,'engine',h.engine,'sampleIndex',index,'parameterHash',h.parameterHash, ...
 'mass_kg',a.mass_kg,'q_Pa',a.q_Pa,'omega_B_rad_s',y(11:13),'alpha_B_rad_s2',h.angularAcceleration_B_rad_s2(index,:)'));
b=rocketlab.balance(c);
assert(b.balanced,'rocketlab:UnbalancedFlight','Mapped force/moment balance failed; no balancing load is added.');
end
