function write_json(path, value)
% NaN/Inf are JSON null. Check statuses carry the missing/zero-load reasons.
fid = fopen(path,'w','n','UTF-8');
assert(fid>=0,'rocketlab:FileWrite','Cannot write %s',path);
c = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true,ConvertInfAndNaN=true));
end
