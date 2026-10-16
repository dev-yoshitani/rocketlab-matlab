function c = check(member,mode,demand,allowable,factor,source)
%CHECK Distinguish unavailable, zero load, failure and requirement satisfaction.
c=struct('memberId',string(member),'mode',string(mode),'demand',demand, ...
    'allowable',allowable,'requiredFactor',factor,'SF',NaN,'MS',NaN, ...
    'status',"not_evaluated",'reason',"",'source',string(source));
c.demandUnit="unspecified"; c.demandFormula="provided demand";
c.marginFormula="SF = allowable / demand; MS = SF / requiredFactor - 1";
switch string(mode)
 case "tension", c.demandUnit="Pa"; c.demandFormula="max(0, N/A + hypot(My,Mz)/Z)";
 case "compression", c.demandUnit="Pa"; c.demandFormula="max(0, -N/A + hypot(My,Mz)/Z)";
 case "shear", c.demandUnit="Pa"; c.demandFormula="hypot(Vy,Vz)*shearPerForce + abs(T)*torsionPerMoment (upper bound)";
 case "deflection", c.demandUnit="m"; c.demandFormula="hypot(wy,wz) relative to the stated reference"; c.marginFormula="demand <= allowable / requiredFactor; displacement factor independent of strength";
end
if ~isscalar(demand)||~isfinite(demand)||demand<0
    c.reason="需要が欠損または無効"; return
end
if ~isscalar(allowable)||~isfinite(allowable)||allowable<=0 || ~isfinite(factor)||factor<=0
    c.reason="許容値または要求係数が不足"; return
end
if demand==0
    c.status="no_load"; c.reason="当該ケースではこの評価項目の荷重なし"; return
end
c.SF=allowable/demand; c.MS=c.SF/factor-1;
if c.MS>=0, c.status="pass"; else, c.status="fail"; end
end
