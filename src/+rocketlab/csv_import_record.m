function audit=csv_import_record(v)
% A record belongs only to the normalized vehicle that was imported.
audit=[];
if ~isfield(v,'csvImport')||~isstruct(v.csvImport)||~isscalar(v.csvImport)||~isfield(v.csvImport,'vehicleHash'), return; end
candidate=rmfield(v,'csvImport');
if isequal(string(v.csvImport.vehicleHash),string(rocketlab.hash(jsonencode(candidate))))
 audit=v.csvImport;
 for key=["referenceMass_kg","referenceCGFromNose_m","massDifference_kg","cgDifference_m"]
  if isfield(audit,key)&&isempty(audit.(key)), audit.(key)=NaN; end
 end
end
end
