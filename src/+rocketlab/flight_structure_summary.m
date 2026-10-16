function summary=flight_structure_summary(h,v,d)
% Evaluate every airborne sample; keep the time and section of each axial peak.
v=rocketlab.validate_vehicle(v); d=rocketlab.validate_vertical_distribution(d,h.parameters,v.length);
assert(string(d.vehicleId)==string(v.id),'rocketlab:ConfigurationMismatch','Distribution belongs to another vehicle.');
assert(string(d.vehicleHash)==string(rocketlab.hash(jsonencode(v))),'rocketlab:StaleFlight','Vehicle changed; regenerate flight and mass/load placement.');
indices=find(h.phase=="free_ascent"); assert(~isempty(indices),'rocketlab:FlightPhase','No free-ascent samples.');
stations=unique([0;v.length;d.parts.station_m;d.thrustStation_m;d.dragStation_m]);
x=repelem(stations,2); side=repmat(["left";"right"],numel(stations),1);
peak=zeros(numel(indices),1); peakStation=peak; peakSide=strings(size(peak)); residual=peak;
for k=1:numel(indices)
 c=rocketlab.vertical_load_case(h,indices(k),d,v.length); a=rocketlab.section_forces(c,x,side);
 [peak(k),j]=max(abs(a.N)); peakStation(k)=a.s(j); peakSide(k)=a.side(j);
 b=rocketlab.balance(c); residual(k)=norm(b.force);
end
[~,q]=max(h.q_Pa(indices)); [~,speed]=max(abs(h.velocity_m_s(indices)));
[~,thrust]=max(h.thrust_N(indices)); [~,axial]=max(peak);
pick=[q;speed;thrust;axial]; sample=indices(pick);
events=table(["max_q";"max_speed";"max_thrust";"max_axial_force"],sample,h.time_s(sample), ...
 [h.q_Pa(sample(1));abs(h.velocity_m_s(sample(2)));h.thrust_N(sample(3));peak(axial)], ...
 ["Pa";"m/s";"N";"N"],'VariableNames',{'event','sampleIndex','time_s','value','unit'});
summary=struct('events',events,'history',table(indices,h.time_s(indices),peak,peakStation,peakSide,residual, ...
 'VariableNames',{'sampleIndex','time_s','maxAbsN_N','station_m','side','forceResidual_N'}), ...
 'maxAxialSampleIndex',indices(axial),'maxAxialStation_m',peakStation(axial), ...
 'maxForceResidual_N',max(residual),'samplesEvaluated',numel(indices), ...
 'groundSamplesExcluded',nnz(h.phase~="free_ascent"),'distribution',d, ...
 'scope',"axial 1DOF free ascent, all stored samples; no lateral-load assessment");
end
