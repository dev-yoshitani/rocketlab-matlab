function s = signed_stress(N,Mb,A,Z)
s.tension=max(0,N./A+Mb./Z);
s.compression=max(0,-N./A+Mb./Z);
s.equivalentBendingForce=A.*Mb./Z;
end
