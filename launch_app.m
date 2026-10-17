function ui = launch_app(visible,dialogs)
% Guided workspace. Display units are converted to SI before calculation.
if nargin<1, visible='on'; end
if nargin<2, dialogs=struct; end
if ~isfield(dialogs,'openFile'), dialogs.openFile=@uigetfile; end
if ~isfield(dialogs,'chooseFolder'), dialogs.chooseFolder=@uigetdir; end
environment=startup_project; root=fileparts(mfilename('fullpath'));
state=struct('vehicle',[],'loadCase',[],'result',[],'import',[],'cancelled',false,'revision',0,'running',false,'flight',[],'flightVehicle',[],'flightDistribution',[],'flightSummary',[],'flightOutputFolder',"",'flightComparison',[],'modelPath',"",'sixdofResult',[],'reportFolder',"");
ink=[.12,.18,.27]; accent=[.03,.40,.59]; muted=[.38,.45,.53]; paper=[.96,.97,.985];
screen=get(groot,'ScreenSize');
window=[screen(1)+40,screen(2)+50,min(1380,screen(3)-80),min(840,screen(4)-120)];
fig=uifigure('Name','RocketLab 解析ワークスペース','Position',window,'Visible',visible,'Color',paper);
if isprop(fig,'Theme'), fig.Theme='light'; end
main=uigridlayout(fig,[5,1]); main.RowHeight={66,48,'1x',34,22}; main.Padding=[20,14,20,10]; main.RowSpacing=8;
header=uigridlayout(main,[1,2]); header.ColumnWidth={'1x',270}; header.Padding=[0,0,0,0];
heading=uigridlayout(header,[2,1]); heading.RowHeight={34,24}; heading.Padding=[0,0,0,0];
uilabel(heading,'Text','RocketLab 解析ワークスペース','FontSize',23,'FontWeight','bold');
uilabel(heading,'Text','機体の入力から、飛行と構造の結果、レポートまで。','FontSize',13);
ui.Environment=uilabel(header,'WordWrap','on','HorizontalAlignment','right','Text',sprintf('MATLAB %s\nSimulink: %s',environment.release,available(environment.simulink)));
workflow=uigridlayout(main,[1,4]); workflow.ColumnWidth={180,180,180,'1x'}; workflow.Padding=[0,0,0,0];
ui.StepInput=uibutton(workflow,'Text','1  入力を選ぶ','ButtonPushedFcn',@goInput);
ui.Run=uibutton(workflow,'Text','2  構造を計算','ButtonPushedFcn',@calculate,'Enable','off');
ui.StepReport=uibutton(workflow,'Text','3  レポートへ','ButtonPushedFcn',@goReport,'Enable','off');
ui.NextAction=uilabel(workflow,'Text','最初は「構造デモを試す」から始められます。','WordWrap','on');
tabs=uitabgroup(main);
home=uitab(tabs,'Title','はじめに'); input=uitab(tabs,'Title','機体の入力');
flight=uitab(tabs,'Title','鉛直飛行'); sixdof=uitab(tabs,'Title','姿勢を含む飛行');
structure=uitab(tabs,'Title','構造の結果'); compare=uitab(tabs,'Title','レポートと比較'); details=uitab(tabs,'Title','計算の根拠');
ui.Tabs=tabs; ui.HomeTab=home; ui.InputTab=input; ui.StructureTab=structure; ui.ReportTab=compare; ui.SixTab=sixdof;

g=uigridlayout(home,[3,1]); g.RowHeight={96,230,210}; g.Padding=[24,20,24,20]; g.Scrollable='on';
intro=uigridlayout(g,[2,1]); intro.RowHeight={40,'1x'}; intro.Padding=[0,0,0,0];
uilabel(intro,'Text','まずはデモで、結果の見方をつかむ','FontSize',24,'FontWeight','bold');
uilabel(intro,'Text','架空の機体を使います。最初のデモは、入力の準備と構造計算をまとめて実行します。','WordWrap','on','FontSize',14);
cards=uigridlayout(g,[1,3]); cards.ColumnWidth={'1x','1x','1x'}; cards.Padding=[0,0,0,0]; cards.ColumnSpacing=16;
ui.QuickDemo=card(cards,'構造デモを試す','軸力、曲げ、変形を見て、レポートを保存する。MATLABだけで実行できます。','デモを計算する',@quickDemo);
ui.GoFlight=card(cards,'飛行を見てみる','高度と荷重の変化を計算する。Simulinkとの比較も選べます。','鉛直飛行を開く',@(~,~)navigate(flight));
ui.GoSix=card(cards,'姿勢まで見てみる','横風と回転を含む飛行を計算し、燃焼後の荷重を構造へ渡す。','姿勢を含む飛行を開く',@(~,~)navigate(sixdof));
help=uigridlayout(g,[5,1]); help.RowHeight={34,36,44,44,'1x'}; help.Padding=[0,8,0,0];
uilabel(help,'Text','自分の入力を使うとき','FontSize',17,'FontWeight','bold');
ui.GoInput=uibutton(help,'Text','CSVまたはJSONの入力画面へ','ButtonPushedFcn',@(~,~)navigate(input));
uilabel(help,'Text','1  機体の入力で、板厚を mm、ヤング率を GPa で確認する。','WordWrap','on');
uilabel(help,'Text','2  構造の結果でグラフと評価を確認し、3  レポートへ進む。','WordWrap','on');
uilabel(help,'Text','計算する範囲と仮定は「計算の根拠」で確認できます。結果には、入力不足と選択した評価の充足を別々に表示します。','WordWrap','on','FontColor',muted);

g=uigridlayout(input,[4,1]); g.RowHeight={44,40,'1x',110};
actions=uigridlayout(g,[1,2]); actions.ColumnWidth={'1x','1x'}; actions.Padding=[0,0,0,0];
ui.Demo=uibutton(actions,'Text','架空デモの入力を読み込む','ButtonPushedFcn',@loadDemo);
ui.Open=uibutton(actions,'Text','自分の機体JSONと荷重JSONを読み込む','ButtonPushedFcn',@openConfig);
ui.InputNote=uitextarea(g,'Editable','off','Value',{'日常単位の表を編集すると、計算用のSI単位へ変換します。荷重と構成を先に選んでください。'});
inputViews=uitabgroup(g); simple=uitab(inputViews,'Title','かんたん設定'); advanced=uitab(inputViews,'Title','詳細の入力（SI単位）');
ui.InputViews=inputViews; ui.CsvTab=uitab(inputViews,'Title','CSVから入力');
csv=uigridlayout(ui.CsvTab,[9,1]); csv.RowHeight={55,34,34,24,34,24,34,40,110}; csv.Scrollable='on';
ui.CsvGrid=csv;
uilabel(csv,'Text','両CSVと基準重心は同じ原点で入力します。連続円管梁を作ります。接合ありは機体JSONを使ってください。','WordWrap','on');
row=uigridlayout(csv,[1,2]); row.ColumnWidth={160,'1x'}; row.Padding=[0,0,0,0];
ui.ChooseMembers=uibutton(row,'Text','部材CSVを選ぶ','ButtonPushedFcn',@(~,~)chooseCsv('members'));
ui.CsvMembers=uieditfield(row,'text','Editable','off','Placeholder','data/templates/members.csv の様式');
row=uigridlayout(csv,[1,2]); row.ColumnWidth={160,'1x'}; row.Padding=[0,0,0,0];
ui.ChooseParts=uibutton(row,'Text','部品CSVを選ぶ','ButtonPushedFcn',@(~,~)chooseCsv('parts'));
ui.CsvParts=uieditfield(row,'text','Editable','off','Placeholder','data/templates/parts.csv の様式');
row=uigridlayout(csv,[1,3]); row.Padding=[0,0,0,0];
for label={'機体ID','改訂','全長 [mm]'}, uilabel(row,'Text',label{1}); end
row=uigridlayout(csv,[1,3]); row.Padding=[0,0,0,0];
ui.CsvId=uieditfield(row,'text','Placeholder','例: my-vehicle'); ui.CsvRevision=uieditfield(row,'text','Placeholder','例: R1');
ui.CsvLength=uieditfield(row,'numeric','Limits',[0 Inf],'Value',0);
row=uigridlayout(csv,[1,3]); row.Padding=[0,0,0,0];
for label={'CSVの位置基準','基準質量 [kg]・任意','基準重心 [mm]・任意'}, uilabel(row,'Text',label{1}); end
row=uigridlayout(csv,[1,3]); row.Padding=[0,0,0,0];
ui.CsvOrigin=uidropdown(row,'Items',{'選択してください','ノーズから','後端から'},'ItemsData',{'choose','nose','tail'});
ui.CsvReferenceMass=uieditfield(row,'text','Placeholder','空欄なら比較なし'); ui.CsvReferenceCG=uieditfield(row,'text','Placeholder','空欄なら比較なし');
row=uigridlayout(csv,[1,3]); row.Padding=[0,0,0,0];
ui.ImportCSV=uibutton(row,'Text','CSVを読込・照合','ButtonPushedFcn',@importCsv);
ui.SaveInput=uibutton(row,'Text','機体JSONと照合を保存','Enable','off','ButtonPushedFcn',@saveInput);
ui.OpenLoad=uibutton(row,'Text','荷重JSONを選ぶ','Enable','off','ButtonPushedFcn',@openLoad);
ui.CsvSummary=uitextarea(csv,'Editable','off','Value',{'部品表は全機の質量を重複なく記入します。部材表の円管質量は加算しません。';'基準値との差だけを表示し、自動で合否を判定しません。'});
simpleGrid=uigridlayout(simple,[1,1]); ui.FriendlyTable=uitable(simpleGrid,'CellEditCallback',@editFriendly);
ui.FriendlyTable.ColumnName={'部材','長さ [mm]','外径 [mm]','板厚 [mm]','ヤング率 [GPa]','密度 [kg/m3]','要求安全率'};
ui.FriendlyTable.ColumnWidth={110,100,100,100,150,125,'auto'}; ui.FriendlyTable.RowName={};
advancedGrid=uigridlayout(advanced,[1,1]); ui.InputTable=uitable(advancedGrid,'CellEditCallback',@editInput);
ui.Issues=uitextarea(g,'Editable','off','Value',{'入力待ちです。上のボタンからデモ、または自分の入力を選びます。'});

g=uigridlayout(flight,[5,1]); g.RowHeight={42,44,44,280,130}; g.Scrollable='on';
uilabel(g,'Text','1  飛行を計算 → 2  時刻を選択 → 3  同じ時刻の構造を確認','FontSize',15,'FontWeight','bold');
flightBar=uigridlayout(g,[1,3]); flightBar.ColumnWidth={'1x','1x','1x'};
ui.FlightRun=uibutton(flightBar,'Text','MATLABでデモを計算','ButtonPushedFcn',@flightDemo);
ui.FlightSim=uibutton(flightBar,'Text','Simulinkと比較する','ButtonPushedFcn',@flightSim);
ui.FlightModel=uibutton(flightBar,'Text','計算したモデルを開く','ButtonPushedFcn',@openFlightModel,'Enable','off');
if ~environment.simulink, ui.FlightSim.Enable='off'; end
transferBar=uigridlayout(g,[1,2]); transferBar.ColumnWidth={250,'1x'};
ui.FlightEvent=uidropdown(transferBar,'Items',{'最大動圧の時刻','最大速度の時刻','最大推力の時刻','最大軸力の時刻'}, ...
 'ItemsData',{'max_q','max_speed','max_thrust','max_axial_force'},'Value','max_axial_force');
ui.FlightTransfer=uibutton(transferBar,'Text','この時刻の構造を確認する','ButtonPushedFcn',@transferFlight,'Enable','off');
ui.FlightAxes=uiaxes(g); ui.FlightSummary=uitextarea(g,'Editable','off','Value',{'架空の機体による鉛直1次元の飛行です。横風、姿勢、回収は対象に含みません。'});

g=uigridlayout(sixdof,[5,1]); g.RowHeight={42,44,280,145,120}; g.Scrollable='on';
uilabel(g,'Text','姿勢を含む飛行（6自由度） / 固定重心の架空機体を4秒間計算','FontSize',15,'FontWeight','bold');
sixBar=uigridlayout(g,[1,4]); sixBar.ColumnWidth={'1x','1x','1x','1x'};
ui.SixRun=uibutton(sixBar,'Text','MATLABで計算','ButtonPushedFcn',@(~,~)runSix("MATLAB"));
ui.SixSim=uibutton(sixBar,'Text','Simulinkと比較','ButtonPushedFcn',@(~,~)runSix("Simulink"));
ui.SixTransfer=uibutton(sixBar,'Text','燃焼後の最大曲げを確認','Enable','off','ButtonPushedFcn',@transferSix);
ui.SixModel=uibutton(sixBar,'Text','モデルを開く','Enable','off','ButtonPushedFcn',@openSixModel);
if ~environment.simulink || isempty(which('aerolib6dof2')), ui.SixSim.Enable='off'; end
charts=uigridlayout(g,[1,2]); ui.SixHeight=uiaxes(charts); ui.SixRates=uiaxes(charts);
ui.SixEvents=uitable(g); ui.SixEvents.RowName={};
ui.SixNote=uitextarea(g,'Editable','off','Value',{'横風、姿勢、角速度、質量と慣性の変化を計算します。';'構造への受渡しは燃焼終了後です。重心移動、レール、分離、開傘は未対応です。'});

g=uigridlayout(structure,[3,1]); g.RowHeight={90,'1x',85};
summary=uigridlayout(g,[1,3]); summary.ColumnWidth={'1x','1x','1x'}; summary.Padding=[0,0,0,0];
ui.BendingValue=metric(summary,'最大の曲げモーメント','計算待ち');
ui.DisplacementValue=metric(summary,'最大の相対変位','計算待ち');
ui.EvaluationValue=metric(summary,'選択した評価の状態','未評価');
ui.StructureViews=uitabgroup(g); ui.LoadTab=uitab(ui.StructureViews,'Title','力と曲げ'); ui.DeformTab=uitab(ui.StructureViews,'Title','変形とねじり'); ui.ChecksTab=uitab(ui.StructureViews,'Title','部材ごとの評価');
plots=uigridlayout(ui.LoadTab,[1,2]); ui.LoadAxes=uiaxes(plots); ui.BendAxes=uiaxes(plots);
plots=uigridlayout(ui.DeformTab,[1,3]); ui.ShapeAxes=uiaxes(plots); ui.EquivalentAxes=uiaxes(plots); ui.TorqueAxes=uiaxes(plots);
checksGrid=uigridlayout(ui.ChecksTab,[1,1]); ui.CheckTable=uitable(checksGrid,'CellSelectionCallback',@selectCheck);
ui.Detail=uitextarea(g,'Editable','off','Value',{'計算後に、グラフの点や評価表の行を選ぶと、その位置と時刻の数値を確認できます。'});

g=uigridlayout(compare,[5,1]); g.RowHeight={44,44,100,44,'1x'};
ui.Export=uibutton(g,'Text','解析レポートを保存する','ButtonPushedFcn',@report,'Enable','off');
ui.OpenReport=uibutton(g,'Text','保存先のフォルダを開く','ButtonPushedFcn',@openReport,'Enable','off');
ui.ReportNote=uitextarea(g,'Editable','off','Value',{'構造を計算してから、レポートを保存できます。';'HTML、表、グラフ、入力を同じフォルダへ保存します。HTMLはブラウザで読めます。'});
ui.Compare=uibutton(g,'Text','同じ荷重で板厚を 0.8 / 1.0 / 1.2 倍にして比較する','ButtonPushedFcn',@sweep,'Enable','off');
ui.CompareTable=uitable(g);
g=uigridlayout(details,[3,1]); g.RowHeight={150,'1x',180};
ui.Scope=uitextarea(g,'Editable','off','Value',{'円形の等方性断面を持つ線形Euler–Bernoulli梁を評価します。'; ...
 '区分梁、集中荷重、偶力、等分布荷重、接合回転ばね、応力と相対変形に対応します。'; ...
 '局部座屈、詳細FEM、空力弾性などは別のモデルとデータが必要です。'; ...
 '計算の完了、選択した要求の充足、全機の安全性は別々に扱います。全機判定は未評価です。'});
ui.SourceTable=uitable(g); ui.RawDetail=uitextarea(g,'Editable','off','Value',{'選択した結果の詳細データを表示します。'});

ui.Figure=fig;
if ~isempty(which('rocketlab.local_source_panel'))
 local=rocketlab.local_source_panel(tabs,@acceptImport,@showError); names=fieldnames(local);
 for k=1:numel(names), ui.(names{k})=local.(names{k}); end
end
statusBar=uigridlayout(main,[1,2]); statusBar.ColumnWidth={'1x',110}; statusBar.Padding=[0,0,0,0];
ui.Status=uilabel(statusBar,'Text','準備ができました。デモまたは入力を選んでください。','WordWrap','on');
ui.Cancel=uibutton(statusBar,'Text','計算を取り消す','ButtonPushedFcn',@cancel,'Enable','off');
uilabel(main,'Text','表示は選択したモデルと入力の範囲です。全機の安全性と打上げ可否は未評価です。','FontSize',11,'FontColor',muted);
style(); fig.UserData=state; refreshWorkflow();
 function invalidate()
  state.result=[]; state.reportFolder=""; ui.OpenReport.Enable='off'; state.revision=state.revision+1; ui.Export.Enable='off';
  ui.CheckTable.Data=table(); cla(ui.LoadAxes); cla(ui.BendAxes); cla(ui.ShapeAxes); cla(ui.EquivalentAxes); cla(ui.TorqueAxes);
  ui.CompareTable.Data=table(); ui.BendingValue.Text='計算待ち'; ui.DisplacementValue.Text='計算待ち'; ui.EvaluationValue.Text='未評価'; refreshWorkflow(); fig.UserData=state;
 end
 function loadDemo(~,~)
  if state.running, return; end
  invalidate(); resetSource(); [state.vehicle,state.loadCase]=rocketlab.demo_config;
  ui.InputTable.Data=state.vehicle.members; ui.InputTable.ColumnEditable=[false,false,false,false,true,true,false,false,true,true,true,true,true,false];
  ui.InputTable.ColumnName={'部材','開始[m]','終了[m]','外径[m]','板厚[m]','E[Pa]','ポアソン比','密度[kg/m3]','引張許容[Pa]','圧縮許容[Pa]','せん断許容[Pa]','変位制限[m]','要求安全率','出典'};
  ui.Issues.Value={'検証用の架空入力です。実機値ではありません。';'機体構成: DEMO-two-segment / 荷重: snapshot'};
  ui.Run.Enable='on'; ui.Compare.Enable='on'; ui.Status.Text='デモ入力を読込済み。計算を実行できます。'; syncInputs(); refreshWorkflow(); tabs.SelectedTab=input; fig.UserData=state;
 end
 function openConfig(~,~)
  if state.running, return; end
  [file,path]=dialogs.openFile('*.json','vehicle.jsonを選択'); if isequal(file,0), return; end
  [loadFile,loadPath]=dialogs.openFile('*.json','load_case.jsonを選択'); if isequal(loadFile,0), return; end
  try
   v=rocketlab.validate_vehicle(jsondecode(fileread(fullfile(path,file))));
   c=readLoad(fullfile(loadPath,loadFile),v);
   invalidate(); resetSource();
   state.vehicle=v; state.loadCase=c; ui.InputTable.Data=v.members; ui.InputTable.ColumnName=v.members.Properties.VariableNames; ui.InputTable.ColumnEditable=ismember(v.members.Properties.VariableNames,{'diameter','thickness','E','nu','density','tension','compression','shear','deflection','strengthFactor','source'});
   if ismember(string(c.mode),["replay","predict"]), ui.InputTable.ColumnEditable=false; end
   ui.Run.Enable='on'; ui.Compare.Enable='on'; ui.Status.Text='構成と荷重を読込済み。';
  catch e, showError(e); end
  syncInputs(); refreshWorkflow(); tabs.SelectedTab=input; fig.UserData=state;
 end
 function chooseCsv(kind)
  if state.running, return; end
  [file,path]=dialogs.openFile('*.csv','固定様式のCSVを選択'); if isequal(file,0), return; end
  if strcmp(kind,'members'), ui.CsvMembers.Value=fullfile(path,file); else, ui.CsvParts.Value=fullfile(path,file); end
  ui.Status.Text='CSVを選択しました。機体情報を入力し「CSVを読込・照合」を押してください。';
 end
 function importCsv(~,~)
  if state.running, return; end
  try
   options=struct('id',ui.CsvId.Value,'revision',ui.CsvRevision.Value,'length_mm',ui.CsvLength.Value, ...
    'origin',ui.CsvOrigin.Value,'referenceMass_kg',optionalNumber(ui.CsvReferenceMass.Value), ...
    'referenceCG_mm',optionalNumber(ui.CsvReferenceCG.Value));
   v=rocketlab.import_vehicle_csv(ui.CsvMembers.Value,ui.CsvParts.Value,options);
   invalidate(); resetSource(); state.vehicle=v; state.loadCase=[];
   syncInputs(); refreshWorkflow(); fig.UserData=state;
   ui.Issues.Value={'CSV入力を採用しました。構造計算には、この機体に対応する荷重JSONを別途選択してください。'; ...
    '連続円管梁 / 仮定付き。部品質量から飛行荷重や慣性テンソルは生成しません。'};
   ui.Status.Text='取込完了。「機体JSONと照合を保存」、または「荷重JSONを選ぶ」へ進めます。';
  catch e, showError(e); end
 end
 function value=optionalNumber(text)
  if strlength(strtrim(string(text)))==0, value=NaN; return; end
  value=str2double(text);
  assert(isfinite(value),'rocketlab:CSVOptions','基準値は有限の数値、または空欄にしてください。');
 end
 function saveInput(~,~)
  if state.running||isempty(state.vehicle), return; end
  destination=fullfile(root,'outputs'); if ~isfolder(destination), mkdir(destination); end
  folder=dialogs.chooseFolder(destination,'保存先を選択（新しい入力フォルダを作成します）'); if isequal(folder,0), return; end
  try
   saved=rocketlab.save_vehicle_input(state.vehicle,folder);
   ui.Status.Text='入力を保存しました: '+string(displayPath(saved));
  catch e, showError(e); end
 end
 function openLoad(~,~)
  if state.running||isempty(state.vehicle), return; end
  [file,path]=dialogs.openFile('*.json','この機体に対応する荷重JSONを選択'); if isequal(file,0), return; end
  try
   c=readLoad(fullfile(path,file),state.vehicle);
   invalidate(); state.loadCase=c; syncInputs(); refreshWorkflow(); fig.UserData=state;
   ui.Issues.Value={'機体と荷重を選択しました。「2 構造を計算」から計算できます。'; ...
    '選択した荷重と実機構成の対応・出典は利用者が確認してください。'};
   ui.Status.Text='荷重JSONを読み込みました。構造を計算できます。';
  catch e, showError(e); end
 end
 function c=readLoad(file,v)
  c=jsondecode(fileread(file));
  % Reuse the solver's validation instead of duplicating its load rules.
  rocketlab.analyze_case(v,c);
 end
 function calculate(~,~)
  if state.running || isempty(state.vehicle)||isempty(state.loadCase), return; end
  invalidate(); state.cancelled=false; state.running=true; rev=state.revision;
  ui.Run.Enable='off'; ui.Cancel.Enable='on'; refreshWorkflow(); ui.Status.Text='構造計算中'; drawnow;
  try
   result=rocketlab.analyze_case(state.vehicle,state.loadCase); drawnow;
   if state.cancelled || state.revision~=rev
    ui.Status.Text='取消済み。今回の完了結果はありません。';
   else
    state.result=result; showResult(); ui.Status.Text='計算完了 / 選択評価: '+rocketlab.status_label(result.selectedEvaluationStatus)+' / 全機: 未評価'; ui.Export.Enable='on';
   end
  catch e, state.result=[]; showError(e); end
  state.running=false; ui.Run.Enable='on'; ui.Cancel.Enable='off'; refreshWorkflow(); if ~isempty(state.result), tabs.SelectedTab=structure; end; fig.UserData=state;
 end
 function cancel(~,~)
  state.cancelled=true; state.result=[]; ui.Export.Enable='off'; fig.UserData=state;
 end
 function showResult()
  r=state.result; s=r.sections;
  ui.BendingValue.Text=sprintf('%.4g N m',max(hypot(s.My,s.Mz)));
  ui.DisplacementValue.Text=sprintf('%.4g mm',1e3*max(hypot(s.wy,s.wz)));
  ui.EvaluationValue.Text=char(rocketlab.status_label(r.selectedEvaluationStatus));
  ui.Detail.Value={sprintf('ケース %s / 時刻 %.6g s',r.caseId,r.loadCase.time_s);'グラフの点、または「部材ごとの評価」の行を選んで数値を確認できます。'};
  ui.StructureViews.SelectedTab=ui.LoadTab;
  a=plot(ui.LoadAxes,s.s,[s.N,s.Vy,s.Vz]); legend(ui.LoadAxes,'N 引張+','Vy','Vz'); ylabel(ui.LoadAxes,'断面力 [N]');
  b=plot(ui.BendAxes,s.s,[s.My,s.Mz]); legend(ui.BendAxes,'My','Mz'); ylabel(ui.BendAxes,'曲げ [N m]');
  d=plot(ui.ShapeAxes,s.s,1e3*[s.wy,s.wz]); legend(ui.ShapeAxes,'wy','wz'); ylabel(ui.ShapeAxes,'相対変位 [mm]');
  eq=plot(ui.EquivalentAxes,s.s,s.Nbend); ylabel(ui.EquivalentAxes,'曲げ等価軸力 [N]');
  tq=plot(ui.TorqueAxes,s.s,s.T); ylabel(ui.TorqueAxes,'ねじり [N m]');
  for ax=[ui.EquivalentAxes,ui.TorqueAxes,ui.LoadAxes,ui.BendAxes,ui.ShapeAxes], xlabel(ax,'ノーズからの距離 [m]'); grid(ax,'on'); end
  for line=[a(:);b(:);d(:);eq(:);tq(:)]', line.ButtonDownFcn=@selectSection; end
  checks=struct2table(r.checks); mode=string(checks.mode); unit=repmat("MPa",height(checks),1); scale=ones(height(checks),1)*1e-6;
  unit(mode=="deflection")="mm"; scale(mode=="deflection")=1e3;
  label=mode; label(mode=="tension")="引張"; label(mode=="compression")="圧縮"; label(mode=="shear")="せん断上限"; label(mode=="deflection")="相対変位";
  ui.CheckTable.Data=table(string(checks.memberId),label,checks.demand.*scale,checks.allowable.*scale,unit,checks.requiredFactor,checks.MS,rocketlab.status_label(checks.status), ...
   'VariableNames',{'member','evaluation','demand','allowable','unit','factor','margin','status'});
  ui.CheckTable.ColumnName={'部材','評価','需要','許容値','単位','係数','余裕MS','判定'};
  ui.CheckTable.ColumnWidth={100,120,135,135,80,100,130,'auto'}; ui.CheckTable.RowName={};
  ui.SourceTable.Data=r.vehicle.members(:,{'id','source','tension','compression','shear','deflection'});
 end
 function report(~,~)
  if isempty(state.result), return; end
  try
   folder=export_report(state.result); state.reportFolder=string(folder); ui.OpenReport.Enable='on'; ui.ReportNote.Value={['保存先: ' displayPath(folder)];'report.htmlを開くと、部材別の支配条件・許容値・出典を確認できます。'};
   ui.Status.Text='レポートを保存しました。「保存先のフォルダを開く」からHTMLを確認できます。'; refreshWorkflow(); fig.UserData=state;
  catch e, showError(e); end
 end
 function sweep(~,~)
  if isempty(state.vehicle), return; end
  try, ui.CompareTable.Data=rocketlab.sweep_thickness(state.vehicle,state.loadCase,[.8,1,1.2]);
  catch e, ui.CompareTable.Data=table(); showError(e); end
 end
 function flightDemo(~,~)
  runFlight("MATLAB");
 end
 function flightSim(~,~)
  runFlight("Simulink");
 end
 function runFlight(engine)
  if state.running, return; end
  state.running=true; refreshWorkflow(); revision=state.revision;
  ui.FlightRun.Enable='off'; ui.FlightSim.Enable='off'; ui.FlightTransfer.Enable='off'; ui.FlightModel.Enable='off';
  ui.Status.Text=engine+' の検証用飛行と荷重を計算中'; drawnow;
  try
   a=run_flight_structure_demo(engine);
   if revision~=state.revision, error('rocketlab:StaleResult','入力が変わったため、保存した結果を画面へ採用しません。'); end
   state.flight=a.flight; state.flightVehicle=a.vehicle; state.flightDistribution=a.distribution;
   state.flightSummary=a.summary; state.flightOutputFolder=a.outputFolder; state.flightComparison=a.comparison; state.modelPath=a.modelPath; h=a.flight;
   plot(ui.FlightAxes,h.time_s,h.altitude_m,'LineWidth',1.4); xlabel(ui.FlightAxes,'時刻 [s]'); ylabel(ui.FlightAxes,'高度 [m]'); grid(ui.FlightAxes,'on');
   events=a.summary.events; messages=cellstr(events.event+" : "+string(events.time_s)+" s");
   ui.FlightSummary.Value=[{sprintf('%s / 頂点 %.6f s / 高度 %.6f m',engine,h.apogee_s,h.altitude_m(end)); ...
    '架空デモ / 鉛直1次元・軸荷重。横風・姿勢・曲げ・回収は未評価。'};messages; ...
    {sprintf('自由飛行の全%dサンプルを評価 / 合力残差の最大 %.3g N',a.summary.samplesEvaluated,a.summary.maxForceResidual_N); ...
    ['保存先: ' displayPath(a.outputFolder)]}];
   if engine=="Simulink"
    ui.FlightSummary.Value=[ui.FlightSummary.Value;{sprintf('MATLAB比較成功 / 頂点時刻差 %.3g s',a.comparison.eventTimeDifference_s)}];
    ui.FlightModel.Enable='on';
   end
   ui.FlightTransfer.Enable='on'; ui.Status.Text='飛行・荷重計算が完了。時刻を選んで構造画面へ渡せます。';
  catch e
   state.flight=[]; state.flightComparison=[]; state.flightSummary=[]; state.modelPath=""; cla(ui.FlightAxes); ui.FlightSummary.Value={'計算に失敗しました。入力画面の詳細を確認してください。'}; showError(e);
  end
  state.running=false; ui.FlightRun.Enable='on';
  if environment.simulink, ui.FlightSim.Enable='on'; end
  refreshWorkflow(); fig.UserData=state;
 end
 function transferFlight(~,~)
  if isempty(state.flight), return; end
  try
   events=state.flightSummary.events; index=events.sampleIndex(events.event==string(ui.FlightEvent.Value));
   state.vehicle=state.flightVehicle;
   state.loadCase=rocketlab.vertical_load_case(state.flight,index,state.flightDistribution,state.vehicle.length);
   invalidate();
   ui.InputTable.Data=state.vehicle.members; ui.InputTable.ColumnName=state.vehicle.members.Properties.VariableNames;
   ui.InputTable.ColumnEditable=false;
   ui.InputNote.Value={'飛行から渡した構成・荷重です。構成を変更する場合は飛行と荷重を再計算します。'};
   ui.Run.Enable='on'; ui.Compare.Enable='off';
   ui.Issues.Value={'検証用の架空機体。Simulink/MATLAB飛行の同一時刻から荷重を受け渡しています。'; ...
    '鉛直1次元の軸荷重。横荷重・局部評価・全機の安全性は未評価です。'; ...
    sprintf('ケース時刻: %.9g s / 元エンジン: %s',state.loadCase.time_s,state.flight.engine)};
   syncInputs(); calculate([],[]); tabs.SelectedTab=structure;
  catch e, showError(e); end
  fig.UserData=state;
 end
 function openFlightModel(~,~)
  if strlength(state.modelPath)==0, return; end
  try, open_system(char(state.modelPath)); catch e, showError(e); end
 end
 function runSix(engine)
  if state.running, return; end
  state.running=true; refreshWorkflow(); revision=state.revision;
  ui.SixRun.Enable='off'; ui.SixSim.Enable='off'; ui.SixTransfer.Enable='off'; ui.SixModel.Enable='off';
  ui.Status.Text=engine+' の6自由度と燃焼後荷重を計算中'; drawnow;
  try
   a=run_sixdof_demo(engine);
   if revision~=state.revision, error('rocketlab:StaleResult','入力変更のため今回の結果を画面へ採用しません。'); end
   state.sixdofResult=a; h=a.flight;
   plot(ui.SixHeight,h.time_s,h.altitude_m,'LineWidth',1.4); xlabel(ui.SixHeight,'時刻 [s]'); ylabel(ui.SixHeight,'高度 [m]'); grid(ui.SixHeight,'on');
   plot(ui.SixRates,h.time_s,h.state(:,11:13)*180/pi); xlabel(ui.SixRates,'時刻 [s]'); ylabel(ui.SixRates,'機体角速度 [deg/s]');
   legend(ui.SixRates,'ロール p','ピッチ q','ヨー r'); grid(ui.SixRates,'on');
   ev=a.summary.events;
   labels=["最大動圧";"最大対気速度";"最大推力";"最大迎角の絶対値";"燃焼後の最大曲げ"];
   scope=["計算区間";"計算区間";"計算区間";"計算区間";"燃焼終了後のみ"];
   ui.SixEvents.Data=table(labels,ev.time_s,ev.value,ev.unit,scope);
   ui.SixEvents.ColumnName={'イベント','時刻 [s]','値','単位','探索範囲'}; ui.SixEvents.ColumnWidth={200,100,150,80,'auto'};
   ui.SixNote.Value={sprintf('架空機体 / 固定重心の6自由度 / %.3f〜%.3f s',h.time_s(1),h.time_s(end)); ...
    sprintf('燃焼後 %d 点の構造荷重を評価。燃焼中を含む %d 点は対象外。',a.summary.samplesEvaluated,a.summary.excludedSamples); ...
    sprintf('最大残差: 合力 %.3g N / 合モーメント %.3g N m',a.summary.maxForceResidual_N,a.summary.maxMomentResidual_Nm); ...
    'レール拘束・重心移動・分離・開傘は未実装。全飛行の最大構造荷重ではありません。';displayPath(a.outputFolder)};
   if engine=="Simulink"
    ui.SixModel.Enable='on';
    ui.SixNote.Value=[ui.SixNote.Value;{sprintf('MATLAB比較成功 / 姿勢差 %.3g rad',a.comparison.maximumErrors(3))}];
   end
   ui.SixTransfer.Enable='on'; ui.Status.Text='6自由度の計算完了。燃焼後の最大曲げ時刻を構造画面へ渡せます。';
  catch e
   state.sixdofResult=[]; cla(ui.SixHeight); cla(ui.SixRates); ui.SixEvents.Data=table();
   ui.SixNote.Value={'6自由度計算に失敗しました。入力画面の詳細を確認してください。'}; showError(e);
  end
  state.running=false; ui.SixRun.Enable='on';
  if environment.simulink && ~isempty(which('aerolib6dof2')), ui.SixSim.Enable='on'; end
  refreshWorkflow(); fig.UserData=state;
 end
 function transferSix(~,~)
  if state.running || isempty(state.sixdofResult), return; end
  try
   a=state.sixdofResult; state.vehicle=a.vehicle;
   state.loadCase=rocketlab.sixdof_load_case(a.flight,a.summary.maxBendingSampleIndex); invalidate();
   ui.InputTable.Data=state.vehicle.members; ui.InputTable.ColumnName=state.vehicle.members.Properties.VariableNames;
   ui.InputTable.ColumnEditable=false; ui.Run.Enable='on'; ui.Compare.Enable='off';
   ui.InputNote.Value={'6自由度の同一時刻から渡した構成・荷重です。変更時は飛行と荷重を再計算します。'};
   ui.Issues.Value={'架空機体 / 燃焼終了後の最大曲げ時刻 / 6成分の断面力。'; ...
    '燃焼中の構造荷重、局部座屈、全機の安全性は未評価。';sprintf('ケース時刻 %.9g s / %s',state.loadCase.time_s,a.engine)};
   syncInputs(); calculate([],[]); tabs.SelectedTab=structure;
  catch e, showError(e); end
  fig.UserData=state;
 end
 function openSixModel(~,~)
  if isempty(state.sixdofResult)||strlength(state.sixdofResult.modelPath)==0, return; end
  try, open_system(char(state.sixdofResult.modelPath)); catch e, showError(e); end
 end
 function showError(e)
  ui.RawDetail.Value=cellstr(splitlines(string(e.message)));
  ui.Status.Text='入力または計算条件を確認してください: '+string(e.identifier); ui.Issues.Value=cellstr(splitlines(string(e.message)));
 end
 function quickDemo(~,~)
  if state.running, return; end
  loadDemo([],[]); calculate([],[]);
 end
 function navigate(tab)
  tabs.SelectedTab=tab;
 end
 function goInput(~,~)
  navigate(input);
 end
 function goReport(~,~)
  navigate(compare);
 end
 function text=available(value)
  if value, text='利用できます'; else, text='未導入（MATLABのデモは利用可）'; end
 end
 function button=card(parent,titleText,bodyText,buttonText,callback)
  panel=uipanel(parent,'BorderType','line','BackgroundColor',[1,1,1],'BorderColor',[.84,.88,.92]);
  grid=uigridlayout(panel,[3,1]); grid.RowHeight={40,'1x',44}; grid.Padding=[18,18,18,18];
  uilabel(grid,'Text',titleText,'FontWeight','bold','FontSize',18,'WordWrap','on');
  uilabel(grid,'Text',bodyText,'WordWrap','on','FontSize',13);
  button=uibutton(grid,'Text',buttonText,'ButtonPushedFcn',callback);
 end
 function value=metric(parent,labelText,initial)
  grid=uigridlayout(parent,[2,1]); grid.RowHeight={24,'1x'}; grid.Padding=[12,0,12,0]; grid.RowSpacing=4;
  uilabel(grid,'Text',labelText,'FontSize',12);
  value=uilabel(grid,'Text',initial,'FontSize',23,'FontWeight','bold');
 end
 function syncInputs()
  if isempty(state.vehicle)
   ui.FriendlyTable.Data=table(); showCsvSummary(); return
  end
  ui.FriendlyTable.Data=rocketlab.input_view(state.vehicle);
  ui.InputTable.Data=state.vehicle.members;
  ui.InputTable.ColumnEditable=ismember(state.vehicle.members.Properties.VariableNames,{'thickness','E','nu','density','tension','compression','shear','deflection','strengthFactor','source'});
  ui.FriendlyTable.ColumnEditable=[false,false,false,true,true,true,true];
  if ~isempty(state.loadCase)&&ismember(string(state.loadCase.mode),["replay","predict"]), ui.FriendlyTable.ColumnEditable=false; ui.InputTable.ColumnEditable=false; end
  showCsvSummary();
 end
 function showCsvSummary()
  audit=[]; if ~isempty(state.vehicle), audit=rocketlab.csv_import_record(state.vehicle); end
  if isempty(audit)
   ui.CsvSummary.Value={'現在の構成に対応するCSV照合記録はありません。';'部材を編集した場合は、部品表も確認してCSVを再読込してください。'}; return
  end
  ui.CsvSummary.Value={sprintf('部品表の総質量 %.8g kg / ノーズからの重心 %.8g mm',audit.totalMass_kg,audit.cgFromNose_m*1000); ...
   sprintf('基準との差: 質量 %s / 重心 %s',comparisonText(audit.massDifference_kg,'kg'),comparisonText(audit.cgDifference_m*1000,'mm')); ...
   '差分の表示であり、合否判定ではありません。部材表の質量は加算していません。'; ...
   sprintf('構成 %s / 改訂 %s / 原点 %s / 出典 %s, %s',audit.vehicleId,audit.revision,audit.inputOrigin,audit.membersFile.name,audit.partsFile.name)};
 end
 function text=comparisonText(value,unit)
  if isnan(value), text='比較なし'; else, text=sprintf('%.8g %s',value,unit); end
 end
 function editFriendly(~,~)
  if isempty(state.vehicle)||state.running, syncInputs(); return; end
  try
   candidate=rocketlab.apply_input_view(state.vehicle,ui.FriendlyTable.Data);
   state.vehicle=candidate; ui.InputTable.Data=candidate.members; invalidate(); syncInputs();
   ui.Status.Text='入力を変更しました。2 構造を計算から再計算してください。'; fig.UserData=state;
  catch e, syncInputs(); showError(e); end
 end
 function editInput(~,~)
  if isempty(state.vehicle)||state.running, return; end
  try
   candidate=state.vehicle; candidate.members=ui.InputTable.Data; candidate.assumed=true;
   candidate=rocketlab.validate_vehicle(candidate); state.vehicle=candidate; invalidate(); syncInputs();
   ui.Status.Text='入力を変更しました。2 構造を計算から再計算してください。'; fig.UserData=state;
  catch e, ui.InputTable.Data=state.vehicle.members; showError(e); end
 end
 function refreshWorkflow()
  hasInput=~isempty(state.vehicle); hasLoad=~isempty(state.loadCase); hasResult=~isempty(state.result); idle=~state.running;
  ui.Demo.Enable=onoff(idle); ui.Open.Enable=onoff(idle); ui.QuickDemo.Enable=onoff(idle);
  ui.Run.Enable=onoff(idle&&hasInput&&hasLoad); ui.StepReport.Enable=onoff(idle&&hasResult); ui.Export.Enable=onoff(idle&&hasResult);
  for item=[ui.ChooseMembers,ui.ChooseParts,ui.ImportCSV], item.Enable=onoff(idle); end
  ui.SaveInput.Enable=onoff(idle&&hasInput); ui.OpenLoad.Enable=onoff(idle&&hasInput);
  ui.Compare.Enable=onoff(idle&&hasInput&&hasLoad&&ismemberMode());
  if state.running, ui.NextAction.Text='計算しています。完了すると結果を確認できます。';
  elseif hasResult && strlength(state.reportFolder)>0, ui.NextAction.Text='レポートを保存しました。保存先のHTMLを開いて確認できます。';
  elseif hasResult, ui.NextAction.Text='次は 3 レポートへ。部材ごとの評価も確認できます。';
  elseif hasInput&&~hasLoad, ui.NextAction.Text='CSVを取込済み。CSVタブで保存、または荷重JSONを選択してください。';
  elseif hasInput, ui.NextAction.Text='次は 2 構造を計算。入力を編集したら、もう一度計算します。';
  else, ui.NextAction.Text='最初は「構造デモを試す」から始められます。'; end
 end
 function yes=ismemberMode()
  yes=~isempty(state.loadCase)&&ismember(string(state.loadCase.mode),["snapshot","test"]);
 end
 function value=onoff(condition)
  if condition, value='on'; else, value='off'; end
 end
 function resetSource()
  state.sixdofResult=[]; ui.SixTransfer.Enable='off'; ui.SixModel.Enable='off';
  cla(ui.SixHeight); cla(ui.SixRates); ui.SixEvents.Data=table(); ui.SixNote.Value={'姿勢を含む飛行は、まだ計算していません。'};
  ui.InputNote.Value={'日常単位の表を編集すると、計算用のSI単位へ変換します。飛行から渡した構成は編集できません。'};
  state.import=[]; state.flight=[]; state.flightSummary=[]; state.flightOutputFolder=""; state.flightComparison=[]; state.modelPath="";
  ui.FlightTransfer.Enable='off'; ui.FlightModel.Enable='off'; ui.SourceTable.Data=table(); ui.InputTable.Data=table(); ui.FriendlyTable.Data=table();
  cla(ui.FlightAxes); ui.FlightSummary.Value={'飛行は、まだ計算していません。'};
  if isfield(ui,'ResetLocalSources'), ui.ResetLocalSources(); end
 end
 function acceptImport(p)
  if state.running, return; end
  invalidate(); resetSource(); state.vehicle=[]; state.import=p;
  ui.Issues.Value=cellstr(p.issues);
  if ~isempty(p.cad)
   ui.InputTable.Data=p.cad.candidates; ui.InputTable.ColumnEditable=false;
   ui.InputTable.ColumnName={'項目','シート','セル','保存値','数式','元の単位','SI換算係数','SI値','状態'}; ui.SourceTable.Data=p.cad.candidates;
  end
  if ~isempty(p.flight)
   h=p.flight; plot(ui.FlightAxes,h.normalized.time_s,h.normalized.q_Pa/1000); xlabel(ui.FlightAxes,'時刻 [s]'); ylabel(ui.FlightAxes,'動圧 [kPa]'); grid(ui.FlightAxes,'on');
   ui.FlightSummary.Value={sprintf('%d行 / %.3f〜%.3f s',h.summary.rows,h.summary.start_s,h.summary.end_s);'取込候補です。採用構成と規約を確認してください。'};
  end
  ui.Status.Text='ローカル資料を読み込みました。採用構成は未確定です。'; refreshWorkflow(); fig.UserData=state;
 end
 function selectSection(~,event)
  if isempty(state.result), return; end
  s=state.result.sections; [~,index]=min(abs(s.s-event.IntersectionPoint(1)));
  m=state.result.vehicle.members; member=m(string(m.id)==s.memberId(index),:);
  record=struct('caseId',state.result.caseId,'time_s',state.result.loadCase.time_s,'section',table2struct(s(index,:)), ...
   'member',table2struct(member),'checks',state.result.checks(string({state.result.checks.memberId})==s.memberId(index)));
  ui.Detail.Value={sprintf('部材 %s / 位置 %.4g m / 時刻 %.4g s',s.memberId(index),s.s(index),state.result.loadCase.time_s); ...
   sprintf('軸力 %.4g N / 曲げ My %.4g, Mz %.4g N m / ねじり %.4g N m',s.N(index),s.My(index),s.Mz(index),s.T(index));'全データは「計算の根拠」で確認できます。'};
  ui.RawDetail.Value=cellstr(splitlines(string(jsonencode(record,PrettyPrint=true))));
 end
 function selectCheck(~,event)
  if isempty(event.Indices)||isempty(state.result), return; end
  item=state.result.checks(event.Indices(1,1));
  ui.Detail.Value={sprintf('部材 %s / %s',item.memberId,rocketlab.status_label(item.status));'需要、許容値、安全率、出典は表と「計算の根拠」で確認できます。'};
  ui.RawDetail.Value=cellstr(splitlines(string(jsonencode(item,PrettyPrint=true))));
 end
 function openReport(~,~)
  if strlength(state.reportFolder)==0 || ~isfolder(state.reportFolder), return; end
  if ispc, winopen(char(state.reportFolder)); else, web(fullfile(state.reportFolder,'report.html'),'-browser'); end
 end
 function path=displayPath(path)
  path=strrep(char(path),[root filesep],'');
 end
 function style()
  components=findall(fig);
  for j=1:numel(components)
   item=components(j);
   if isa(item,'matlab.ui.control.Label'), item.FontColor=ink;
   elseif isa(item,'matlab.ui.control.Button'), item.BackgroundColor=[1,1,1]; item.FontColor=ink; item.FontSize=13;
   elseif isa(item,'matlab.ui.control.TextArea'), item.BackgroundColor=[1,1,1]; item.FontColor=ink;
   elseif isa(item,'matlab.ui.control.Table'), item.BackgroundColor=[1,1,1;.97,.98,.99]; item.ForegroundColor=ink;
   elseif isa(item,'matlab.ui.container.Tab'), item.BackgroundColor=paper;
   elseif isa(item,'matlab.ui.container.GridLayout'), item.BackgroundColor=paper;
   end
  end
  for button=[ui.QuickDemo,ui.Run,ui.Export], button.BackgroundColor=accent; button.FontColor=[1,1,1]; button.FontWeight='bold'; end
  axes=[ui.FlightAxes,ui.SixHeight,ui.SixRates,ui.LoadAxes,ui.BendAxes,ui.ShapeAxes,ui.EquivalentAxes,ui.TorqueAxes];
  for ax=axes, ax.Color=[1,1,1]; ax.XColor=ink; ax.YColor=ink; ax.FontSize=12; ax.GridColor=[.78,.82,.87]; end
 end
end
