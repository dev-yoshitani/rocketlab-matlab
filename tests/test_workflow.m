function tests=test_workflow
tests=functiontests(localfunctions);
end
function setupOnce(~)
startup_project;
end
function testDisplayUnitsAndRoundTrip(t)
[v,~]=rocketlab.demo_config; a=rocketlab.input_view(v);
t.verifyEqual(a.thickness_mm,[2;1]); t.verifyEqual(a.E_GPa,[70;70]);
a.thickness_mm(1)=1.5; a.E_GPa(1)=75; a.density_kg_m3(1)=2800;
out=rocketlab.apply_input_view(v,a);
t.verifyEqual(out.members.thickness(1),.0015,'AbsTol',1e-15);
t.verifyEqual(out.members.E(1),75e9); t.verifyEqual(out.members.density(1),2800);
again=rocketlab.input_view(out); t.verifyEqual(again.thickness_mm,a.thickness_mm,'AbsTol',1e-12);
end
function testInitialWindowFitsScreen(t)
ui=launch_app('off'); cleanup=onCleanup(@()delete(ui.Figure));
screen=get(groot,'ScreenSize'); position=ui.Figure.Position;
t.verifyLessThanOrEqual(position(3),screen(3)-80);
t.verifyLessThanOrEqual(position(4),screen(4)-120);
t.verifyGreaterThanOrEqual(ui.SixHeight.Parent.Parent.RowHeight{3},250);
t.verifyEqual(string(ui.SixHeight.Parent.Parent.Scrollable),"on");
t.verifyGreaterThanOrEqual(ui.FlightAxes.Parent.RowHeight{4},250);
if isfield(ui,'PropulsionAxes'), t.verifyGreaterThanOrEqual(ui.PropulsionAxes.Parent.RowHeight{2},250); end
end
function testRejectImpossibleInput(t)
[v,~]=rocketlab.demo_config; a=rocketlab.input_view(v); a.thickness_mm(1)=a.diameter_mm(1);
t.verifyError(@()rocketlab.apply_input_view(v,a),'rocketlab:Geometry');
a=rocketlab.input_view(v); a.member=flipud(a.member);
t.verifyError(@()rocketlab.apply_input_view(v,a),'rocketlab:InputRows');
end
function testGuidedDemoAndNavigation(t)
ui=launch_app('off'); cleanup=onCleanup(@()delete(ui.Figure));
t.verifyEqual(ui.Tabs.SelectedTab,ui.HomeTab); t.verifyEqual(string(ui.Run.Enable),"off");
ui.QuickDemo.ButtonPushedFcn(ui.QuickDemo,[]); state=ui.Figure.UserData;
t.verifyNotEmpty(state.result); t.verifyEqual(state.result.wholeVehicleStatus,"not_evaluated");
t.verifyEqual(ui.Tabs.SelectedTab,ui.StructureTab); t.verifyEqual(string(ui.StepReport.Enable),"on");
t.verifyTrue(contains(string(ui.BendingValue.Text),'N m'));
ui.StepReport.ButtonPushedFcn(ui.StepReport,[]); t.verifyEqual(ui.Tabs.SelectedTab,ui.ReportTab);
ui.StepInput.ButtonPushedFcn(ui.StepInput,[]); t.verifyEqual(ui.Tabs.SelectedTab,ui.InputTab);
end
function testFriendlyEditInvalidatesReport(t)
ui=launch_app('off'); cleanup=onCleanup(@()delete(ui.Figure));
ui.QuickDemo.ButtonPushedFcn(ui.QuickDemo,[]); ui.Export.ButtonPushedFcn(ui.Export,[]);
state=ui.Figure.UserData; t.verifyTrue(isfile(fullfile(state.reportFolder,'report.html')));
t.verifyEqual(string(ui.OpenReport.Enable),"on");
ui.FriendlyTable.Data.thickness_mm(1)=1.5; ui.FriendlyTable.CellEditCallback(ui.FriendlyTable,[]);
state=ui.Figure.UserData; t.verifyEmpty(state.result); t.verifyEqual(state.reportFolder,"");
t.verifyEqual(state.vehicle.members.thickness(1),.0015,'AbsTol',1e-15);
t.verifyEqual(string(ui.Export.Enable),"off"); t.verifyEqual(string(ui.OpenReport.Enable),"off");
ui.Run.ButtonPushedFcn(ui.Run,[]); state=ui.Figure.UserData;
t.verifyEqual(state.result.vehicle.members.thickness(1),.0015,'AbsTol',1e-15);
end
function testInvalidEditPreservesAcceptedInput(t)
ui=launch_app('off'); cleanup=onCleanup(@()delete(ui.Figure)); ui.Demo.ButtonPushedFcn(ui.Demo,[]);
before=ui.Figure.UserData.vehicle; ui.FriendlyTable.Data.thickness_mm(1)=100;
ui.FriendlyTable.CellEditCallback(ui.FriendlyTable,[]); state=ui.Figure.UserData;
t.verifyEqual(state.vehicle,before); t.verifyEqual(ui.FriendlyTable.Data.thickness_mm(1),2);
t.verifyTrue(contains(string(ui.Status.Text),'確認'));
end
