function out=beam_modes(vehicle,boundary,elementCount,pointMasses)
% Planar Euler-Bernoulli FEM: two rigid modes for free-free, consistent mass.
% Rotation springs split rotation DOFs but retain translational continuity.
v=rocketlab.validate_vehicle(vehicle);
assert(all(isfinite(v.members.density)&v.members.density>0),'rocketlab:MissingDensity','Modal analysis requires density.');
if nargin<3, elementCount=30; end
if nargin<4, pointMasses=zeros(0,2); end
assert(size(pointMasses,2)==2&&all(pointMasses(:,1)>=0&pointMasses(:,1)<=v.length)&&all(pointMasses(:,2)>=0),'rocketlab:PointMass','Expected [station,mass].');
x=unique([linspace(0,v.length,elementCount+1)';v.members.s0;v.members.s1;v.joints.s;pointMasses(:,1)]);
n=numel(x); displacement=(1:2:2*n)'; leftRotation=(2:2:2*n)'; rightRotation=leftRotation;
nd=2*n;
for k=1:height(v.joints)
 i=find(x==v.joints.s(k)); nd=nd+1; rightRotation(i)=nd;
end
K=zeros(nd); M=zeros(nd);
for k=1:n-1
 h=x(k+1)-x(k); mid=(x(k+1)+x(k))/2; m=find(v.members.s0<=mid&v.members.s1>mid,1);
 EI=v.members.EI(m); mu=v.members.density(m)*v.members.A(m);
 ke=EI/h^3*[12,6*h,-12,6*h;6*h,4*h^2,-6*h,2*h^2;-12,-6*h,12,-6*h;6*h,2*h^2,-6*h,4*h^2];
 me=mu*h/420*[156,22*h,54,-13*h;22*h,4*h^2,13*h,-3*h^2;54,13*h,156,-22*h;-13*h,-3*h^2,-22*h,4*h^2];
 index=[displacement(k),rightRotation(k),displacement(k+1),leftRotation(k+1)];
 K(index,index)=K(index,index)+ke; M(index,index)=M(index,index)+me;
end
for k=1:height(v.joints)
 i=find(x==v.joints.s(k)); ids=[leftRotation(i),rightRotation(i)];
 assert(isfinite(v.joints.kz(k)),'rocketlab:JointStiffness','Use no joint for rigid continuity in modal model.');
 K(ids,ids)=K(ids,ids)+v.joints.kz(k)*[1,-1;-1,1];
end
for k=1:size(pointMasses,1)
 i=displacement(x==pointMasses(k,1)); M(i,i)=M(i,i)+pointMasses(k,2);
end
switch string(boundary)
 case "free", fixed=[];
 case "cantilever", fixed=[displacement(1),leftRotation(1)];
 case "simply_supported", fixed=[displacement(1),displacement(end)];
 otherwise, error('rocketlab:Boundary','Unknown boundary.');
end
active=setdiff(1:nd,fixed);
[V,D]=eig(K(active,active),M(active,active)); lambda=real(diag(D));
[lambda,order]=sort(lambda); V=real(V(:,order));
% Absolute scale derived from EI/(mu*L^4), not highest mesh eigenvalue.
scale=max(v.members.EI./(v.members.density.*v.members.A))/v.length^4;
threshold=1e-6*scale;
assert(all(lambda>=-threshold),'rocketlab:ModalInstability','Negative stiffness mode.');
rigid=abs(lambda)<=threshold; phi=zeros(nd,numel(lambda)); phi(active,:)=V;
out=struct('frequency_Hz',sqrt(max(0,lambda(~rigid)))/(2*pi),'rigidModeCount',nnz(rigid), ...
 'stations',x,'modeShapes',phi(displacement,~rigid),'boundary',string(boundary), ...
 'model',"planar Euler-Bernoulli, two rigid modes in free-free; no damping or flutter");
end
