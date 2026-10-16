function c=compare_sixdof_histories(ref,h)
assert(string(ref.parameterHash)==string(h.parameterHash),'rocketlab:ConfigurationMismatch','Histories must use identical parameters.');
assert(abs(ref.time_s(1)-h.time_s(1))<1e-9&&abs(ref.time_s(end)-h.time_s(end))<1e-9,'rocketlab:EventAlignment','Different intervals cannot be compared.');
aligned=interp1(ref.time_s,ref.state,h.time_s,'pchip');
assert(all(isfinite(aligned),'all'),'rocketlab:EventAlignment','No state extrapolation is permitted.');
qr=aligned(:,7:10); qr=qr./vecnorm(qr,2,2); q=h.state(:,7:10); q=q./vecnorm(q,2,2);
signs=ones(size(q,1),1); signs(sum(q.*qr,2)<0)=-1; q=q.*signs;
angle=4*asin(min(1,vecnorm(q-qr,2,2)/2));
err=[max(vecnorm(aligned(:,1:3)-h.state(:,1:3),2,2)), ...
 max(vecnorm(aligned(:,4:6)-h.state(:,4:6),2,2)),max(angle), ...
 max(vecnorm(aligned(:,11:13)-h.state(:,11:13),2,2))];
tol=[1e-3,1e-3,2e-5,2e-5];
c=struct('passed',all(err<=tol),'quantities',["position_m","velocity_m_s","attitude_rad","angular_rate_rad_s"], ...
 'maximumErrors',err,'absoluteTolerances',tol,'referenceSamples',numel(ref.time_s),'nativeSamples',numel(h.time_s), ...
 'quaternionNormError',max(abs(h.quaternionNorm-1)),'scope',h.model, ...
 'note',"Native Aerospace EOM vs independent MATLAB EOM; common applied-load/environment functions; PCHIP on matching interval; quaternion sign invariant.");
end
