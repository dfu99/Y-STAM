%% EG_TRAIL
% Define a chemoattractive trail for the path to follow
% SetTrack
% Low GSE and high Branching

s = 20;
n = 40;
ystam(n, ...
    'Gse', 0.5, ...
    'BranchingFactor', 0.5, ...
    'ECM', [0 0.5 0.01 0.05 1], ...
    'MaxTrials', 1, ...
    'ShowRun', true, ...
    'ShowECM', true, ...
    'ShowHeatMap', true, ...
    'Feedback', true, ...
    'Continuous', true, ...
    'NumSeeds', [1 1], ...
    'SetGoal', [ceil(n/2), n], ...     
    'SetTrack', [0.55 1/n s; 0.2 0.5 s; 0.55 1 s;])
