function tests=test_outputs
tests=functiontests(localfunctions);
end
function setupOnce(t)
startup_project; root=fileparts(fileparts(mfilename('fullpath')));
t.TestData.folder=rocketlab.unique_run(fullfile(root,'work'),'test-output');
end
function testReport(t)
[v,c]=rocketlab.demo_config; r=run_case(v,c,t.TestData.folder);
t.verifyTrue(isfile(fullfile(r.outputFolder,'report.html')));
t.verifyTrue(isfile(fullfile(r.outputFolder,'distributions.svg')));
manifest=jsondecode(fileread(fullfile(r.outputFolder,'manifest.json')));
t.verifyEqual(string(manifest.status),"complete");
t.verifyEqual(string(manifest.codeHash),string(rocketlab.code_hash(fileparts(fileparts(mfilename('fullpath'))))));
t.verifyError(@()export_report(r,r.outputFolder),'rocketlab:OutputExists');
r2=run_case(v,c,t.TestData.folder); t.verifyNotEqual(r.outputFolder,r2.outputFolder);
end
function testUI(t)
ui=launch_app('off'); cleanup=onCleanup(@()delete(ui.Figure));
ui.Demo.ButtonPushedFcn(ui.Demo,[]);
t.verifyEqual(ui.Run.Enable,matlab.lang.OnOffSwitchState.on);
ui.Run.ButtonPushedFcn(ui.Run,[]);
s=ui.Figure.UserData; t.verifyNotEmpty(s.result); t.verifyEqual(s.result.wholeVehicleStatus,"not_evaluated");
ui.InputTable.Data.thickness(1)=.0015; ui.InputTable.CellEditCallback(ui.InputTable,[]);
s=ui.Figure.UserData; t.verifyEmpty(s.result);
t.verifyEqual(ui.Export.Enable,matlab.lang.OnOffSwitchState.off);
end

function testFlightTransferUI(t)
ui=launch_app('off'); cleanup=onCleanup(@()delete(ui.Figure));
ui.FlightRun.ButtonPushedFcn(ui.FlightRun,[]);
state=ui.Figure.UserData; t.verifyNotEmpty(state.flight); t.verifyNotEmpty(state.flightSummary);
ui.FlightEvent.Value='max_thrust'; ui.FlightTransfer.ButtonPushedFcn(ui.FlightTransfer,[]);
state=ui.Figure.UserData; t.verifyNotEmpty(state.result);
index=state.flightSummary.events.sampleIndex(state.flightSummary.events.event=="max_thrust");
t.verifyEqual(state.result.loadCase.time_s,state.flight.time_s(index));
t.verifyEqual(state.result.loadCase.mode,"predict");
t.verifyEqual(ui.Compare.Enable,matlab.lang.OnOffSwitchState.off);
t.verifyEqual(state.result.wholeVehicleStatus,"not_evaluated");
end
