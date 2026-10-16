function r=joint_test_fit(displacement,force,elasticRows,source)
% The elastic interval must be identified by the user from the test evidence.
x=displacement(elasticRows); y=force(elasticRows);
assert(numel(x)>=3&&all(isfinite(x))&&all(isfinite(y))&&max(x)-min(x)>0,'rocketlab:TestData','Need 3+ finite elastic samples.');
assert(strlength(string(source))>0,'rocketlab:TestSource','Test source and interval basis required.');
p=polyfit(x,y,1); assert(p(1)>0,'rocketlab:Stiffness','Elastic slope must be positive.');
res=y-polyval(p,x);
r=struct('axialStiffness_N_m',p(1),'intercept_N',p(2),'residualRMS_N',sqrt(mean(res.^2)), ...
 'elasticRows',elasticRows,'source',string(source),'damageOnset_N',NaN,'ultimate_N',NaN, ...
 'rotationalStiffness_Nm_rad',NaN,'note',"Rotation needs bolt positions and individual load sharing; no automatic conversion.");
end
