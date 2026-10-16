function v=apply_input_view(v,view)
% Match rows by immutable part ID; validate before accepting an edit.
m=v.members;
assert(height(view)==height(m)&&isequal(string(view.member),string(m.id)), ...
 'rocketlab:InputRows','Part IDs and their order cannot be changed here.');
m.thickness=view.thickness_mm/1e3; m.E=view.E_GPa*1e9;
m.density=view.density_kg_m3; m.strengthFactor=view.strengthFactor;
v.members=m; v.assumed=true; v=rocketlab.validate_vehicle(v);
end
