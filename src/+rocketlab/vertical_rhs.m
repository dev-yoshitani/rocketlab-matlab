function [dy,aux]=vertical_rhs(t,y,p)
% Shared by MATLAB ODE and generated Simulink S-function.
mach=abs(y(2))/p.soundSpeed;
assert(mach>=p.mach(1)&&mach<=p.mach(end),'rocketlab:AeroRange','Mach %g outside [%g,%g].',mach,p.mach(1),p.mach(end));
cd=interp1(p.mach,p.cd,mach,'linear');
if t<p.time(end)
 thrust=interp1(p.time,p.thrust,t,'linear'); flow=interp1(p.time,p.massFlow,t,'linear');
else, thrust=0; flow=0; end
assert(y(3)>=p.dryMass-1e-6 && y(3)>0,'rocketlab:MassFloor','Mass state and propulsion flow disagree.');
rho=p.rho0*exp(-y(1)/p.scaleHeight); q=.5*rho*y(2)^2;
drag=q*p.area*cd*sign(y(2)); accel=(thrust-drag)/y(3)-p.g;
if y(1)<=0 && y(2)<=0 && accel<0, accel=0; end
dy=[y(2);accel;-flow];
aux=struct('q_Pa',q,'mach',mach,'thrust_N',thrust,'drag_N',drag,'massFlow',flow,'acceleration_m_s2',accel);
end
