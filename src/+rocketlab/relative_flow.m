function r=relative_flow(velocityRelativeBody,extraWindBody,density,soundSpeed,mode)
% Right-handed flight-body frame: xb forward; alpha=atan2(vz,vx).
assert(ismember(string(mode),["snapshot","replay","predict"]),'rocketlab:Mode','Unknown flow mode.');
assert(numel(velocityRelativeBody)==3&&numel(extraWindBody)==3&&density>0&&soundSpeed>0,'rocketlab:Flow','Invalid relative-flow input.');
assert(~strcmp(mode,'replay')||all(extraWindBody==0),'rocketlab:ReplayWind','Replay cannot add wind a second time.');
v=velocityRelativeBody(:)'-extraWindBody(:)'; speed=norm(v);
assert(all(isfinite(v))&&speed>0,'rocketlab:Flow','Relative-flow direction undefined at zero speed.');
r=struct('vector_m_s',v,'speed_m_s',speed,'mach',speed/soundSpeed,'q_Pa',.5*density*speed^2, ...
 'alpha_rad',atan2(v(3),v(1)),'beta_rad',asin(max(-1,min(1,v(2)/speed))),'mode',string(mode));
end
