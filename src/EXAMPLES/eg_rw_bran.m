%% EG_RW_BRAN
% random walk, branching
% The results should should measure a new distribution of hit locations
% across different branching factors

list_bf = [0 0.01 0.05 0.1 0.25 0.5];
for bf = list_bf
    ystam(50, ...
        'BranchingFactor', bf, ...
        'MaxTrials', 1, ...
        'ShowRun', true)
end
