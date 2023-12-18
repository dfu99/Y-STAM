%% EG_DEGRAD
% Checks the effect of degradation vs branching factor

list_n = [10 20 30 40 50];
list_gse = [0.99 0.95 0.9 0.85 0.8];
list_bf = [0 0.01 0.1 0.5];
trials = 1;
for n = list_n
    for gse = list_gse
        for bf = list_bf
            ystam(n, ...
                'ShowRun', true, ...
                'Gse', gse, ...
                'BranchingFactor', bf, ...
                'MaxTrials', trials, ...
                'TimeLimit', 100) % Set higher time limit when collecting data
        end
    end
end
