function folder=save_vehicle_input(vehicle,outputRoot)
% Save a validated input and matching CSV audit in a fresh folder.
v=rocketlab.validate_vehicle(vehicle);
folder=rocketlab.unique_run(outputRoot,'vehicle-input');
rocketlab.write_json(fullfile(folder,'vehicle.json'),v);
audit=rocketlab.csv_import_record(v);
if ~isempty(audit), rocketlab.write_json(fullfile(folder,'input_check.json'),audit); end
end
