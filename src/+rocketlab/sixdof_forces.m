function a=sixdof_forces(t,y,p)
% Common environment/applied loads, not the native Simulink equations of motion.
y=y(:); R=rocketlab.quat_rotation(y(7:10)); omega=y(11:13);
a=rocketlab.sixdof_propulsion(t,p); a.R_BN=R;
a.gravity_B=R'*[0;0;p.g_m_s2];
a.airVelocity_B=R'*(y(4:6)-p.windNED_m_s); speed=norm(a.airVelocity_B);
a.airspeed_m_s=speed; a.mach=speed/p.soundSpeed_m_s;
a.alpha_rad=0; a.beta_rad=0;
if speed>1e-9
 a.alpha_rad=atan2(a.airVelocity_B(3),a.airVelocity_B(1));
 a.beta_rad=asin(max(-1,min(1,a.airVelocity_B(2)/speed)));
end
assert(p.rho0_kg_m3==0 || (a.mach<=p.aeroMach(end)&&abs(a.alpha_rad)<=p.aeroAngleLimit_rad&&abs(a.beta_rad)<=p.aeroAngleLimit_rad), ...
 'rocketlab:AeroRange','State exceeds the documented aerodynamic table/angle range; extrapolation is disabled.');
assert(y(3)<=0,'rocketlab:GroundUnsupported','Free-flight interval reached the ground; ground reactions are not implemented.');
a.rho_kg_m3=p.rho0_kg_m3*exp(y(3)/p.scaleHeight_m);
a.q_Pa=.5*a.rho_kg_m3*speed^2; ca=0;
if a.q_Pa>0, ca=interp1(p.aeroMach,p.aeroCA,a.mach); end
a.aeroForce_B=a.q_Pa*p.area_m2*[-ca;-p.normalSlope_rad*a.beta_rad;-p.normalSlope_rad*a.alpha_rad];
a.thrustForce_B=[a.thrust_N;0;0];
a.aeroCouple_B=-p.angularDamping_Nms.*omega;
% In nose-directed body axes, the CP aft of the CG has negative x.
a.momentCG_B=cross([p.cgStation_m-p.cpStation_m;0;0],a.aeroForce_B)+a.aeroCouple_B;
a.force_B=a.thrustForce_B+a.aeroForce_B+a.mass_kg*a.gravity_B;
end
