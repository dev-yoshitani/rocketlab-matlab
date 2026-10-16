function result=fem_exchange(action,packet,folder)
% Manual external-solver contract. Never infer local pressure from total drag.
required={'configurationId','geometryFile','units','materials','materialAxes','loadSurfaces','supports','analysisType','source'};
assert(all(isfield(packet,required)),'rocketlab:FemInput','Incomplete FEM packet.');
assert(strcmp(packet.units,'SI'),'rocketlab:FemUnits','FEM exchange uses SI.');
if ~isfile(packet.geometryFile) && strcmp(action,'import')
 packet.geometryFile=fullfile(folder,packet.geometryFile);
end
assert(isfile(packet.geometryFile),'rocketlab:FemGeometry','Geometry file unavailable.');
for key={'inputHash','geometryHash'}
 if isfield(packet,key{1}), packet=rmfield(packet,key{1}); end
end
geometrySource=packet.geometryFile;
packet.geometryHash=rocketlab.hash(geometrySource,true);
[~,geometryName,geometryExt]=fileparts(geometrySource);
packet.geometryFile=[geometryName geometryExt];
packet.inputHash=rocketlab.hash(jsonencode(packet));
switch string(action)
 case "export"
  assert(~isfolder(folder),'rocketlab:OutputExists','FEM package destination must be new.');
  mkdir(folder); [~,name,ext]=fileparts(packet.geometryFile);
  copyfile(geometrySource,fullfile(folder,[name ext]));
  rocketlab.write_json(fullfile(folder,'input.json'),packet); result=packet;
 case "import"
  result=jsondecode(fileread(fullfile(folder,'result.json')));
  requiredResult={'configurationId','inputHash','solverVersion','mesh','convergence','reactions','displacement','evaluationLocations','stress'};
  assert(all(isfield(result,requiredResult)),'rocketlab:FemResult','Incomplete external result.');
  assert(strcmp(result.configurationId,packet.configurationId)&&strcmp(result.inputHash,packet.inputHash),'rocketlab:StaleFEM','FEM result configuration or input hash differs.');
  result.verificationStatus="external_result_requires_review";
 otherwise, error('rocketlab:FemAction','Use export/import.');
end
end
