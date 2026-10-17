function tests=test_csv_input
tests=functiontests(localfunctions);
end
function setupOnce(t)
startup_project; t.TestData.root=fileparts(fileparts(mfilename('fullpath')));
end
function setup(t)
t.TestData.folder=rocketlab.unique_run(fullfile(t.TestData.root,'work'),'csv-test');
end
function [m,p,o]=example(t)
m=fullfile(t.TestData.root,'data','demo','members.csv');
p=fullfile(t.TestData.root,'data','demo','parts.csv');
o=struct('id',"synthetic-csv",'revision',"R1",'length_mm',1000,'origin',"nose");
end
function testMassCGUnitsAndSources(t)
[m,p,o]=example(t); before=[string(rocketlab.hash(m,true)),string(rocketlab.hash(p,true))];
o.referenceMass_kg=3.9; o.referenceCG_mm=540;
[v,a]=rocketlab.import_vehicle_csv(m,p,o);
t.verifyEqual(a.totalMass_kg,4); t.verifyEqual(a.cgFromNose_m,.55,'AbsTol',1e-14);
t.verifyEqual(a.massDifference_kg,.1,'AbsTol',1e-14); t.verifyEqual(a.cgDifference_m,.01,'AbsTol',1e-14);
t.verifyEqual(v.members.E,[70;70]*1e9); t.verifyEqual(v.members.thickness,[.002;.001]);
t.verifyEqual(v.members.tension,[120;120]*1e6); t.verifyEqual(v.members.deflection,[.01;.01]);
t.verifyEqual(v.length,1); t.verifyEmpty(v.joints); t.verifyTrue(v.assumed);
t.verifyEqual(a.membersFile.name,"members.csv"); t.verifyEqual(a.membersFile.sha256,before(1));
t.verifyEqual([string(rocketlab.hash(m,true)),string(rocketlab.hash(p,true))],before);
t.verifyNotEmpty(rocketlab.csv_import_record(v));
end
function testTailCoordinatesAndReordering(t)
[m,p,o]=example(t); nose=rocketlab.import_vehicle_csv(m,p,o);
mt=readtable(m,'TextType','string'); pt=readtable(p,'TextType','string');
mt{:,{'s0_mm','s1_mm'}}=[1000-mt.s1_mm,1000-mt.s0_mm]; mt=flipud(mt);
pt.position_mm=1000-pt.position_mm;
mf=fullfile(t.TestData.folder,'tail_members.csv'); pf=fullfile(t.TestData.folder,'tail_parts.csv');
writetable(mt,mf); writetable(pt,pf); o.origin="tail"; o.referenceCG_mm=450;
[tail,a]=rocketlab.import_vehicle_csv(mf,pf,o);
t.verifyEqual(tail.members,nose.members); t.verifyEqual(a.parts.station_m,[.1;.7],'AbsTol',1e-14);
t.verifyEqual(a.cgFromNose_m,.55,'AbsTol',1e-14); t.verifyEqual(a.cgDifference_m,0,'AbsTol',1e-14);
end
function testMissingAllowablesStayUnevaluated(t)
[m,p,o]=example(t);
file=fullfile(t.TestData.folder,'missing.csv'); writeText(file,replace(string(fileread(m)),',120,100,60,',',120,,60,'));
[v,a]=rocketlab.import_vehicle_csv(file,p,o);
t.verifyTrue(all(isnan(v.members.compression))); t.verifyTrue(isnan(a.referenceMass_kg));
[~,c]=rocketlab.demo_config; r=rocketlab.analyze_case(v,c);
t.verifyEqual(r.wholeVehicleStatus,"not_evaluated"); t.verifyEqual(r.selectedEvaluationStatus,"incomplete");
end
function testHeaderAndNumericDiagnostics(t)
[m,p,o]=example(t); original=fileread(m); file=fullfile(t.TestData.folder,'invalid.csv');
cases={replace(original,'s0_mm','s0_m'),1,'s0_mm'; ...
 replace(original,'front,0,500','front,abc,500'),2,'s0_mm'; ...
 replace(original,'front,0,500','front,,500'),2,'s0_mm'; ...
 replace(original,'front,0,500','front,1+2i,500'),2,'s0_mm'; ...
 replace(original,'2700,120','2700,NaN'),2,'tension_MPa'; ...
 replace(original,'2700,120','2700,Inf'),2,'tension_MPa'};
for k=1:size(cases,1)
 writeText(file,cases{k,1});
 verifyDiagnostic(t,@()rocketlab.import_vehicle_csv(file,p,o),'invalid.csv',cases{k,2},cases{k,3});
end
end
function testInvalidGeometryAndMaterial(t)
[m,p,o]=example(t); original=readtable(m,'TextType','string');
changes={'s0_mm',2,501; 's0_mm',2,499; 's0_mm',1,-1; 's1_mm',2,999; ...
 's1_mm',1,0; 'diameter_mm',1,0; 'thickness_mm',1,25; 'E_GPa',1,0; ...
 'nu',1,.5; 'density_kg_m3',1,-1; 'tension_MPa',1,-1; 'strengthFactor',1,.9};
file=fullfile(t.TestData.folder,'geometry.csv');
for k=1:size(changes,1)
 mt=original; key=changes{k,1}; row=changes{k,2}; mt.(key)(row)=changes{k,3}; writetable(mt,file);
 verifyDiagnostic(t,@()rocketlab.import_vehicle_csv(file,p,o),'geometry.csv',row+1,key);
end
end
function testInvalidIdsSourcesAndPartData(t)
[m,p,o]=example(t); mt=readtable(m,'TextType','string'); pt=readtable(p,'TextType','string');
mf=fullfile(t.TestData.folder,'members.csv'); pf=fullfile(t.TestData.folder,'parts.csv');
mt.id(2)=mt.id(1); writetable(mt,mf);
verifyDiagnostic(t,@()rocketlab.import_vehicle_csv(mf,p,o),'members.csv',3,'id');
mt=readtable(m,'TextType','string'); mt.source(1)=""; writetable(mt,mf);
verifyDiagnostic(t,@()rocketlab.import_vehicle_csv(mf,p,o),'members.csv',2,'source');
for key=["id","source"]
 q=pt; q.(key)(2)=q.(key)(1); if key=="source", q.source(2)=""; end
 writetable(q,pf); verifyDiagnostic(t,@()rocketlab.import_vehicle_csv(m,pf,o),'parts.csv',3,key);
end
for values={[-1;3],[0;0],[NaN;3]}
 q=pt; q.mass_kg=values{1}; writetable(q,pf);
 t.verifyError(@()rocketlab.import_vehicle_csv(m,pf,o),'rocketlab:CSVInput');
end
q=pt; q.position_mm(2)=1001; writetable(q,pf);
verifyDiagnostic(t,@()rocketlab.import_vehicle_csv(m,pf,o),'parts.csv',3,'position_mm');
end
function testExplicitOptionsAndReferences(t)
[m,p,o]=example(t);
for origin=["choose","", "CAD"]
 x=o; x.origin=origin; t.verifyError(@()rocketlab.import_vehicle_csv(m,p,x),'rocketlab:CSVOptions');
end
x=o; x.id=""; t.verifyError(@()rocketlab.import_vehicle_csv(m,p,x),'rocketlab:CSVOptions');
x=o; x.length_mm=0; t.verifyError(@()rocketlab.import_vehicle_csv(m,p,x),'rocketlab:CSVOptions');
x=o; x.referenceMass_kg=-1; t.verifyError(@()rocketlab.import_vehicle_csv(m,p,x),'rocketlab:CSVOptions');
x=o; x.referenceCG_mm=1001; t.verifyError(@()rocketlab.import_vehicle_csv(m,p,x),'rocketlab:CSVOptions');
end
function testUnicodeAndBOM(t)
[m,p,o]=example(t); file=fullfile(t.TestData.folder,'unicode.csv');
writeText(file,string(char(65279))+replace(string(fileread(m)),"synthetic example","架空の部材・単位確認"));
v=rocketlab.import_vehicle_csv(file,p,o); t.verifyEqual(v.members.source,repmat("架空の部材・単位確認",2,1));
end
function testSaveRoundTripAndStaleAudit(t)
[m,p,o]=example(t); v=rocketlab.import_vehicle_csv(m,p,o);
folder=rocketlab.save_vehicle_input(v,t.TestData.folder);
saved=rocketlab.validate_vehicle(jsondecode(fileread(fullfile(folder,'vehicle.json'))));
t.verifyNotEmpty(rocketlab.csv_import_record(saved)); t.verifyTrue(isfile(fullfile(folder,'input_check.json')));
audit=rocketlab.csv_import_record(saved); t.verifyTrue(isnan(audit.massDifference_kg));
t.verifyNotEqual(rocketlab.save_vehicle_input(v,t.TestData.folder),folder);
view=rocketlab.input_view(saved); view.thickness_mm(1)=1.5; changed=rocketlab.apply_input_view(saved,view);
t.verifyFalse(isfield(changed,'csvImport'));
folder=rocketlab.save_vehicle_input(changed,t.TestData.folder); t.verifyFalse(isfile(fullfile(folder,'input_check.json')));
end
function testOnlyMatchingRecordInReport(t)
[m,p,o]=example(t); v=rocketlab.import_vehicle_csv(m,p,o); [~,c]=rocketlab.demo_config;
r=rocketlab.analyze_case(v,c); folder=export_report(r,fullfile(t.TestData.folder,'report'));
t.verifyTrue(isfile(fullfile(folder,'input_check.json'))); t.verifyTrue(contains(fileread(fullfile(folder,'report.html')),'CSV入力の照合'));
v.members.thickness(1)=.0015; r=rocketlab.analyze_case(v,c);
folder=export_report(r,fullfile(t.TestData.folder,'edited-report'));
t.verifyFalse(isfile(fullfile(folder,'input_check.json'))); t.verifyFalse(isfield(r.vehicle,'csvImport'));
end
function testGUIImportLoadSaveAndEdit(t)
[m,p,~]=example(t); loadFile=fullfile(t.TestData.root,'data','demo','load_case.json');
ui=createUI(t,{m,p,loadFile},t.TestData.folder); ui.QuickDemo.ButtonPushedFcn(ui.QuickDemo,[]);
ui.ChooseMembers.ButtonPushedFcn(ui.ChooseMembers,[]); ui.ChooseParts.ButtonPushedFcn(ui.ChooseParts,[]);
fillOptions(ui); ui.ImportCSV.ButtonPushedFcn(ui.ImportCSV,[]); state=ui.Figure.UserData;
t.verifyEmpty(state.result); t.verifyEmpty(state.loadCase); t.verifyEqual(string(ui.Run.Enable),"off");
ui.Run.ButtonPushedFcn(ui.Run,[]); t.verifyEmpty(ui.Figure.UserData.result);
t.verifyTrue(contains(join(string(ui.CsvSummary.Value)),"550"));
ui.SaveInput.ButtonPushedFcn(ui.SaveInput,[]);
files=dir(fullfile(t.TestData.folder,'vehicle-input*','vehicle.json')); t.verifyNumElements(files,1);
ui.OpenLoad.ButtonPushedFcn(ui.OpenLoad,[]); t.verifyEqual(string(ui.Run.Enable),"on");
ui.Run.ButtonPushedFcn(ui.Run,[]); t.verifyNotEmpty(ui.Figure.UserData.result);
ui.FriendlyTable.Data.thickness_mm(1)=1.5; ui.FriendlyTable.CellEditCallback(ui.FriendlyTable,[]);
t.verifyEmpty(ui.Figure.UserData.result); t.verifyFalse(isfield(ui.Figure.UserData.vehicle,'csvImport'));
t.verifyFalse(contains(join(string(ui.CsvSummary.Value)),"550"));
end
function testGUIFailedAndCancelledImportPreservesInput(t)
[m,p,~]=example(t); ui=createUI(t,{0,0},0); ui.QuickDemo.ButtonPushedFcn(ui.QuickDemo,[]);
before=ui.Figure.UserData;
ui.ChooseMembers.ButtonPushedFcn(ui.ChooseMembers,[]); ui.Open.ButtonPushedFcn(ui.Open,[]);
t.verifyEqual(ui.Figure.UserData,before);
ui.CsvMembers.Value=m; ui.CsvParts.Value=p; fillOptions(ui); ui.CsvLength.Value=999;
ui.ImportCSV.ButtonPushedFcn(ui.ImportCSV,[]); t.verifyEqual(ui.Figure.UserData,before);
end
function testGUIJSONReloadAndInvalidLoadPreservation(t)
[m,p,o]=example(t); v=rocketlab.import_vehicle_csv(m,p,o); folder=rocketlab.save_vehicle_input(v,t.TestData.folder);
file=fullfile(folder,'vehicle.json'); loadFile=fullfile(t.TestData.root,'data','demo','load_case.json');
invalid=fullfile(t.TestData.folder,'invalid-load.json'); writeText(invalid,'{}');
ui=createUI(t,{file,loadFile,invalid,0},0); ui.Open.ButtonPushedFcn(ui.Open,[]);
t.verifyNotEmpty(rocketlab.csv_import_record(ui.Figure.UserData.vehicle));
ui.Run.ButtonPushedFcn(ui.Run,[]); before=ui.Figure.UserData;
ui.OpenLoad.ButtonPushedFcn(ui.OpenLoad,[]); t.verifyEqual(ui.Figure.UserData,before);
ui.OpenLoad.ButtonPushedFcn(ui.OpenLoad,[]); t.verifyEqual(ui.Figure.UserData,before);
end
function ui=createUI(t,files,folder)
index=0; dialogs=struct('openFile',@open,'chooseFolder',@(~,~)folder);
ui=launch_app('off',dialogs); t.addTeardown(@()delete(ui.Figure));
 function [file,path]=open(~,~)
  index=index+1; chosen=files{index};
  if isequal(chosen,0), file=0; path=0; else, [path,n,e]=fileparts(chosen); file=[n e]; end
 end
end
function fillOptions(ui)
ui.CsvId.Value='synthetic-csv'; ui.CsvRevision.Value='R1'; ui.CsvLength.Value=1000; ui.CsvOrigin.Value='nose';
end
function verifyDiagnostic(t,callback,file,row,column)
try, callback(); t.assertFail('Expected an input error.');
catch e
 t.verifyEqual(e.identifier,'rocketlab:CSVInput'); t.verifyTrue(contains(e.message,file));
 t.verifyTrue(contains(e.message,sprintf('行 %d',row))); t.verifyTrue(contains(e.message,string(column)));
end
end
function writeText(file,text)
fid=fopen(file,'w','n','UTF-8'); clean=onCleanup(@()fclose(fid)); fprintf(fid,'%s',text);
end
