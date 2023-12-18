close all

POPS_DIR = './data/fig6/gompertz/';

bfs = [0.01 0.02 0.05 0.1 0.25 0.5];

figure
hold on
for bf = 1:size(bfs,2)
    
    branching = num2str(bfs(bf));
    POPS_SUBDIR = ['radial_gompertz(',branching,')/'];
    POPS_FILE = 'populations.txt';
    pops_data = load([POPS_DIR, POPS_SUBDIR, POPS_FILE]);
    
    plot(pops_data, 'LineWidth', 3)
    title('Gompertz')
    xlabel("Time steps")
    ylabel("Assembly size (Number of tiles)")

    legend("1%", "2%", "5%", "10%", "25%", "50%", 'Location', 'northwest')
end