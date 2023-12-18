%% EG_CHEM_A
% Effect of chemoattractive forces with some radius around each tile
% The goal is to see if it narrows the growth during high disassembly rates

n = 40;
ystam(n, ...
    'Gse', 0.8, ...
    'BranchingFactor', 0.05, ...
    'ECM', [5 1 0.001 0.05 0.1], ...
    'ShowECM', true, ...
    'MaxTrials', 1, ...
    'NumSeeds', [1 1], ...
    'SetGoal', [ceil(n/2), n], ...        
    'ShowRun', true, ...
    'Feedback', true, ...
    'Continuous', true)