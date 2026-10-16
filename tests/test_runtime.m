function tests=test_runtime
tests=functiontests(localfunctions);
end
function setupOnce(t)
startup_project; root=fileparts(fileparts(mfilename('fullpath')));
t.TestData.scratch=rocketlab.unique_run(fullfile(root,'work'),'runtime-test');
end
function testSHA256KnownAnswers(t)
t.verifyEqual(rocketlab.hash('abc'),'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
t.verifyEqual(rocketlab.hash(''),'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
% UTF-8 expected value is independently generated in Python hashlib.
t.verifyEqual(rocketlab.hash('あ'),'dc5a4d3d82f7e15792959dc661538ae0e541ce66494516f5c9cfd9cd3308494d');
end
function testFileStreamingAndOriginalBytes(t)
p=fullfile(t.TestData.scratch,'million-a.bin'); fid=fopen(p,'wb'); fwrite(fid,repmat(uint8('a'),1,1000000),'uint8'); fclose(fid);
t.verifyEqual(rocketlab.hash(p,true),'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0');
t.verifyEqual(dir(p).bytes,1000000);
end
function testLongPathsAndChunkedRead(t)
folder=fullfile(t.TestData.scratch,repmat('x',1,80),repmat('y',1,80),repmat('z',1,80));
mkdir(folder); p=fullfile(folder,'three-million-a.bin');
t.assertGreaterThan(numel(p),260);
fid=fopen(p,'wb'); t.assertGreaterThanOrEqual(fid,0); closer=onCleanup(@()fclose(fid));
fwrite(fid,repmat(uint8('a'),1,3000000),'uint8'); clear closer;
% Independent Python hashlib digest; crosses two 1 MiB chunk boundaries.
t.verifyEqual(rocketlab.hash(p,true),'2a152c894398719c0570f83fac34ac03a0f6e8e474b995c2403aa5434f7b9dd4');
t.verifyEqual(dir(p).bytes,3000000);
end
