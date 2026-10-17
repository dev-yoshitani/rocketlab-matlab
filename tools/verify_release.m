function verify_release
% Reproduce tests and GUI acceptance using only this public source tree.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); env=startup_project;
folder=fullfile(root,'work','release_verification'); if ~isfolder(folder), mkdir(folder); end
results=runtests(fullfile(root,'tests'),'IncludeSubfolders',true);
writetable(table(results),fullfile(folder,'tests.csv'));
save(fullfile(folder,'tests.mat'),'results');
assert(all([results.Passed]),'rocketlab:ReleaseTests','All public-release tests must pass; incomplete tests are not passes.');
% In R2026b, exportapp/getframe rebuild a scrollable app at its top position.
% Isolate this verification window so CSV captures retain the live viewport.
if ~isprop(groot,'ForceIndependentlyHostedFigures')
 isolated=addprop(groot,'ForceIndependentlyHostedFigures'); hostCleanup=onCleanup(@()delete(isolated)); %#ok<NASGU>
end
ui=launch_app('off'); cleanup=onCleanup(@()delete(ui.Figure));
assert(~isfield(ui,'LoadSources'),'rocketlab:PrivateExtension','Private source adapter must not exist in the public edition.');
capture('home');
ui.QuickDemo.ButtonPushedFcn(ui.QuickDemo,[]);
assert(~isempty(ui.Figure.UserData.result),'rocketlab:ReleaseGUI','Guided demo failed.');
assert(ui.Tabs.SelectedTab==ui.StructureTab,'rocketlab:ReleaseGUI','Guided result not shown.');
capture('structure'); ui.StructureViews.SelectedTab=ui.DeformTab; capture('deformation');
ui.StructureViews.SelectedTab=ui.ChecksTab; capture('checks');
ui.StepInput.ButtonPushedFcn(ui.StepInput,[]); capture('input');
ui.FriendlyTable.Data.thickness_mm(1)=1.5; ui.FriendlyTable.CellEditCallback(ui.FriendlyTable,[]);
s=ui.Figure.UserData;
assert(isempty(s.result)&&s.vehicle.members.thickness(1)==.0015,'rocketlab:ReleaseGUI','Unit conversion or invalidation failed.');
ui.Run.ButtonPushedFcn(ui.Run,[]); ui.StepReport.ButtonPushedFcn(ui.StepReport,[]);
ui.Export.ButtonPushedFcn(ui.Export,[]); s=ui.Figure.UserData;
assert(isfile(fullfile(s.reportFolder,'report.html')),'rocketlab:ReleaseGUI','Report was not saved.');
capture('report');
ui.GoSix.ButtonPushedFcn(ui.GoSix,[]); ui.SixSim.ButtonPushedFcn(ui.SixSim,[]);
s=ui.Figure.UserData; assert(~isempty(s.sixdofResult)&&s.sixdofResult.comparison.passed,'rocketlab:ReleaseGUI','Native flight comparison failed.');
capture('flight'); ui.SixTransfer.ButtonPushedFcn(ui.SixTransfer,[]); s=ui.Figure.UserData;
assert(~isempty(s.result)&&s.result.wholeVehicleStatus=="not_evaluated",'rocketlab:ReleaseGUI','Structural transfer failed.');
assert(all(~ui.FriendlyTable.ColumnEditable),'rocketlab:ReleaseGUI','Transferred configuration is editable.');
capture('flight_structure');
native=s; regularSize=ui.Figure.Position(3:4);
ui.Figure.Position(3:4)=[1100,760]; ui.Tabs.SelectedTab=ui.HomeTab; capture('home_compact');
ui.Figure.Position(3:4)=regularSize;
ui.Figure.Visible='on'; drawnow; pause(2);
ui.StepInput.ButtonPushedFcn(ui.StepInput,[]); ui.InputViews.SelectedTab=ui.CsvTab;
ui.CsvMembers.Value=fullfile('data','demo','members.csv'); ui.CsvParts.Value=fullfile('data','demo','parts.csv');
ui.CsvId.Value='synthetic-csv'; ui.CsvRevision.Value='R1'; ui.CsvLength.Value=1000; ui.CsvOrigin.Value='nose';
ui.CsvReferenceMass.Value='4'; ui.CsvReferenceCG.Value='550'; ui.ImportCSV.ButtonPushedFcn(ui.ImportCSV,[]);
csvState=ui.Figure.UserData; audit=rocketlab.csv_import_record(csvState.vehicle);
assert(~isempty(audit)&&audit.totalMass_kg==4&&abs(audit.cgFromNose_m-.55)<1e-14,'rocketlab:ReleaseCSV','CSV mass/CG failed.');
assert(isempty(csvState.loadCase)&&isempty(csvState.result)&&string(ui.Run.Enable)=="off",'rocketlab:ReleaseCSV','Previous loads survived CSV import.');
capture('csv_input'); scroll(ui.CsvGrid,ui.CsvSummary); drawnow;
assert(isInScrollView(ui.CsvGrid,ui.CsvSummary),'rocketlab:CSVViewport','CSV summary is outside the viewport.'); capture('csv_summary');
ui.Figure.Position(3:4)=[1100,760]; scroll(ui.CsvGrid,'top'); capture('csv_input_compact');
scroll(ui.CsvGrid,ui.CsvSummary); drawnow;
assert(isInScrollView(ui.CsvGrid,ui.CsvSummary),'rocketlab:CSVViewport','CSV summary is outside the compact viewport.'); capture('csv_summary_compact');
summary=struct('schemaVersion',1,'timeUTC',string(datetime('now','TimeZone','UTC')), ...
 'matlab',env.matlab,'release',env.release,'simulink',env.simulink,'aerospaceBlockset',~isempty(which('aerolib6dof2')), ...
 'testsPassed',nnz([results.Passed]),'testsFailed',nnz([results.Failed]),'testsIncomplete',nnz([results.Incomplete]), ...
 'codeHash',rocketlab.code_hash(root),'guidedDemoVerified',true,'displayUnitsVerified',true, ...
 'resultInvalidationVerified',true,'reportExportVerified',true,'nativeFlightComparisonVerified',true, ...
 'postburnStructuralTransferVerified',true,'privateSourceAdapterAbsent',true, ...
 'csvImportVerified',true,'csvTotalMass_kg',audit.totalMass_kg,'csvCGFromNose_m',audit.cgFromNose_m, ...
 'csvLoadSeparationVerified',true,'csvVisualCheckUTC',string(datetime('now','TimeZone','UTC')), ...
 'flightComparison',native.sixdofResult.comparison.maximumErrors,'forceResidual_N',native.sixdofResult.summary.maxForceResidual_N, ...
 'momentResidual_Nm',native.sixdofResult.summary.maxMomentResidual_Nm,'wholeVehicleStatus',native.result.wholeVehicleStatus);
rocketlab.write_json(fullfile(folder,'summary.json'),summary);
disp(summary); fprintf('PUBLIC_RELEASE_VERIFICATION_COMPLETE\n');
 function capture(name)
  drawnow; pause(3); drawnow; file=fullfile(folder,[name '.png']);
  if startsWith(name,'csv_')
   % Verification only: R2026b's CEF screenshot preserves the live scroll.
   windows=matlab.internal.cef.webwindowmanager.instance.windowList;
   match=arrayfun(@(w)strcmp(w.Title,ui.Figure.Name),windows);
   assert(nnz(match)==1,'rocketlab:CaptureWindow','Expected one owned verification window.');
   pixels=windows(match).getScreenshot(); assert(~isempty(pixels)); imwrite(pixels,file);
  else
   exportapp(ui.Figure,file);
  end
  info=imfinfo(file); position=ui.Figure.Position;
  assert(abs(info.Width/info.Height-position(3)/position(4))<.02,'rocketlab:ClippedCapture','The display clipped the app capture.');
 end
end
