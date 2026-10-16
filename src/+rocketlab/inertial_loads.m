function p = inertial_loads(mass,positions,inertias,aOrigin,omega,angularAccel,gravity)
% Fixed body point O; frozen mass snapshot excludes internal flow motion.
n=numel(mass);
assert(size(positions,2)==3 && all(abs(positions(:,2:3))<1e-12,'all'),'rocketlab:BeamAxis','Masses must be on beam axis.');
mass=mass(:); aOrigin=aOrigin(:)'; omega=omega(:)'; angularAccel=angularAccel(:)'; gravity=gravity(:)';
a=repmat(aOrigin,n,1)+cross(repmat(angularAccel,n,1),positions,2)+cross(repmat(omega,n,1),cross(repmat(omega,n,1),positions,2),2);
F=mass.*(gravity-a); C=zeros(n,3);
for k=1:n
 I=inertias(:,:,k); C(k,:)=(-I*angularAccel'-cross(omega',I*omega'))';
end
p=rocketlab.point_loads(positions(:,1),F,C); p.id="inertia"+string((1:n)'); p.role(:)="inertia_and_gravity";
end
