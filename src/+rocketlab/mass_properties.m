function p = mass_properties(mass,position,inertia)
mass=mass(:); n=numel(mass);
assert(isequal(size(position),[n,3]) && all(isfinite(mass)&mass>=0) && sum(mass)>0 && all(isfinite(position),'all'),'rocketlab:Mass','Invalid mass data.');
if nargin<3, inertia=zeros(3,3,n); end
assert(size(inertia,1)==3 && size(inertia,2)==3 && size(inertia,3)==n,'rocketlab:Inertia','Expected 3-by-3-by-N tensors.');
p.mass=sum(mass); p.cg=sum(mass.*position,1)/p.mass; p.inertia=zeros(3);
for k=1:n
 I=inertia(:,:,k); ev=eig((I+I')/2);
 assert(all(isfinite(I),'all') && norm(I-I')<1e-9 && min(ev)>-1e-10 && 2*max(ev)<=sum(ev)+1e-9,'rocketlab:Inertia','Invalid intrinsic inertia.');
 r=position(k,:)-p.cg; p.inertia=p.inertia+I+mass(k)*(dot(r,r)*eye(3)-r'*r);
end
end
