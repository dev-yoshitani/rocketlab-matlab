function v=normalize_vehicle(v)
% JSON null allowables remain missing (NaN) after conversion to tables.
if isstruct(v.members)
 fields={'s0','s1','diameter','thickness','E','nu','density','tension','compression','shear','deflection','strengthFactor'};
 for k=1:numel(v.members)
  for j=1:numel(fields)
   key=fields{j}; if isfield(v.members,key)&&isempty(v.members(k).(key)), v.members(k).(key)=NaN; end
  end
 end
 v.members=struct2table(v.members);
end
if ~isfield(v,'joints')||isempty(v.joints), v.joints=table(zeros(0,1),zeros(0,1),zeros(0,1),'VariableNames',{'s','ky','kz'});
elseif isstruct(v.joints), v.joints=struct2table(v.joints); end
end
