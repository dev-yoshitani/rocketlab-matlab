function f = section_forces(loads,positions,sides)
% Traction on the positive cut face of the nose-side body, tensile N positive.
x=positions(:); n=numel(x);
if nargin<3, sides=repmat("right",n,1); end
sides=string(sides(:));
assert(numel(sides)==n && all(ismember(sides,["left","right"])),'rocketlab:Side','Use left/right at every station.');
p=loads.points; d=loads.distributed;
mask=double(p.s'<x | (p.s'==x & sides=="right")); arm=(p.s'-x).*mask;
F=p{:,{'Fx','Fy','Fz'}}; C=p{:,{'Mx','My','Mz'}};
h=max(0,min(x,d.s1')-d.s0'); lever=h.*(d.s0'+h/2-x);
q=d{:,{'qx','qy','qz'}}; couples=d{:,{'tx','ty','tz'}};
force=-(mask*F+h*q);
moment=-(mask*C+h*couples+[zeros(n,1),-arm*F(:,3)-lever*q(:,3),arm*F(:,2)+lever*q(:,2)]);
f=table(x,sides,force(:,1),force(:,2),force(:,3),moment(:,1),moment(:,2),moment(:,3), ...
 'VariableNames',{'s','side','N','Vy','Vz','T','My','Mz'});
end
