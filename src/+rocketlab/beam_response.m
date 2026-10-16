function response = beam_response(v,loads,stations,reference)
% Exact interval quadrature: curvature is at most cubic with uniform line couples.
if nargin<3, stations=linspace(0,v.length,101)'; end
if nargin<4, reference=v.length/2; end
b=rocketlab.balance(loads); assert(b.balanced,'rocketlab:Unbalanced','Residual exceeds tolerance.');
assert(reference>=0&&reference<=v.length,'rocketlab:Reference','Reference outside beam.');
m=v.members; j=v.joints; p=loads.points; d=loads.distributed;
x=unique([0;v.length;stations(:);reference;m.s0;m.s1;j.s;p.s;d.s0;d.s1]);
assert(all(isfinite(x)&x>=0&x<=v.length),'rocketlab:LoadPosition','Station outside beam.');
n=numel(x); left=zeros(n,6); right=zeros(n,6);
g=[-sqrt(3/5),0,sqrt(3/5)]; weights=[5/9,8/9,5/9]';
z=x(1:end-1)+diff(x)*(g+1)/2;
qf=rocketlab.section_forces(loads,reshape(z',[],1));
jf=rocketlab.section_forces(loads,j.s,repmat("left",height(j),1));
for k=1:n
 state=left(k,:); joint=find(j.s==x(k));
 if ~isempty(joint)
  state(5)=state(5)+jf.Mz(joint)/j.kz(joint);
  state(6)=state(6)-jf.My(joint)/j.ky(joint);
 end
 right(k,:)=state; if k==n, break; end
 h=x(k+1)-x(k); w=weights*h/2; pos=z(k,:)'; rows=(k-1)*3+(1:3);
 member=find(m.s0<=(x(k)+x(k+1))/2 & m.s1>(x(k)+x(k+1))/2,1);
 cy=qf.Mz(rows)/m.EI(member); cz=-qf.My(rows)/m.EI(member);
 left(k+1,:)=[state(1)+sum(w.*qf.N(rows))/m.EA(member), ...
 state(2)+h*state(5)+sum(w.*(x(k+1)-pos).*cy),state(3)+h*state(6)+sum(w.*(x(k+1)-pos).*cz), ...
 state(4)+sum(w.*qf.T(rows))/m.GJ(member),state(5)+sum(w.*cy),state(6)+sum(w.*cz)];
end
switch string(loads.boundary)
 case "free"
  ref=right(x==reference,:);
  offsets=[repmat(ref(1),n,1),ref(2)+(x-reference)*ref(5),ref(3)+(x-reference)*ref(6),repmat(ref(4:6),n,1)];
  left=left-offsets; right=right-offsets;
 case "simply_supported"
  slope=left(end,2:3)/v.length;
  left(:,2:3)=left(:,2:3)-x*slope; right(:,2:3)=right(:,2:3)-x*slope;
  left(:,5:6)=left(:,5:6)-slope; right(:,5:6)=right(:,5:6)-slope;
end
xx=reshape([x,x]',[],1); side=repmat(["left";"right"],n,1);
values=zeros(2*n,6); values(1:2:end,:)=left; values(2:2:end,:)=right;
response=[rocketlab.section_forces(loads,xx,side),array2table(values,'VariableNames',{'u','wy','wz','twist','thetaY','thetaZ'})];
response.memberId=strings(height(response),1);
for k=1:height(response)
 if side(k)=="left", index=find(m.s0<xx(k) & m.s1>=xx(k),1);
 else, index=find(m.s0<=xx(k) & m.s1>xx(k),1); end
 if isempty(index), index=1+(xx(k)==v.length)*(height(m)-1); end
 response.memberId(k)=string(m.id(index));
end
end
