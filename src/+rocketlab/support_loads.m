function loads = support_loads(loads,L)
% Reactions are added only for explicit ground-test supports.
b=rocketlab.balance(loads);
switch string(loads.boundary)
 case "free", return
 case "cantilever", p=rocketlab.point_loads(0,-b.force,-b.moment);
 case "simply_supported"
  r=[0,-b.moment(3)/L,b.moment(2)/L];
  p=rocketlab.point_loads([0;L],[-b.force-r;r],[-b.moment(1),0,0;0,0,0]);
 otherwise, error('rocketlab:Boundary','Unknown boundary condition.');
end
p.id="support"+string((1:height(p))'); p.role(:)="reaction"; p.partId(:)="fixture";
loads.points=[loads.points;p];
end
