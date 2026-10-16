function h=sixdof_history(p,time,state,engine)
time=time(:); assert(size(state,1)==numel(time)&&size(state,2)==13&&all(isfinite(state),'all'),'rocketlab:FlightHistory','Invalid 6DOF history.');
assert(all(isfinite(time))&&all(diff(time)>=0),'rocketlab:FlightHistory','Nonfinite or reversed times are not continuous solver events.');
% Native solver can record identical states on a continuous forcing knot.
duplicate=find(diff(time)==0);
assert(all(vecnorm(state(duplicate,:)-state(duplicate+1,:),2,2)<1e-10),'rocketlab:EventAlignment','Conflicting states at one time.');
keep=[true;diff(time)>0]; time=time(keep); state=state(keep,:);
assert(all(diff(time)>0)&&abs(time(1))<1e-10&&abs(time(end)-p.stopTime_s)<1e-8,'rocketlab:FlightHistory','Incomplete or unordered interval.');
n=numel(time); values=zeros(n,10); acceleration=zeros(n,3); alpha=zeros(n,3);
inertia=zeros(n,6); aero=zeros(n,3); moment=zeros(n,3);
for k=1:n
 [dy,a]=rocketlab.sixdof_rhs(time(k),state(k,:)',p);
 values(k,:)=[a.mass_kg,a.remaining_kg,a.flow_kg_s,a.thrust_N,a.airspeed_m_s,a.mach,a.q_Pa,a.alpha_rad,a.beta_rad,a.rho_kg_m3];
 acceleration(k,:)=dy(4:6)'; alpha(k,:)=dy(11:13)';
 inertia(k,:)=[a.I_B(1,1),a.I_B(2,2),a.I_B(3,3),a.I_B(1,2),a.I_B(1,3),a.I_B(2,3)];
 aero(k,:)=a.aeroForce_B'; moment(k,:)=a.momentCG_B';
end
h=struct('id',p.id,'engine',string(engine),'parameters',p,'parameterHash',rocketlab.hash(jsonencode(p)), ...
 'time_s',time,'state',state,'altitude_m',-state(:,3),'mass_kg',values(:,1),'propellant_kg',values(:,2), ...
 'massFlow_kg_s',values(:,3),'thrust_N',values(:,4),'airspeed_m_s',values(:,5),'mach',values(:,6),'q_Pa',values(:,7), ...
 'alpha_rad',values(:,8),'beta_rad',values(:,9),'rho_kg_m3',values(:,10),'acceleration_NED_m_s2',acceleration, ...
 'angularAcceleration_B_rad_s2',alpha,'inertia_B_kgm2',inertia,'aeroForce_B_N',aero,'momentCG_B_Nm',moment,'quaternionNorm',vecnorm(state(:,7:10),2,2), ...
 'structuralEligible',time>=p.time_s(end)&values(:,3)==0, ...
 'coordinates',"NED; scalar-first Hamilton q maps body to NED; body x noseward; S=diag(-1,1,-1) maps body to station", ...
 'accelerationConvention',"coordinate acceleration including gravity", ...
 'model',p.scope,'identicalDuplicateSamples',numel(duplicate));
assert(max(abs(h.quaternionNorm-1))<1e-5,'rocketlab:QuaternionDrift','Quaternion norm exceeded tolerance.');
end
