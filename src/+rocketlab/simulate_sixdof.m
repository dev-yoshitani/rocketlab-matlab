function h=simulate_sixdof(p)
p=rocketlab.validate_sixdof(p); options=odeset('RelTol',p.relTol,'AbsTol',p.absTol,'MaxStep',p.maxStep_s);
knots=unique([0;p.time_s(p.time_s<p.stopTime_s);p.stopTime_s]);
time=[]; state=[]; initial=p.initialState;
for k=1:numel(knots)-1
 [t,y]=ode45(@(t,y)rocketlab.sixdof_rhs(t,y,p),knots(k:k+1),initial,options);
 if k>1, t=t(2:end); y=y(2:end,:); end
 time=[time;t]; state=[state;y]; initial=state(end,:)'; %#ok<AGROW>
end
h=rocketlab.sixdof_history(p,time,state,"MATLAB");
end
