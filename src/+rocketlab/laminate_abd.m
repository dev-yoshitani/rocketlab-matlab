function out=laminate_abd(plies)
% Classical laminated plate theory; plane stress and engineering shear gamma.
% Rows: thickness_m, angle_rad, E1, E2, G12, nu12. No strength inference.
assert(isnumeric(plies)&&size(plies,2)==6&&all(isfinite(plies),'all'),'rocketlab:Laminate','Expected N-by-6 ply data.');
assert(all(plies(:,1)>0)&all(plies(:,3:5)>0,'all'),'rocketlab:Laminate','Thickness and moduli must be positive.');
z=[0;cumsum(plies(:,1))]-sum(plies(:,1))/2; A=zeros(3); B=A; D=A; qb=zeros(3,3,size(plies,1));
for k=1:size(plies,1)
 p=plies(k,:); v21=p(6)*p(4)/p(3); den=1-p(6)*v21;
 assert(den>0,'rocketlab:Laminate','Non-positive constitutive stiffness.');
 q11=p(3)/den; q22=p(4)/den; q12=p(6)*p(4)/den; q66=p(5);
 m=cos(p(2)); n=sin(p(2));
 a=q11*m^4+2*(q12+2*q66)*m^2*n^2+q22*n^4;
 b=(q11+q22-4*q66)*m^2*n^2+q12*(m^4+n^4);
 d=q11*n^4+2*(q12+2*q66)*m^2*n^2+q22*m^4;
 e=(q11-q12-2*q66)*m^3*n-(q22-q12-2*q66)*m*n^3;
 f=(q11-q12-2*q66)*m*n^3-(q22-q12-2*q66)*m^3*n;
 g=(q11+q22-2*q12-2*q66)*m^2*n^2+q66*(m^4+n^4);
 Q=[a,b,e;b,d,f;e,f,g]; qb(:,:,k)=Q;
 A=A+Q*(z(k+1)-z(k)); B=B+Q*(z(k+1)^2-z(k)^2)/2; D=D+Q*(z(k+1)^3-z(k)^3)/3;
end
out=struct('A',A,'B',B,'D',D,'ABD',[A,B;B,D],'z',z,'Qbar',qb, ...
 'scope',"linear plane-stress laminate stiffness; strength, delamination and shell buckling unevaluated", ...
 'source',"NASA RP-1351, Basic mechanics of laminated composite plates (1994)");
end
