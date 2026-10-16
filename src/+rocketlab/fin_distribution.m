function result = fin_distribution(total,individual,basis)
if nargin<2 || isempty(individual) || nargin<3 || strlength(string(basis))==0
 result=struct('status',"not_evaluated",'forces',[],'reason',"フィン別荷重と分配根拠が必要"); return
end
assert(all(isfinite(individual),'all') && size(individual,2)==numel(total),'rocketlab:FinShape','Dimensions differ.');
assert(norm(sum(individual,1)-total)<=1e-9*max(1,norm(total)),'rocketlab:FinResultant','Fin loads do not conserve resultant.');
result=struct('status',"specified",'forces',individual,'reason',string(basis));
end
