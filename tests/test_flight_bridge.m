function tests=test_flight_bridge
tests=functiontests(localfunctions);
end
function setupOnce(t)
startup_project; p=rocketlab.flight_demo_config; t.TestData.h=rocketlab.simulate_vertical(p);
[t.TestData.v,t.TestData.d]=rocketlab.flight_structure_demo(p);
end
function testSameInstantAndSigns(t)
h=t.TestData.h; v=t.TestData.v; d=t.TestData.d;
[~,index]=max(h.thrust_N); c=rocketlab.vertical_load_case(h,index,d,v.length);
t.verifyEqual(c.time_s,h.time_s(index)); t.verifyEqual(c.mode,"predict");
t.verifyEqual(c.points.Fx(1),-h.thrust_N(index)); t.verifyEqual(c.points.Fx(2),h.drag_N(index));
b=rocketlab.balance(c); t.verifyTrue(b.balanced); t.verifyLessThan(norm(b.force),1e-10);
r=rocketlab.analyze_case(v,c); t.verifyEqual(r.wholeVehicleStatus,"not_evaluated");
t.verifyTrue(all(r.sections.Vy==0 & r.sections.Vz==0 & r.sections.My==0 & r.sections.Mz==0));
end
function testRefuseGroundAndMissingMass(t)
h=t.TestData.h; v=t.TestData.v; d=t.TestData.d;
t.verifyError(@()rocketlab.vertical_load_case(h,1,d,v.length),'rocketlab:FlightPhase');
[~,index]=max(h.thrust_N); d.parts.dryMass_kg(1)=d.parts.dryMass_kg(1)+.1;
t.verifyError(@()rocketlab.vertical_load_case(h,index,d,v.length),'rocketlab:MassDistribution');
end
function testNoResidualForceFix(t)
h=t.TestData.h; [~,index]=max(h.thrust_N); h.acceleration_m_s2(index)=h.acceleration_m_s2(index)+1;
t.verifyError(@()rocketlab.vertical_load_case(h,index,t.TestData.d,t.TestData.v.length),'rocketlab:UnbalancedFlight');
end
function testAllAirborneSamples(t)
h=t.TestData.h; s=rocketlab.flight_structure_summary(h,t.TestData.v,t.TestData.d);
t.verifyEqual(s.samplesEvaluated,nnz(h.phase=="free_ascent"));
t.verifyLessThan(s.maxForceResidual_N,1e-8);
[~,iq]=max(h.q_Pa); t.verifyEqual(s.events.sampleIndex(s.events.event=="max_q"),iq);
[~,it]=max(h.thrust_N); t.verifyEqual(s.events.sampleIndex(s.events.event=="max_thrust"),it);
t.verifyNotEqual(iq,it);
[~,i]=max(s.history.maxAbsN_N); t.verifyEqual(s.maxAxialSampleIndex,s.history.sampleIndex(i));
end
function testContinuousDuplicateAlignment(t)
ref=t.TestData.h; h=ref; fields={'time_s','altitude_m','velocity_m_s','mass_kg'};
for k=1:numel(fields)
 value=h.(fields{k}); h.(fields{k})=[value(1:10);value(10);value(11:end)];
end
c=rocketlab.compare_vertical_histories(ref,h); t.verifyTrue(c.passed); t.verifyEqual(c.identicalDuplicateSamples,1);
h.velocity_m_s(11)=h.velocity_m_s(11)+1;
t.verifyError(@()rocketlab.compare_vertical_histories(ref,h),'rocketlab:EventAlignment');
end
function testMissingApogee(t)
ref=t.TestData.h; h=ref; h.apogee_s=NaN;
t.verifyError(@()rocketlab.compare_vertical_histories(ref,h),'rocketlab:MissingApogee');
end

function testChangedVehicleRejectsOldFlight(t)
h=t.TestData.h; v=t.TestData.v; d=t.TestData.d; [~,index]=max(h.thrust_N);
c=rocketlab.vertical_load_case(h,index,d,v.length);
v.members.thickness(1)=v.members.thickness(1)*1.1;
t.verifyError(@()rocketlab.flight_structure_summary(h,v,d),'rocketlab:StaleFlight');
t.verifyError(@()rocketlab.analyze_case(v,c),'rocketlab:StaleFlight');
end
