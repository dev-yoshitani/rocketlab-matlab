function result=euler_column(EI,length,effectiveLengthFactor,basis)
% Ideal straight uniform isotropic column. No implicit support assumption.
assert(all(isfinite([EI,length,effectiveLengthFactor]))&&EI>0&&length>0&&effectiveLengthFactor>0,'rocketlab:BucklingInput','Positive EI, length and K required.');
assert(strlength(string(basis))>0,'rocketlab:BoundaryBasis','Effective length needs a support-condition basis.');
result=struct('criticalLoad_N',pi^2*EI/(effectiveLengthFactor*length)^2, ...
 'model',"ideal Euler column",'supportBasis',string(basis), ...
 'exclusions',["local shell buckling","Brazier ovalization","imperfections","composite coupling"]);
end
