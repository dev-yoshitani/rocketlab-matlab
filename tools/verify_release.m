function verify_release
% Reproduce tests and GUI acceptance using only this public source tree.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); env=startup_project;
folder=fullfile(root,'work','release_verification'); if ~isfolder(folder), mkdir(folder); end
results=runtests(fullfile(root,'tests'),'IncludeSubfolders',true);
writetable(table(results),fullfile(folder,'tests.csv'));
save(fullfile(folder,'tests.mat'),'results');
assert(all([results.Passed]),'rocketlab:ReleaseTests','All public-release tests must pass; incomplete tests are not passes.');
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
ui.Figure.Position(3:4)=[1100,760]; ui.Tabs.SelectedTab=ui.HomeTab; capture('home_compact');
summary=struct('schemaVersion',1,'timeUTC',string(datetime('now','TimeZone','UTC')), ...
 'matlab',env.matlab,'release',env.release,'simulink',env.simulink,'aerospaceBlockset',~isempty(which('aerolib6dof2')), ...
 'testsPassed',nnz([results.Passed]),'testsFailed',nnz([results.Failed]),'testsIncomplete',nnz([results.Incomplete]), ...
 'codeHash',rocketlab.code_hash(root),'guidedDemoVerified',true,'displayUnitsVerified',true, ...
 'resultInvalidationVerified',true,'reportExportVerified',true,'nativeFlightComparisonVerified',true, ...
 'postburnStructuralTransferVerified',true,'privateSourceAdapterAbsent',true, ...
 'flightComparison',s.sixdofResult.comparison.maximumErrors,'forceResidual_N',s.sixdofResult.summary.maxForceResidual_N, ...
 'momentResidual_Nm',s.sixdofResult.summary.maxMomentResidual_Nm,'wholeVehicleStatus',s.result.wholeVehicleStatus);
rocketlab.write_json(fullfile(folder,'summary.json'),summary);
disp(summary); fprintf('PUBLIC_RELEASE_VERIFICATION_COMPLETE\n');
 function capture(name)
  drawnow; pause(3); drawnow; file=fullfile(folder,[name '.png']); exportapp(ui.Figure,file);
  info=imfinfo(file); position=ui.Figure.Position;
  assert(abs(info.Width/info.Height-position(3)/position(4))<.02,'rocketlab:ClippedCapture','The display clipped the app capture.');
 end
end
