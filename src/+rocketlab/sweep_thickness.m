function comparison = sweep_thickness(vehicle,loadCase,factors)
% Fixed-load snapshots/test cases only; changed flight needs a new trajectory.
assert(ismember(string(loadCase.mode),["snapshot","test"]),'rocketlab:StaleFlight','Thickness change requires flight and loads to be regenerated for replay/predict.');
factors=factors(:); n=numel(factors); mass=zeros(n,1); deflection=mass; tension=mass; status=strings(n,1); inputHash=strings(n,1);
for k=1:n
 v=vehicle; v.members.thickness=v.members.thickness*factors(k); v.revision="sweep-"+string(k);
 r=rocketlab.analyze_case(v,loadCase);
 m=r.vehicle.members; mass(k)=sum(m.density.*m.A.*(m.s1-m.s0));
 deflection(k)=max(hypot(r.sections.wy,r.sections.wz)); tension(k)=max(r.sections.tension);
 status(k)=r.selectedEvaluationStatus; inputHash(k)=rocketlab.hash(jsonencode(v));
end
comparison=table(factors,mass,deflection,tension,status,inputHash, ...
 'VariableNames',{'thicknessFactor','memberMass_kg','maxDeflection_m','maxTension_Pa','status','inputHash'});
end
