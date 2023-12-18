%% EG_TRUNK
% Places a pre-set memory strength area around the goal tile
% CMode

n = 50;
ystam(n, ...
    'Gse', 0.2, ...
    'BranchingFactor', 0.5, ...
    'MaxTrials', 1, ...
    'ShowECM', true, ...
    'TimeLimit', 5000, ...
    'CMode', [0 0 5 50], ...
    'NumSeeds', [1 1], ...,
    'SetGoal', [ceil(n/2), n], ...
    'ShowRun', true, ...
    'ShowHeatMap', true, ...
    'Continuous', true)