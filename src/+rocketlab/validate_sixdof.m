function p=validate_sixdof(p)
p.vehicle=rocketlab.validate_vehicle(p.vehicle);
assert(string(p.vehicleHash)==string(rocketlab.hash(jsonencode(p.vehicle))),'rocketlab:StaleFlight','Vehicle changed; rebuild the mass and load configuration.');
positive={'propellantInitial_kg','area_m2','scaleHeight_m','soundSpeed_m_s','stopTime_s','maxStep_s','relTol','absTol','aeroAngleLimit_rad'};
for k=1:numel(positive)
 x=p.(positive{k}); assert(isscalar(x)&&isfinite(x)&&x>0,'rocketlab:SixDOFInput','Expected a positive finite scalar: %s',positive{k});
end
for f={'g_m_s2','rho0_kg_m3','normalSlope_rad'}
 x=p.(f{1}); assert(isscalar(x)&&isfinite(x)&&x>=0,'rocketlab:SixDOFInput','Expected a nonnegative scalar.');
end
for f={'position0_NED_m','velocity0_body_m_s','euler0_rad','omega0_body_rad_s','windNED_m_s','angularDamping_Nms'}
 x=p.(f{1}); assert(isnumeric(x)&&numel(x)==3&&all(isfinite(x)),'rocketlab:SixDOFInput','Expected a finite three-vector.');
 p.(f{1})=x(:);
end
assert(all(p.angularDamping_Nms>=0)&&p.position0_NED_m(3)<0,'rocketlab:SixDOFInput','Free-flight initial height and nonnegative damping are required.');
p.time_s=p.time_s(:); p.thrust_N=p.thrust_N(:); p.massFlow_kg_s=p.massFlow_kg_s(:);
n=numel(p.time_s);
assert(n>=2&&isequal(size(p.time_s),size(p.thrust_N),size(p.massFlow_kg_s)) ...
 &&all(isfinite([p.time_s;p.thrust_N;p.massFlow_kg_s]))&&p.time_s(1)==0&&all(diff(p.time_s)>0) ...
 &&all(p.thrust_N>=0)&&all(p.massFlow_kg_s>=0),'rocketlab:SixDOFPropulsion','Invalid propulsion history.');
assert(p.thrust_N(end)==0&&p.massFlow_kg_s(end)==0,'rocketlab:SixDOFPropulsion','A measured end is required; no zero tail is invented.');
assert(trapz(p.time_s,p.massFlow_kg_s)<=p.propellantInitial_kg+1e-12,'rocketlab:MassFloor','Integrated outflow exceeds available mass.');
p.aeroMach=p.aeroMach(:); p.aeroCA=p.aeroCA(:);
assert(numel(p.aeroMach)>=2&&isequal(size(p.aeroMach),size(p.aeroCA))&&all(isfinite([p.aeroMach;p.aeroCA])) ...
 &&p.aeroMach(1)==0&&all(diff(p.aeroMach)>0)&&all(p.aeroCA>=0)&&p.aeroAngleLimit_rad<pi/2,'rocketlab:AeroRange','Invalid coefficient table or angle range.');
p.dryPartMass_kg=p.dryPartMass_kg(:); p.partStation_m=p.partStation_m(:); n=numel(p.dryPartMass_kg);
assert(numel(p.partStation_m)==n&&numel(p.partIds)==n&&all(p.dryPartMass_kg>0),'rocketlab:MassDistribution','Invalid part mapping.');
s=[p.partStation_m;p.propellantStation_m;p.cpStation_m;p.thrustStation_m];
assert(all(isfinite(s)&s>=0&s<=p.vehicle.length),'rocketlab:MassDistribution','Stations must lie on the vehicle.');
a=rocketlab.mass_properties(p.dryPartMass_kg,[p.partStation_m,zeros(n,2)],p.dryPartInertia_S_kgm2);
b=rocketlab.mass_properties(1,[0,0,0],p.propellantInertiaPerKg_S_m2);
assert(abs(p.propellantStation_m-a.cg(1))<1e-10,'rocketlab:MovingCGUnsupported','This model requires propellant at the dry CG; moving CG is not implemented.');
S=diag([-1,1,-1]); p.dryMass_kg=a.mass; p.cgStation_m=a.cg(1);
p.dryInertia_B_kgm2=S*a.inertia*S'; p.propellantInertiaPerKg_B_m2=S*b.inertia*S';
assert(min(eig(p.dryInertia_B_kgm2))>1e-10,'rocketlab:Inertia','Positive definite total inertia is required.');
p.quaternion0=rocketlab.euler_quat(p.euler0_rad);
p.initialState=[p.position0_NED_m;rocketlab.quat_rotation(p.quaternion0)*p.velocity0_body_m_s;p.quaternion0;p.omega0_body_rad_s];
end
