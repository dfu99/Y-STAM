close all

HITS_DIR = '/home/dan/Documents/dendritic-stam/data/fig4/tileconc/tc_hits/';
POPS_DIR = '/home/dan/Documents/dendritic-stam/data/fig4/tileconc/populations/';

concs = [160 140 120 100 80 70 60 50 40 35 30 25];
ls = {"-", "--"};

figure
for c = 1:size(concs,2)
    
    conc = num2str(concs(c));
    HITS_FILE = ['tc',conc,'.txt'];
    POPS_SUBDIR = ['tileconc(',conc,')/'];
    hits_data = load([HITS_DIR, HITS_FILE]);
    
    for t = 1:50
        POPS_FILE = ['populations_trial', num2str(t), '.txt'];
        pops_data = load([POPS_DIR, POPS_SUBDIR, POPS_FILE]);

        for x = 1:size(hits_data, 1)
            if hits_data(x, 1) == t && hits_data(x, 6) == 1
                subplot(4,3,c)
                hold on
                plot(pops_data,'k')
                title(['Conc=',conc])
                ylim([0 400])
                break
            elseif hits_data(x, 1) > t
                subplot(4,3,c)
                hold on
                plot(pops_data, "r--")
                title(['Conc=',conc])
                ylim([0 400])
                break
            end
        end
    end


end