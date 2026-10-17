function folder = export_report(result,folder)
% Export one stored result without recalculating, to a fresh destination.
startup_project();
if nargin<2, folder=rocketlab.unique_run(fullfile(fileparts(mfilename('fullpath')),'outputs'),'report'); end
assert(~isfile(fullfile(folder,'report.html')) && ~isfile(fullfile(folder,'sections.csv')),'rocketlab:OutputExists','Existing reports are never overwritten.');
if ~isfolder(folder), mkdir(folder); end
r=result; s=r.sections; c=r.checks;
standalone=~isfile(fullfile(folder,'manifest.json'));
if standalone
 manifest=struct('status',"running",'kind',"report_export",'matlab',version, ...
 'codeHash',rocketlab.code_hash(fileparts(mfilename('fullpath'))), ...
 'normalizedInputHash',rocketlab.hash(jsonencode(struct('vehicle',r.vehicle,'loadCase',r.loadCase))), ...
 'timeUTC',string(datetime('now','TimeZone','UTC')));
 rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
 manifestCleanup=onCleanup(@()markFailed(folder));
end
writetable(s,fullfile(folder,'sections.csv'));
flat=rmfield(c,'concurrentLoads'); writetable(struct2table(flat),fullfile(folder,'checks.csv'));
rocketlab.write_json(fullfile(folder,'checks.json'),c);
rocketlab.write_json(fullfile(folder,'input.json'),struct('vehicle',r.vehicle,'loadCase',r.loadCase));
rocketlab.write_json(fullfile(folder,'balance.json'),r.balance);
audit=rocketlab.csv_import_record(r.vehicle);
if ~isempty(audit), rocketlab.write_json(fullfile(folder,'input_check.json'),audit); end
f=figure('Visible','off','Position',[50 50 1150 1060],'Color','w');
cl=onCleanup(@()close(f)); t=tiledlayout(f,3,2,'Padding','compact');
nexttile; plot(s.s,s.N,'LineWidth',1.4); ylabel('N (tension +) [N]'); grid on; xlabel('s [m]');
nexttile; plot(s.s,[s.Vy,s.Vz],'LineWidth',1.4); legend('Vy','Vz'); ylabel('Shear [N]'); grid on; xlabel('s [m]');
nexttile; plot(s.s,[s.My,s.Mz],'LineWidth',1.4); legend('My','Mz'); ylabel('Moment [N m]'); grid on; xlabel('s [m]');
nexttile; plot(s.s,s.T,'LineWidth',1.4); ylabel('Torque [N m]'); grid on; xlabel('s [m]');
nexttile; plot(s.s,s.Nbend,'LineWidth',1.4); ylabel('Bending equivalent axial force [N]'); grid on; xlabel('s [m]');
nexttile; plot(s.s,1e3*[s.wy,s.wz],'LineWidth',1.4); legend('wy','wz'); ylabel('Relative displacement [mm]'); grid on; xlabel('s [m]');
title(t,sprintf('%s | t = %.6g s | %s',r.caseId,r.loadCase.time_s,r.loadCase.mode),'Interpreter','none');
% Keep exported figures readable independently of the user's desktop theme.
ink=[.08 .14 .20];
for ax=findall(f,'Type','axes')'
 ax.Color='w'; ax.XColor=ink; ax.YColor=ink; ax.ZColor=ink;
 ax.GridColor=[.45 .5 .55]; ax.GridAlpha=.25; ax.FontSize=11;
 ax.XLabel.Color=ink; ax.YLabel.Color=ink; ax.Title.Color=ink;
end
for lg=findall(f,'Type','legend')'
 lg.Color='w'; lg.TextColor=ink; lg.EdgeColor=[.7 .75 .8];
end
t.Title.Color=ink;
exportgraphics(f,fullfile(folder,'distributions.png'),'Resolution',160,'BackgroundColor','white');
print(f,fullfile(folder,'distributions.svg'),'-dsvg');
md=["# RocketLab 解析報告";"";"## 概要"; ...
 "ケース: "+r.caseId+" / 構成: "+r.vehicle.id; ...
 "選択した評価: "+r.selectedEvaluationStatus+" / 全機判定: "+r.wholeVehicleStatus; ...
 "この結果は指定モデル内の計算であり、打上げ可否・審査承認を示さない。";""; ...
 "## 構成・条件";"解析モード: "+r.loadCase.mode+" / 境界条件: "+r.loadCase.boundary; ...
 "荷重時刻: "+string(r.loadCase.time_s)+" s";"仮定: "+r.loadCase.assumptions;""; ...
 "## モデルと出典";r.model;"内部単位はSI。sはノーズから後端へ増加。Nは引張正。"; ...
 "強度: SF=許容値/需要、MS=SF/要求係数−1。変位: 変位≤許容変位。"; ...
 "横せん断とねじりは、それぞれの最大値の和による上限評価。"; ...
 "入力と出典はinput.json、同時の断面力と支配時刻はchecks.jsonを参照。";""; ...
 "## 結果";"![荷重と変形](distributions.png)";""; ...
 "| 部材 | 評価 | 需要 | 許容値 | 要求係数 | MS | 状態 | s [m] |"; ...
 "|---|---|---:|---:|---:|---:|---|---:|"];
htmlRows=strings(numel(c),1);
for k=1:numel(c)
 ch=c(k);
 md(end+1)=sprintf('| %s | %s | %.6g | %.6g | %.3g | %.6g | %s | %.6g |',ch.memberId,ch.mode,ch.demand,ch.allowable,ch.requiredFactor,ch.MS,ch.status,ch.station);
 htmlRows(k)=sprintf('<tr><td><a href="#check%d">%s</a></td><td>%s</td><td>%.6g</td><td>%.6g</td><td>%.3g</td><td>%.6g</td><td>%s</td></tr>', ...
 k,esc(ch.memberId),esc(ch.mode),ch.demand,ch.allowable,ch.requiredFactor,ch.MS,esc(rocketlab.status_label(ch.status)));
end
md=[md;"";"## 検証";sprintf('合力残差 [N]: [%.6g, %.6g, %.6g]',r.balance.force); ...
 sprintf('合モーメント残差 [N m]: [%.6g, %.6g, %.6g]',r.balance.moment); ...
 "釣合いの一致だけで、採用した荷重分布の妥当性を証明したことにはならない。";""; ...
 "## 未確認事項";r.samplingNote; ...
 "局部シェル座屈、ノーズ保持、詳細FEM、フラッタ、ダイバージェンス、実機試験との一致は別評価。"; ...
 "本報告はこれらの評価結果を代用しない。"];
verificationText=join(md(end-8:end),newline);
if ~isempty(audit)
 md=[md;"";"## CSV入力の照合"; ...
  sprintf('部品表の総質量 %.8g kg、ノーズからの重心 %.8g mm。',audit.totalMass_kg,audit.cgFromNose_m*1000); ...
  sprintf('基準との差: 質量 %s、重心 %s。',comparisonText(audit.massDifference_kg,'kg'),comparisonText(audit.cgDifference_m*1000,'mm')); ...
  "部品表だけの集計であり、合否判定ではない。出典・SHA-256・単位・座標はinput_check.jsonを参照。"];
end
write(fullfile(folder,'report.md'),join(md,newline));
html="<html lang='ja'><meta charset='utf-8'><title>RocketLab 解析報告</title>"+ ...
 "<style>body{font:16px Meiryo,sans-serif;max-width:1100px;margin:32px auto;line-height:1.7;color:#183047}table{border-collapse:collapse;width:100%}td,th{padding:7px;border-bottom:1px solid #cbd5e1;text-align:left}img{width:100%}pre{white-space:pre-wrap;background:#f1f5f9;padding:12px}a{color:#1668a8}</style>"+ ...
 "<h1>RocketLab 解析報告</h1><p>"+esc(r.caseId)+" / "+esc(r.vehicle.id)+"</p>"+ ...
 "<p>選択した評価: "+esc(rocketlab.status_label(r.selectedEvaluationStatus))+" / 全機判定: 未評価</p>"+ ...
 "<p>"+esc(r.loadCase.assumptions)+"</p><h2>モデルと条件</h2><p>"+esc(r.model)+"</p>"+ ...
 "<p>Nは引張正。応力はPa、変位はm。強度SF=許容値/需要、MS=SF/要求係数−1。変位係数は1。</p>"+ ...
 "<img alt='断面力と相対変形の図' src='distributions.svg'><h2>部材別結果</h2>"+ ...
 "<table><tr><th>部材</th><th>評価</th><th>需要</th><th>許容値</th><th>係数</th><th>MS</th><th>状態</th></tr>"+join(htmlRows,"")+"</table><h2>支配条件と根拠</h2>";
for k=1:numel(c)
 html=html+"<h3 id='check"+string(k)+"'>"+esc(c(k).memberId)+" / "+esc(c(k).mode)+"</h3><pre>"+esc(jsonencode(c(k),PrettyPrint=true))+"</pre>";
end
if ~isempty(audit)
 html=html+"<h2>CSV入力の照合</h2><p>"+esc(sprintf('部品表の総質量 %.8g kg / ノーズからの重心 %.8g mm',audit.totalMass_kg,audit.cgFromNose_m*1000))+ ...
  "</p><p>"+esc(sprintf('基準との差: 質量 %s / 重心 %s。',comparisonText(audit.massDifference_kg,'kg'),comparisonText(audit.cgDifference_m*1000,'mm')))+ ...
  " 合否判定ではありません。<a href='input_check.json'>照合・出典・SHA-256</a></p>";
end
html=html+"<h2>検証と未確認事項</h2><pre>"+esc(verificationText)+"</pre>"+ ...
 "<p><a href='input.json'>入力・出典</a> / <a href='sections.csv'>全断面CSV</a> / <a href='checks.json'>判定JSON</a></p></html>";
write(fullfile(folder,'report.html'),html);
result.outputFolder=folder; save(fullfile(folder,'result.mat'),'result');
if standalone
 manifest.status="complete"; rocketlab.write_json(fullfile(folder,'manifest.json'),manifest);
 clear manifestCleanup
end
end
function markFailed(folder)
p=fullfile(folder,'manifest.json'); m=jsondecode(fileread(p));
if strcmp(m.status,'running'), m.status="failed"; rocketlab.write_json(p,m); end
end
function s=esc(s)
s=replace(string(s),["&","<",">",char(34)],["&amp;","&lt;","&gt;","&quot;"]);
end
function text=comparisonText(value,unit)
if isnan(value), text='比較なし'; else, text=sprintf('%.8g %s',value,unit); end
end
function write(path,text)
fid=fopen(path,'w','n','UTF-8'); assert(fid>=0,'rocketlab:FileWrite','Cannot write report.');
c=onCleanup(@()fclose(fid)); fprintf(fid,'%s',text);
end
