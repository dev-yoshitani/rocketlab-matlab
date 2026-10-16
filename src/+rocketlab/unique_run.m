function folder = unique_run(root, prefix)
if nargin<2, prefix='run'; end
if ~isfolder(root), mkdir(root); end
[~,token] = fileparts(tempname(root));
folder = fullfile(root,[char(prefix) '_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')) '_' token]);
assert(~isfolder(folder),'rocketlab:OutputExists','Output already exists.');
mkdir(folder);
end
