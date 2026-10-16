function d=validate_vertical_distribution(d,p,length_m)
assert(isfield(d,'vehicleHash')&&strlength(string(d.vehicleHash))==64,'rocketlab:ConfigurationBasis','A normalized vehicle hash is required.');
if isstruct(d.parts), d.parts=struct2table(d.parts); end
parts=d.parts; needed={'id','station_m','dryMass_kg','propellantFraction'};
assert(all(ismember(needed,parts.Properties.VariableNames)) && ~isempty(parts),'rocketlab:MassDistribution','Mass distribution is required.');
assert(numel(unique(string(parts.id)))==height(parts),'rocketlab:MassDistribution','Part IDs must be unique.');
values=parts{:,needed(2:end)};
assert(all(isfinite(values),'all')&&all(values>=0,'all')&&all(parts.station_m<=length_m),'rocketlab:MassDistribution','Invalid mass or station.');
assert(abs(sum(parts.dryMass_kg)-p.dryMass)<1e-10 && abs(sum(parts.propellantFraction)-1)<1e-12,'rocketlab:MassDistribution','Mass distribution must match the flight dry mass and all propellant.');
assert(all(isfinite([d.thrustStation_m,d.dragStation_m]))&&all([d.thrustStation_m,d.dragStation_m]>=0)&&all([d.thrustStation_m,d.dragStation_m]<=length_m),'rocketlab:LoadPosition','Load stations are outside the vehicle.');
assert(strlength(string(d.source))>0 && strlength(string(d.loadPath))>0,'rocketlab:LoadBasis','Load placement and load path need an explicit basis.');
end
