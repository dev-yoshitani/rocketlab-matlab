function p = point_loads(s,F,C)
%POINT_LOADS Station-frame forces [Fx Fy Fz], free couples [Mx My Mz].
s=s(:); n=numel(s);
if nargin<3, C=zeros(n,3); end
assert(isequal(size(F),[n,3]) && isequal(size(C),[n,3]),'rocketlab:LoadShape','Forces and couples must be N-by-3.');
p=table("load"+string((1:n)'),repmat("unspecified",n,1),repmat("external",n,1),s,F(:,1),F(:,2),F(:,3),C(:,1),C(:,2),C(:,3), ...
    'VariableNames',{'id','partId','role','s','Fx','Fy','Fz','Mx','My','Mz'});
end
