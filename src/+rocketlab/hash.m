function value = hash(input, isFile)
% SHA-256 of UTF-8 text or file bytes. Windows uses installed .NET, not Java.
if nargin<2, isFile=false; end
if ispc
 md=System.Security.Cryptography.SHA256.Create(); clean=onCleanup(@()md.Dispose());
 if isFile
  assert(isfile(input),'rocketlab:FileRead','Cannot open %s',input);
  % MATLAB file IO supports long Unicode paths; .NET Framework File.OpenRead
  % can still enforce MAX_PATH. Feed native file reads to the crypto stream.
  fid=fopen(input,'rb'); assert(fid>=0,'rocketlab:FileRead','Cannot open %s',input);
  closer=onCleanup(@()fclose(fid));
  while ~feof(fid)
   chunk=fread(fid,1048576,'*uint8'); if isempty(chunk), break; end
   md.TransformBlock(chunk,0,numel(chunk),chunk,0);
  end
  md.TransformFinalBlock(NET.createArray('System.Byte',0),0,0); bytes=uint8(md.Hash);
 else
  bytes=uint8(md.ComputeHash(uint8(unicode2native(char(input),'UTF-8'))));
 end
else
 assert(usejava('jvm'),'rocketlab:HashRuntime','Java is required for hashing on this platform.');
 md=java.security.MessageDigest.getInstance('SHA-256');
 if isFile
  fid=fopen(input,'rb'); assert(fid>=0,'rocketlab:FileRead','Cannot open %s',input); closer=onCleanup(@()fclose(fid));
  while ~feof(fid), md.update(fread(fid,1048576,'*uint8')); end
 else
  md.update(unicode2native(char(input),'UTF-8'));
 end
 bytes=typecast(md.digest(),'uint8');
end
value=lower(reshape(dec2hex(bytes,2).',1,[]));
end
