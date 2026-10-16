function stations=critical_stations(v,c)
% Interior extrema of the piecewise polynomial beam solution.
% Includes deflection-norm stationary points and signed stress candidates.
base=rocketlab.beam_response(v,c,[],c.reference); x=unique(base.s);
stations=x;
for k=1:numel(x)-1
 a=x(k); h=x(k+1)-a;
 member=find(v.members.s0<=(a+h/2)&v.members.s1>(a+h/2),1); m=v.members(member,:);
 f=rocketlab.section_forces(c,a+h*[.25;.5;.75]);
 my=polyfit([.25;.5;.75],f.My,2); mz=polyfit([.25;.5;.75],f.Mz,2);
 axial=polyfit([.25;.75],f.N([1,3])/m.A,1);
 momentSquared=pluspoly(conv(my,my),conv(mz,mz));
 momentDot=pluspoly(conv(my,polyder(my)),conv(mz,polyder(mz)));
 stressEquation=pluspoly(conv(momentDot,momentDot),-(axial(1)*m.Z)^2*momentSquared);
 candidates=[realroots(stressEquation);realroots(momentDot);realroots(momentSquared)];
 row=find(base.s==a & base.side=="right",1);
 wy=polyint(polyint(h^2*mz/m.EI,h*base.thetaY(row)),base.wy(row));
 wz=polyint(polyint(-h^2*my/m.EI,h*base.thetaZ(row)),base.wz(row));
 deflectionEquation=pluspoly(conv(wy,polyder(wy)),conv(wz,polyder(wz)));
 candidates=[candidates;realroots(deflectionEquation)];
 vy=polyfit([.25;.75],f.Vy([1,3]),1); vz=polyfit([.25;.75],f.Vz([1,3]),1);
 torque=polyfit([.25;.75],f.T([1,3]),1);
 vsq=pluspoly(conv(vy,vy),conv(vz,vz)); vdot=pluspoly(conv(vy,polyder(vy)),conv(vz,polyder(vz)));
 shearEquation=pluspoly(m.shearPerForce^2*conv(vdot,vdot),-(m.torsionPerMoment*torque(1))^2*vsq);
 candidates=[candidates;realroots(shearEquation);realroots(torque);realroots(vsq)];
 candidates=candidates(candidates>1e-10 & candidates<1-1e-10);
 stations=[stations;a+h*candidates]; %#ok<AGROW>
end
stations=unique(stations);
end
function p=pluspoly(a,b)
n=max(numel(a),numel(b)); p=[zeros(1,n-numel(a)),a]+[zeros(1,n-numel(b)),b];
end
function r=realroots(p)
scale=max(abs(p));
if scale==0, r=[]; return; end
first=find(abs(p)>scale*1e-11,1); p=p(first:end);
if numel(p)<=1, r=[]; return; end
z=roots(p); r=real(z(abs(imag(z))<1e-7));
end
