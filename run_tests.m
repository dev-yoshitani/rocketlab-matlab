function [results,folder] = run_tests()
root=fileparts(mfilename('fullpath')); startup_project();
results=runtests(fullfile(root,'tests'),'IncludeSubfolders',true);
folder=rocketlab.unique_run(fullfile(root,'outputs'),'verification');
summary=table(results); writetable(summary,fullfile(folder,'tests.csv'));
save(fullfile(folder,'tests.mat'),'results');
fprintf('Verification artifacts: %s\n',folder);
assert(~any([results.Failed]),'rocketlab:TestsFailed','Some tests failed.');
end
