function summary=sixdof_structure_summary(h)
p=h.parameters; indices=find(h.structuralEligible); assert(~isempty(indices),'rocketlab:OpenSystemLoad','No postburn samples in this interval.');
stations=unique([0;p.vehicle.length;p.partStation_m;p.propellantStation_m;p.cpStation_m;p.thrustStation_m;p.vehicle.members.s0;p.vehicle.members.s1]);
x=repelem(stations,2); side=repmat(["left";"right"],numel(stations),1);
peak=zeros(numel(indices),6); residual=zeros(numel(indices),2); bend=zeros(numel(indices),1); where=bend;
% Every point-load interval is affine; absolute component and bending norm maxima occur at its ends.
env=zeros(numel(x),6); owner=zeros(size(env));
for k=1:numel(indices)
 c=rocketlab.sixdof_load_case(h,indices(k)); a=rocketlab.section_forces(c,x,side);
 values=abs([a.N,a.Vy,a.Vz,a.T,a.My,a.Mz]); peak(k,:)=max(values,[],1);
 [bend(k),j]=max(hypot(a.My,a.Mz)); where(k)=x(j);
 update=values>env | owner==0; env(update)=values(update); owner(update)=indices(k);
 b=rocketlab.balance(c); residual(k,:)=[norm(b.force),norm(b.moment)];
end
[~,j]=max(bend);
[~,iq]=max(h.q_Pa); [~,iv]=max(h.airspeed_m_s); [~,it]=max(h.thrust_N);
[~,ia]=max(abs(h.alpha_rad));
sample=[iq;iv;it;ia;indices(j)];
events=table(["max_q";"max_airspeed";"max_thrust";"max_abs_alpha";"max_postburn_bending"],sample,h.time_s(sample), ...
 [h.q_Pa(iq);h.airspeed_m_s(iv);h.thrust_N(it);abs(h.alpha_rad(ia));bend(j)],["Pa";"m/s";"N";"rad";"N m"], ...
 ["simulated interval";"simulated interval";"simulated interval";"simulated interval";"postburn samples only"], ...
 'VariableNames',{'event','sampleIndex','time_s','value','unit','scope'});
envelope=table(x,side);
labels=["N","Vy","Vz","T","My","Mz"];
for k=1:6
 envelope.(char(labels(k)+"_abs"))=env(:,k); envelope.(char(labels(k)+"_sampleIndex"))=owner(:,k);
 envelope.(char(labels(k)+"_time_s"))=h.time_s(owner(:,k));
end
summary=struct('events',events,'history',table(indices,h.time_s(indices),peak,bend,where,residual, ...
 'VariableNames',{'sampleIndex','time_s','componentPeaks','bending_Nm','station_m','balanceResiduals'}), ...
 'envelope',envelope,'samplesEvaluated',numel(indices),'excludedSamples',numel(h.time_s)-numel(indices), ...
 'maxBendingSampleIndex',indices(j),'maxBending_Nm',bend(j), ...
 'maxForceResidual_N',max(residual(:,1)),'maxMomentResidual_Nm',max(residual(:,2)), ...
 'scope',"postburn only; six component maxima at every recorded eligible sample; not a whole-flight envelope");
end
