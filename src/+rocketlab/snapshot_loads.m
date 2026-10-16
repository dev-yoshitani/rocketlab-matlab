function [loads,motion] = snapshot_loads(external,mass,positions,inertias,gravity,omega)
if nargin<5, gravity=[0,0,0]; end
if nargin<6, omega=[0,0,0]; end
props=rocketlab.mass_properties(mass,positions,inertias);
assert(rcond(props.inertia)>1e-12,'rocketlab:SingularInertia','Full nonsingular inertia required.');
b=rocketlab.balance(external); r=props.cg; torque=b.moment-cross(r,b.force);
motion.angularAccel=(props.inertia\(torque'-cross(omega',props.inertia*omega')))';
motion.aCG=b.force/props.mass+gravity;
motion.aOrigin=motion.aCG-cross(motion.angularAccel,r)-cross(omega,cross(omega,r));
p=rocketlab.inertial_loads(mass,positions,inertias,motion.aOrigin,omega,motion.angularAccel,gravity);
loads=external; loads.points=[loads.points;p]; loads.mode="snapshot"; loads.boundary="free";
end
