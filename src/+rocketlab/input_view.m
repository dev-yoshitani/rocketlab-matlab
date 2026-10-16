function view=input_view(v)
% Display ordinary engineering units while retaining SI in the solver.
m=v.members;
view=table(string(m.id),(m.s1-m.s0)*1e3,m.diameter*1e3,m.thickness*1e3,m.E/1e9, ...
 m.density,m.strengthFactor,'VariableNames', ...
 {'member','length_mm','diameter_mm','thickness_mm','E_GPa','density_kg_m3','strengthFactor'});
end
