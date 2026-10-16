function v = validate_vehicle(v)
assert(isfield(v,'schemaVersion') && v.schemaVersion==1,'rocketlab:Schema','schemaVersion must be 1.');
assert(strcmp(v.units,'SI') && strcmp(v.coordinates,'station_RHS'),'rocketlab:Coordinates','SI and station_RHS coordinates required.');
v=rocketlab.normalize_vehicle(v);
m=v.members;
if isstruct(m), m=struct2table(m); end
fields={'id','s0','s1','diameter','thickness','E','nu','density','tension','compression','shear','deflection','strengthFactor','source'};
assert(all(ismember(fields,m.Properties.VariableNames)),'rocketlab:MissingMemberField','Missing required member column.');
assert(height(m)>0 && numel(unique(string(m.id)))==height(m),'rocketlab:Members','Member IDs must be unique.');
m=sortrows(m,'s0');
assert(all(isfinite(m.s0)&isfinite(m.s1)&m.s1>m.s0) && all(abs(m.s0(2:end)-m.s1(1:end-1))<1e-10),'rocketlab:Geometry','Members must be contiguous and nonoverlapping.');
assert(abs(m.s0(1))<1e-10 && abs(m.s1(end)-v.length)<1e-10,'rocketlab:Geometry','Members must cover [0,length].');
assert(all(isnan(m.density)|(isfinite(m.density)&m.density>0)),'rocketlab:Material','Density must be positive or missing.');
assert(all(isnan(m.strengthFactor)|(isfinite(m.strengthFactor)&m.strengthFactor>=1)),'rocketlab:Material','Strength factor must be >=1 or missing.');
sec=rocketlab.tube_section(m.diameter,m.thickness,m.E,m.nu);
for k=string(fieldnames(sec))', m.(k)=sec.(k); end
v.members=m;
if ~isfield(v,'joints') || isempty(v.joints)
    v.joints=table(zeros(0,1),zeros(0,1),zeros(0,1),'VariableNames',{'s','ky','kz'});
elseif isstruct(v.joints), v.joints=struct2table(v.joints);
end
assert(all(v.joints.s>0 & v.joints.s<v.length) && numel(unique(v.joints.s))==height(v.joints),'rocketlab:Joint','Joint positions must be unique and internal.');
assert(all(v.joints.ky>0 & v.joints.kz>0),'rocketlab:JointStiffness','Positive rotational stiffness required; a zero stiffness is a mechanism.');
end
