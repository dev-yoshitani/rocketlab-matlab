function c=vertical_load_case(h,index,d,length_m)
% Frozen-mass axial load transfer at one exact sample of the vertical history.
assert(isscalar(index)&&index==floor(index)&&index>=1&&index<=numel(h.time_s),'rocketlab:SampleIndex','Choose one recorded sample.');
assert(isfield(h,'accelerationConvention')&&h.accelerationConvention=="coordinate acceleration including gravity",'rocketlab:AccelerationConvention','Explicit acceleration convention is required.');
assert(h.phase(index)=="free_ascent",'rocketlab:FlightPhase','Ground/rail loads need their own reaction model.');
d=rocketlab.validate_vertical_distribution(d,h.parameters,length_m); parts=d.parts;
remaining=h.mass_kg(index)-h.parameters.dryMass;
assert(remaining>=-1e-8,'rocketlab:MassFloor','Flight mass is below the distribution dry mass.');
mass=parts.dryMass_kg+parts.propellantFraction*max(remaining,0);
assert(abs(sum(mass)-h.mass_kg(index))<=1e-8,'rocketlab:MassDistribution','Mapped mass does not match the same flight sample.');
% s points aft/down; flight altitude and acceleration point up.
external=rocketlab.point_loads([d.thrustStation_m;d.dragStation_m],[-h.thrust_N(index),0,0;h.drag_N(index),0,0]);
external.id=["net-thrust";"net-drag"]; external.partId=["motor-interface";"aero-resultant"];
inertia=rocketlab.inertial_loads(mass,[parts.station_m,zeros(height(parts),2)],zeros(3,3,height(parts)), ...
 [-h.acceleration_m_s2(index),0,0],[0,0,0],[0,0,0],[h.parameters.g,0,0]);
inertia.partId=string(parts.id);
c=struct('id',h.id+"-"+h.engine+"-sample-"+string(index),'time_s',h.time_s(index), ...
 'mode',"predict",'configurationHash',string(d.vehicleHash),'boundary',"free",'points',[external;inertia], ...
 'distributed',rocketlab.empty_distributed(),'reference',sum(mass.*parts.station_m)/sum(mass), ...
 'assumptions',string(d.source)+" / "+string(d.loadPath)+" / axial 1DOF, frozen mass, no transverse or local shell evaluation", ...
 'flightSource',struct('historyId',h.id,'engine',h.engine,'sampleIndex',index, ...
 'mass_kg',h.mass_kg(index),'mappedMassDifference_kg',sum(mass)-h.mass_kg(index), ...
 'acceleration_m_s2',h.acceleration_m_s2(index),'q_Pa',h.q_Pa(index)), ...
 'distribution',d);
b=rocketlab.balance(c);
assert(b.balanced,'rocketlab:UnbalancedFlight','Transferred flight loads do not balance; no residual force has been added.');
end
