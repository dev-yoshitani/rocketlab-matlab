function environment = startup_project()
%STARTUP_PROJECT Configure this checkout without changing saved MATLAB paths.
root = fileparts(mfilename('fullpath'));
addpath(root, fullfile(root,'src'));
environment = struct('matlab',version,'release',version('-release'), ...
    'products',ver,'javaAvailable',usejava('jvm'),'simulink',license('test','Simulink') && ~isempty(ver('simulink')));
if nargout == 0
    fprintf('RocketLab 解析システム | MATLAB %s | Simulink: %d\n',environment.release,environment.simulink);
end
end
