function p=validate_flight(p)
assert(all(diff(p.time)>0)&&p.time(1)==0&&numel(p.time)==numel(p.thrust)&&numel(p.time)==numel(p.massFlow),'rocketlab:Propulsion','Invalid propulsion times.');
assert(all(isfinite([p.time(:);p.thrust(:);p.massFlow(:)]))&&all(p.thrust>=0)&all(p.massFlow>=0),'rocketlab:Propulsion','Invalid propulsion values.');
assert(p.thrust(end)==0 && p.massFlow(end)==0,'rocketlab:Burnout','Last propulsion knot must be zero.');
assert(all(diff(p.mach)>0)&&numel(p.mach)==numel(p.cd)&&all(p.cd>=0)&&all(isfinite(p.cd)),'rocketlab:AeroTable','Invalid Mach/CD table.');
consumed=trapz(p.time,p.massFlow);
assert(p.dryMass>0 && p.initial(3)>0 && abs(p.initial(3)-consumed-p.dryMass)<1e-8,'rocketlab:MassFlow','Dry mass must match integrated mass flow.');
assert(p.g>0&&p.rho0>0&&p.scaleHeight>0&&p.soundSpeed>0&&p.area>0&&p.maxTime>p.time(end),'rocketlab:FlightInput','Invalid environment.');
assert(numel(p.initial)==3 && all(isfinite(p.initial)) && p.initial(1)>=0 && p.initial(2)>=0,'rocketlab:FlightInput','Initial state must be [altitude; velocity; mass].');
end
