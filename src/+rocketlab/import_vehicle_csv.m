function [v,audit] = import_vehicle_csv(membersFile,partsFile,options)
% Fixed CSV templates. Positions are scalar stations, not 3-D CAD axes.
required={'id','revision','length_mm','origin'};
assert(isstruct(options)&&isscalar(options)&&all(isfield(options,required)), ...
 'rocketlab:CSVOptions','機体ID、改訂、全長[mm]、位置基準が必要です。');
for key=["id","revision"]
 value=string(options.(key));
 assert(isscalar(value)&&~ismissing(value)&&strlength(strtrim(value))>0,'rocketlab:CSVOptions','%sを入力してください。',key);
end
L=options.length_mm;
assert(isnumeric(L)&&isreal(L)&&isscalar(L)&&isfinite(L)&&L>0,'rocketlab:CSVOptions','全長は正の数値[mm]で入力してください。');
origin=string(options.origin);
assert(isscalar(origin)&&ismember(origin,["nose","tail"]),'rocketlab:CSVOptions','位置基準をnoseまたはtailで指定してください。');
mc=["id","s0_mm","s1_mm","diameter_mm","thickness_mm","E_GPa","nu","density_kg_m3", ...
 "tension_MPa","compression_MPa","shear_MPa","deflection_mm","strengthFactor","source"];
pc=["id","position_mm","mass_kg","source"];
[m,mRows]=readTemplate(membersFile,mc); [p,pRows]=readTemplate(partsFile,pc);
for k=[1,14], textColumn(m,membersFile,mRows,mc,k); end
for k=[1,4], textColumn(p,partsFile,pRows,pc,k); end
uniqueIds(m(:,1),membersFile,mRows); uniqueIds(p(:,1),partsFile,pRows);
a=NaN(size(m,1),12);
for k=2:13
 optional=ismember(k,8:13);
 a(:,k-1)=numberColumn(m(:,k),optional,membersFile,mRows,mc(k));
end
pos=numberColumn(p(:,2),false,partsFile,pRows,pc(2));
mass=numberColumn(p(:,3),false,partsFile,pRows,pc(3));
require(a(:,1)>=0&a(:,1)<=L,membersFile,mRows,mc(2),'位置は0〜全長の範囲にしてください。');
require(a(:,2)>a(:,1)&a(:,2)<=L,membersFile,mRows,mc(3),'終了位置は開始位置より大きく、全長以下にしてください。');
require(a(:,3)>0,membersFile,mRows,mc(4),'外径は正の値が必要です。');
require(a(:,4)>0&2*a(:,4)<a(:,3),membersFile,mRows,mc(5),'板厚は正で、外径の半分未満にしてください。');
require(a(:,5)>0,membersFile,mRows,mc(6),'ヤング率は正の値が必要です。');
require(a(:,6)>-1&a(:,6)<.5,membersFile,mRows,mc(7),'ポアソン比は-1より大きく0.5未満にしてください。');
for k=7:11
 require(isnan(a(:,k))|a(:,k)>0,membersFile,mRows,mc(k+1),'正の数値、または未入力にしてください。');
end
require(isnan(a(:,12))|a(:,12)>=1,membersFile,mRows,mc(13),'要求安全率は1以上、または未入力にしてください。');
require(pos>=0&pos<=L,partsFile,pRows,pc(2),'部品位置は0〜全長の範囲にしてください。');
require(mass>=0,partsFile,pRows,pc(3),'質量は0以上にしてください。');
if sum(mass)<=0||~isfinite(sum(mass)), problem(partsFile,pRows(1),pc(3),'総質量は有限の正の値が必要です。'); end
startColumn=mc(2); endColumn=mc(3);
if origin=="tail"
 a(:,1:2)=[L-a(:,2),L-a(:,1)]; pos=L-pos;
 startColumn=mc(3); endColumn=mc(2);
end
[a,order]=sortrows(a,1); m=m(order,:); mRows=mRows(order);
tol=1e-7; % mm; matches the existing 1e-10 m geometry tolerance.
if abs(a(1,1))>tol, problem(membersFile,mRows(1),startColumn,'部材はノーズ位置0から始めてください。'); end
for k=2:size(a,1)
 if abs(a(k,1)-a(k-1,2))>tol, problem(membersFile,mRows(k),startColumn,'隣接部材の間に隙間または重複があります。'); end
end
if abs(a(end,2)-L)>tol, problem(membersFile,mRows(end),endColumn,'部材の末端と全長が一致しません。'); end
names={'s0','s1','diameter','thickness','E','nu','density','tension','compression','shear','deflection','strengthFactor'};
a=a.*[.001,.001,.001,.001,1e9,1,1,1e6,1e6,1e6,.001,1];
members=[table(m(:,1),'VariableNames',{'id'}),array2table(a,'VariableNames',names),table(m(:,14),'VariableNames',{'source'})];
v=struct('schemaVersion',1,'id',strtrim(string(options.id)),'revision',strtrim(string(options.revision)), ...
 'units',"SI",'coordinates',"station_RHS",'length',L/1000,'assumed',true, ...
 'members',members,'joints',[],'requiredEvaluations',["tension","compression","shear","deflection"]);
v=rocketlab.validate_vehicle(v);
refMass=reference(options,'referenceMass_kg'); refCG=reference(options,'referenceCG_mm');
assert(isnan(refMass)||refMass>0,'rocketlab:CSVOptions','基準質量は正の値、または未入力にしてください。');
assert(isnan(refCG)||(refCG>=0&&refCG<=L),'rocketlab:CSVOptions','基準重心は選択した原点で0〜全長の値にしてください。');
if origin=="tail", refCG=L-refCG; end
total=sum(mass); cg=sum((mass/total).*(pos/1000));
audit=struct('schemaVersion',1,'vehicleId',v.id,'revision',v.revision, ...
 'membersFile',fileRecord(membersFile),'partsFile',fileRecord(partsFile), ...
 'inputOrigin',origin,'inputUnits',"mm, kg, GPa, MPa; angles not imported", ...
 'parts',table(p(:,1),pos/1000,mass,p(:,4),'VariableNames',{'id','station_m','mass_kg','source'}), ...
 'totalMass_kg',total,'cgFromNose_m',cg,'referenceMass_kg',refMass,'referenceCGFromNose_m',refCG/1000, ...
 'massDifference_kg',total-refMass,'cgDifference_m',cg-refCG/1000, ...
 'note',"部品表だけの総質量・軸方向重心。連続等方円管梁、接合剛性なし。慣性・荷重・材料強度の実証ではありません。", ...
 'vehicleHash',string(rocketlab.hash(jsonencode(v))));
v.csvImport=audit;
end

function [values,rows]=readTemplate(path,columns)
opts=delimitedTextImportOptions('NumVariables',numel(columns),'Delimiter',',', ...
 'DataLines',[1 Inf],'VariableNames',cellstr(columns),'VariableTypes',repmat({'string'},1,numel(columns)), ...
 'Encoding','UTF-8','ExtraColumnsRule','error','EmptyLineRule','read');
opts=setvaropts(opts,cellstr(columns),'WhitespaceRule','preserve');
try, raw=readtable(path,opts); catch e, problem(path,1,"CSV",string(e.message)); end
if height(raw)<2, problem(path,1,"CSV",'ヘッダと1行以上のデータが必要です。'); end
header=strtrim(raw{1,:}); header(1)=erase(header(1),char(65279));
bad=find(ismissing(header)|header~=columns,1);
if ~isempty(bad), problem(path,1,columns(bad),'テンプレートの列名と順序を使用してください。'); end
values=strtrim(raw{2:end,:}); rows=(2:height(raw))';
end
function x=numberColumn(values,optional,file,rows,column)
blank=ismissing(values)|strlength(values)==0; x=str2double(values);
bad=~isfinite(x)|imag(x)~=0; if optional, bad=bad&~blank; end
require(~bad,file,rows,column,'有限の数値を入力してください。欠損を0で補いません。');
end
function textColumn(values,file,rows,columns,k)
require(~ismissing(values(:,k))&strlength(values(:,k))>0,file,rows,columns(k),'IDと出典は未入力にできません。');
end
function uniqueIds(ids,file,rows)
for k=2:numel(ids)
 if any(ids(1:k-1)==ids(k)), problem(file,rows(k),"id",'IDが重複しています。'); end
end
end
function require(valid,file,rows,column,message)
k=find(~valid,1); if ~isempty(k), problem(file,rows(k),column,message); end
end
function problem(file,row,column,message)
[~,name,ext]=fileparts(file);
error('rocketlab:CSVInput','%s%s / 行 %d / 列 %s: %s',name,ext,row,column,message);
end
function value=reference(options,key)
value=NaN;
if isfield(options,key)&&~isempty(options.(key)), value=options.(key); end
assert(isnumeric(value)&&isreal(value)&&isscalar(value)&&(isfinite(value)||isnan(value)),'rocketlab:CSVOptions','%sは数値またはNaNにしてください。',key);
end
function record=fileRecord(path)
[~,name,ext]=fileparts(path);
record=struct('name',string([name ext]),'sha256',string(rocketlab.hash(path,true)));
end
