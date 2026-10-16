function out=load_envelope(vehicle,times,loadAtTime,outputRoot,cancelRequested)
% Stream every time sample. Keep concurrent six-component states at each peak.
if nargin<5, cancelRequested=@()false; end
v=rocketlab.validate_vehicle(vehicle); times=times(:);
assert(~isempty(times)&&all(isfinite(times))&&all(diff(times)>=0),'rocketlab:TimeOrder','Invalid time samples.');
folder=rocketlab.unique_run(outputRoot,'load-envelope');
x=unique([linspace(0,v.length,401)';v.members.s0;v.members.s1;v.joints.s]);
station=reshape([x,x]',[],1); side=repmat(["left";"right"],numel(x),1); n=numel(station);
maximum=-inf(n,6); minimum=inf(n,6); maxTime=NaN(n,6); minTime=maxTime;
maxConcurrent=NaN(n,6,6); minConcurrent=maxConcurrent;
progress=struct('status',"running",'samplesCompleted',0,'samplesTotal',numel(times));
rocketlab.write_json(fullfile(folder,'manifest.json'),progress);
failure=[];
try
for k=1:numel(times)
 drawnow limitrate
 if cancelRequested(), progress.status="cancelled"; break; end
 c=loadAtTime(k,times(k)); c=rocketlab.support_loads(c,v.length);
 b=rocketlab.balance(c); assert(b.balanced,'rocketlab:Unbalanced','History sample is unbalanced.');
 f=rocketlab.section_forces(c,station,side); a=f{:,{'N','Vy','Vz','T','My','Mz'}};
 for j=1:6
  up=a(:,j)>maximum(:,j); down=a(:,j)<minimum(:,j);
  maximum(up,j)=a(up,j); maxTime(up,j)=times(k);
  minimum(down,j)=a(down,j); minTime(down,j)=times(k);
  maxConcurrent(up,:,j)=a(up,:); minConcurrent(down,:,j)=a(down,:);
 end
 progress.samplesCompleted=k;
 if mod(k,100)==0, rocketlab.write_json(fullfile(folder,'manifest.json'),progress); end
end
catch e
 progress.status="failed"; progress.errorIdentifier=string(e.identifier); failure=e;
end
if progress.status=="running" , progress.status="complete"; end
maximum(isinf(maximum))=NaN; minimum(isinf(minimum))=NaN;
out=struct('station',station,'side',side,'maximum',maximum,'minimum',minimum,'maxTime',maxTime,'minTime',minTime, ...
 'maxConcurrent',maxConcurrent,'minConcurrent',minConcurrent,'progress',progress,'outputFolder',folder, ...
 'scope',"load envelope on fixed stations; moving load peaks must be inspected in their original cases");
save(fullfile(folder,'envelope.mat'),'out');
rocketlab.write_json(fullfile(folder,'manifest.json'),progress);
if ~isempty(failure), rethrow(failure); end
end
