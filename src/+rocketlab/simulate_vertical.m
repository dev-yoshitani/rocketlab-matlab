function h=simulate_vertical(p)
p=rocketlab.validate_flight(p);
options=odeset('RelTol',p.relTol,'AbsTol',p.absTol,'MaxStep',p.maxStep,'Events',@apogee);
% Solve across every forcing knot. Burnout is an explicit segment boundary.
knots=[p.time(:);p.maxTime]; time=[]; state=[]; initial=p.initial(:); apogeeTime=NaN;
for k=1:numel(knots)-1
 [t,y,te]=ode45(@(t,y)rocketlab.vertical_rhs(t,y,p),knots(k:k+1),initial,options);
 if k>1, t=t(2:end); y=y(2:end,:); end % identical continuous forcing boundary only
 time=[time;t]; state=[state;y]; %#ok<AGROW>
 if ~isempty(te), apogeeTime=te(end); break; end
 initial=state(end,:)';
end
h=rocketlab.vertical_history(p,time,state,apogeeTime,"MATLAB");
 function [value,terminal,direction]=apogee(~,y)
  value=y(2); if y(1)<=1e-8 && y(2)<=0, value=1; end
  terminal=1; direction=-1;
 end
end
