file1 = '/home/dan/Documents/dendritic-stam/data/fig4/deadzone/hits/deadzone(0.25,0).txt';
file2 = '/home/dan/Documents/dendritic-stam/data/fig4/deadzone/hits/deadzone(0.25,-10).txt';

data1 = load(file1);
data2 = load(file2);

% check each trial

trial1_hits = zeros(1,20);
trial2_hits = zeros(1,20);

for t = 1:20
    for x = 1:size(data1, 1)
        if data1(x, 1) == t && data1(x, 6) == 1
            trial1_hits(t) = 1;
        elseif data1(x,1) > t
            break
        end
    end
end

for t = 1:20
    for x = 1:size(data2, 1)
        if data2(x, 1) == t && data2(x, 6) == 1
            trial2_hits(t) = 1;
        elseif data2(x,1) > t
            break
        end
    end
end

fprintf("Trial 1, # of hits: %d\n", sum(trial1_hits))
fprintf("Trial 2, # of hits: %d\n", sum(trial2_hits))