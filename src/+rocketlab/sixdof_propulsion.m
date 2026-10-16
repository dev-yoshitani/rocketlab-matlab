function a=sixdof_propulsion(t,p)
% Exact integral of piecewise linear prescribed mass outflow, no state resets.
t=max(0,t); used=0;
for k=1:numel(p.time_s)-1
 dt=p.time_s(k+1)-p.time_s(k); u=min(max(t-p.time_s(k),0),dt);
 used=used+p.massFlow_kg_s(k)*u+(p.massFlow_kg_s(k+1)-p.massFlow_kg_s(k))*u*u/(2*dt);
end
remaining=p.propellantInitial_kg-used;
assert(remaining>=-1e-10,'rocketlab:MassFloor','Negative propellant mass.');
a.remaining_kg=max(remaining,0); a.mass_kg=p.dryMass_kg+a.remaining_kg;
a.flow_kg_s=interp1(p.time_s,p.massFlow_kg_s,t,'linear',0);
a.thrust_N=interp1(p.time_s,p.thrust_N,t,'linear',0);
a.I_B=p.dryInertia_B_kgm2+a.remaining_kg*p.propellantInertiaPerKg_B_m2;
a.Idot_B=-a.flow_kg_s*p.propellantInertiaPerKg_B_m2;
end
