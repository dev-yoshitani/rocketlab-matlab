function s = tube_section(outerDiameter, thickness, E, nu)
validateattributes(outerDiameter,{'numeric'},{'real','finite','positive'});
validateattributes(thickness,{'numeric'},{'real','finite','positive','size',size(outerDiameter)});
assert(all(2*thickness<outerDiameter,'all'),'rocketlab:Geometry','Tube thickness must be smaller than radius.');
assert(all(isfinite(E)&E>0,'all') && all(isfinite(nu)&nu>-1&nu<.5,'all'),'rocketlab:Material','Invalid isotropic elastic properties.');
ro=outerDiameter/2; ri=ro-thickness;
s.A=pi*(ro.^2-ri.^2); s.I=pi/4*(ro.^4-ri.^4);
s.Z=s.I./ro; s.J=2*s.I; s.G=E./(2*(1+nu));
s.EA=E.*s.A; s.EI=E.*s.I; s.GJ=s.G.*s.J;
s.shearPerForce=(ro.^3-ri.^3)./(3*s.I.*(ro-ri));
s.torsionPerMoment=ro./s.J;
end
