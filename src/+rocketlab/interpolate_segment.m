function values = interpolate_segment(history,time,segmentId,columns)
% No interpolation across events, across missing samples, or beyond an interval.
T=history.normalized; mask=T.segment==segmentId; t=T.time_s(mask);
assert(numel(t)>=2 && all(diff(t)>0),'rocketlab:ContinuousSegment','Need a strictly increasing continuous segment.');
assert(all(time>=t(1)&time<=t(end)),'rocketlab:Extrapolation','Requested time is outside segment.');
x=T{mask,cellstr(columns)};
assert(all(isfinite(x),'all'),'rocketlab:MissingSamples','Interpolation across missing values is not permitted.');
values=interp1(t,x,time,'linear');
end
