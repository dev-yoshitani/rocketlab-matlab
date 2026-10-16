function [dy,a]=sixdof_rhs(t,y,p)
% Independent MATLAB inertial translation and Hamilton quaternion reference.
a=rocketlab.sixdof_forces(t,y,p); w=y(11:13); q=y(7:10);
alpha=a.I_B\(a.momentCG_B-cross(w,a.I_B*w)-a.Idot_B*w);
Q=[0,-w';w,[0,w(3),-w(2);-w(3),0,w(1);w(2),-w(1),0]];
dy=[y(4:6);a.R_BN*a.force_B/a.mass_kg;.5*Q*q;alpha];
end
