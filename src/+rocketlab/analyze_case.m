function r = analyze_case(v,c)
v=rocketlab.validate_vehicle(v);
if isfield(c,'configurationHash')
 assert(string(c.configurationHash)==string(rocketlab.hash(jsonencode(v))),'rocketlab:StaleFlight','Vehicle changed after flight load generation.');
end
if ~isfield(c,'distributed') || isempty(c.distributed), c.distributed=rocketlab.empty_distributed(); end
if isstruct(c.points), c.points=struct2table(c.points); end
if isstruct(c.distributed), c.distributed=struct2table(c.distributed); end
assert(ismember(string(c.mode),["snapshot","replay","predict","test"]),'rocketlab:Mode','Unknown mode.');
assert(strcmp(c.boundary,'free') || strcmp(c.mode,'test'),'rocketlab:BoundaryMode','Supports require mode=test.');
p=c.points; d=c.distributed;
assert(all(isfinite(p{:,{'s','Fx','Fy','Fz','Mx','My','Mz'}}),'all') && all(p.s>=0&p.s<=v.length),'rocketlab:LoadPosition','Invalid load.');
assert(all(isfinite(d{:,:}),'all') && all(d.s0>=0&d.s1<=v.length&d.s1>d.s0),'rocketlab:DistributedLoad','Invalid line load.');
assert(~any(string(p.role)=="internal"),'rocketlab:InternalForce','Internal forces must not enter whole-vehicle FBD.');
assert(numel(unique(string(p.id)))==height(p),'rocketlab:DuplicateLoad','Load IDs must be unique.');
c=rocketlab.support_loads(c,v.length); b=rocketlab.balance(c);
assert(b.balanced,'rocketlab:Unbalanced','Unbalanced load: F=[%g %g %g], M=[%g %g %g].',b.force(1),b.force(2),b.force(3),b.moment(1),b.moment(2),b.moment(3));
if ~isfield(c,'reference'), c.reference=v.length/2; end
critical=rocketlab.critical_stations(v,c);
s=rocketlab.beam_response(v,c,[linspace(0,v.length,101)';critical],c.reference);
s.tension=zeros(height(s),1); s.compression=s.tension; s.shear=s.tension; s.Nbend=s.tension;
checks=struct([]); m=v.members;
for k=1:height(m)
 mask=s.memberId==string(m.id(k));
 stress=rocketlab.signed_stress(s.N(mask),hypot(s.My(mask),s.Mz(mask)),m.A(k),m.Z(k));
 s.tension(mask)=stress.tension; s.compression(mask)=stress.compression; s.Nbend(mask)=stress.equivalentBendingForce;
 s.shear(mask)=hypot(s.Vy(mask),s.Vz(mask))*m.shearPerForce(k)+abs(s.T(mask))*m.torsionPerMoment(k);
 modes=["tension","compression","shear","deflection"];
 values=[s.tension(mask),s.compression(mask),s.shear(mask),hypot(s.wy(mask),s.wz(mask))]; rows=find(mask);
 for q=1:numel(modes)
  [demand,idx]=max(values(:,q)); fact=m.strengthFactor(k); if q==4, fact=1; end
  ch=rocketlab.check(m.id(k),modes(q),demand,m.(modes(q))(k),fact,m.source(k));
  ch.station=s.s(rows(idx)); ch.side=s.side(rows(idx)); ch.caseId=string(c.id); ch.time_s=c.time_s;
  ch.concurrentLoads=table2struct(s(rows(idx),{'N','Vy','Vz','T','My','Mz'}));
  checks=[checks;ch]; %#ok<AGROW>
 end
end
states=string({checks.status});
if any(states=="fail"), status="fail";
elseif any(states=="not_evaluated"), status="incomplete";
elseif v.assumed, status="assumed"; else, status="pass"; end
missing=setdiff(string(v.requiredEvaluations),string({checks.mode}));
if ~isempty(missing), status="incomplete"; end
r=struct('schemaVersion',1,'caseId',string(c.id),'vehicle',v,'loadCase',c,'sections',s, ...
 'checks',checks,'balance',b,'selectedEvaluationStatus',status,'unevaluated',missing, ...
 'wholeVehicleStatus',"not_evaluated",'numericalStatus',"complete", ...
 'model',"piecewise isotropic Euler-Bernoulli; uniform line loads; rotation springs", ...
 'samplingNote',"区分多項式の停留点と不連続点の左右で需要を探索。表示点も併記。");
end
