%% EG_RW_NONB
% Random walk, non-branching
% The results here should measure the hit chance as the space increases

list_n = 10:5:100;
for n = list_n
    ystam(n, ...
        'ShowRun', true, ...
        'MaxTrials', 1)
end
