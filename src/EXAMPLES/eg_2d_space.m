%% EG_2D_SPACE
% Change number of seeds
% Keep track of saturation of space and populations of each seeded assembly

n = 500;
seed_locations = [ceil(n/2) ceil(n/2)];
timelimit = 2000;
frameskip = 50;

for ns = [2 5 10 15 20 25 50 75 100 125 200 400 800 1600 3200]
    num_sources = ns;
    ystam(n, ...
        'BranchingFactor', 0.25, ...
        'TurningFactor', 0.05, ...
        'Gse', 0.9, ...
        'ECM', [5 2 0.01 -0.25 0.5], ...
        'ShowRun', true, ...
        'ShowECM', false, ...
        'MaxTrials', 1, ...
        'GrowthMode', 'radial', ...
        'NumSeeds', [num_sources 1], ...
        'SetRoot', seed_locations, ...
        'SetGoal', [ceil(n/2) n], ...
        'ColorCode', randi(255, num_sources, 3)/255, ...
        'Continuous', true, ...
        'TimeLimit', timelimit)
end