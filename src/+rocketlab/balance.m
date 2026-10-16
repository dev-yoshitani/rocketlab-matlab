function b = balance(loads)
p=loads.points; d=loads.distributed;
F=[p.Fx,p.Fy,p.Fz]; C=[p.Mx,p.My,p.Mz]; r=[p.s,zeros(height(p),2)];
fd=[d.qx,d.qy,d.qz].*(d.s1-d.s0);
cd=[d.tx,d.ty,d.tz].*(d.s1-d.s0);
rd=[(d.s0+d.s1)/2,zeros(height(d),2)];
b.force=sum(F,1)+sum(fd,1);
b.moment=sum(C+cross(r,F,2),1)+sum(cd+cross(rd,fd,2),1);
b.forceScale=max(1,sum(vecnorm(F,2,2))+sum(vecnorm(fd,2,2)));
b.momentScale=max(1,sum(vecnorm(C+cross(r,F,2),2,2))+sum(vecnorm(cd+cross(rd,fd,2),2,2)));
b.forceTolerance=1e-8*b.forceScale; b.momentTolerance=1e-8*b.momentScale;
b.balanced=norm(b.force)<=b.forceTolerance && norm(b.moment)<=b.momentTolerance;
end
