function r=recovery_sensitivity(history,baseTime,delays,segmentId,cdArea,openingFactor,basis)
% Equivalent opening-load sensitivity, not a time-resolved inflation/shock model.
assert(isfinite(cdArea)&&cdArea>0&&isfinite(openingFactor)&&openingFactor>0&&strlength(string(basis))>0,'rocketlab:RecoveryInput','CdS, opening factor and source required.');
time=baseTime+delays(:); q=NaN(size(time)); speed=q; force=q; status=repmat("outside_data",size(time));
T=history.normalized; mask=T.segment==segmentId; interval=T.time_s(mask);
assert(numel(interval)>=2,'rocketlab:ContinuousSegment','Missing continuous interval.');
valid=time>=min(interval)&time<=max(interval);
if any(valid)
 vals=rocketlab.interpolate_segment(history,time(valid),segmentId,["q_Pa","speed_m_s"]);
 q(valid)=vals(:,1); speed(valid)=vals(:,2); force(valid)=q(valid)*cdArea*openingFactor; status(valid)="assumed_model";
end
r=table(delays(:),time,speed,q,force,status,repmat(string(basis),numel(time),1), ...
 'VariableNames',{'delay_s','openingTime_s','airSpeed_m_s','q_Pa','equivalentOpeningForce_N','status','basis'});
end
