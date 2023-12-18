function visualize(choice)

switch choice

%% For Test 1
case 1
    plot(x, y, 'LineWidth', 3)
    hold on
    scatter(x, y, 'filled')
    xlabel('n (Size of grid)')
    ylabel('Hits')
    title(['Number of hits, 1000 trials', '1-D, no branching, no dissociation'])

%% For Test 1.1
case 1.1
    % For comparing branching and non-branching target distribution
    list_bf = [0 0.01 0.05 0.1 0.25 0.5];
    for bf = list_bf
        filename = ['export/test1.1_t5000/bf',num2str(bf,'%1.2f'),'.txt'];
        data = load(filename);
        figure
        histogram(data(:, 5), [0:2:51]);
        fprintf("bf: %1.2f\n", bf)
        fprintf("Mean: %f\n", mean(data(:, 5)))
        fprintf("SD: %f\n", std(data(:, 5)))
        fprintf("Var: %f\n", res(data(:, 5)))
        s = std(data(:,5));
        m = mean(data(:,5));
        one_std = data(data(:,5)<=(m+s) & data(:,5)>=(m-s), 5);
        pct_one_std = max(size(one_std))/max(size(data(:, 5)));
        fprintf("Pct: %f\n\n", pct_one_std);
        title({'Hit Locations', ['n=50, ', '\it N','\rm\bf=1000, ', num2str(100*bf), '% branching']})
    end

%% For Test 2
case 2
    list_n = [5 6 7 8 9 10 15 20];
    list_gse = [0.8 0.85 0.9 0.95 0.99];
    list_bf = [0 0.01 0.1 0.5];
    t = 200;
    files = {};
    
    figure
    hold on
    for i = 1:8
        col = {[255 0 0]/255, [255 0 45]/255, [255 0 77]/255, [255 0 110]/255, [240 0 147]/255, [208 0 185]/255, [155 0 222]/255, [0 0 255]/255};
        mrkr = {'o', "square", "diamond", "^"};
        n = list_n(i);
    
        if n == 15 || n == 20
            t = 100;
            ls = '--';
            if n == 15
                lw = 1;
            else
                lw = 1;
            end
        else
            t = 200;
            ls = '--';
            lw = 1;
        end
        for j = 1:4
        bf = list_bf(j);
            time_steps = [];
            for gse = list_gse
                filename = ['export/v0.1/test2/n',num2str(n),',t',num2str(t),',b',num2str(bf),',gse',num2str(gse),',f0,ecm0,ch0,tc0.txt'];
                data = load(filename);
                time_steps = [time_steps mean(data(:,2))];
            end
            plot(list_gse, time_steps, 'Color', col{i}, 'LineWidth', lw, 'LineStyle', ls, "Marker", mrkr{j})
        end
    end
    xticks([0.8, 0.85, 0.9, 0.95, 0.99])
    ylabel("Time to Target")
    xlabel("r_b")
    xlim([0.79 1.01])
    set(gca, "YScale", "log")
    ylim([0 3000])
    
    plot([0.8 0.99], [2000 2000], '--')
    text(0.95, 2500, 'Time out threshold')
    
    title({'Space traversal slowdown vs degradation rate'})
    
    hold off

%% Converting .fig to .jpg or .svg
case 0.1
    directory = ['frames\archive\caseFeedbackDemo'];
        

%% For Test 3
case 3
    figure('Position', [0 0 1120 840])
    file0 = 'export/v0.1/test3/n20,t50,b0.1,gse0.95,f0,ecm0,ch0,tc0.txt';
    file1 = 'export/v0.1/test3/n20,t50,b0.1,gse0.95,f1,ecm0,ch0,tc0.txt';
    
    data0 = load(file0);
    data1 = load(file1);
    
    hits0 = data0(find(data0(:,7)), 7);
    hits1 = data1(find(data1(:,7)), 7);
    
    hits = [hits0; hits1];
    for i = 1:max(size(hits0))
        g(i) = "Without feedback";
    end
    for i = max(size(hits0))+1:max(size(hits0)) + max(size(hits1))
        g(i) = "With feedback";
    end
    
    boxplot(hits, g)
    n=20; bf=0.1; gse=0.95; ecms=0;
    title({'Hit times with and without feedback', ['n=',num2str(n),', \beta=',num2str(bf),' e_s=',num2str(ecms) ,', r_b=',num2str(gse)]})
    ylabel("Time steps")
    set(gca,'FontSize',30)
    xlim([0.5 2.5])

%% For Test 3v2 Boxplot of median duration measuring source-target connection time
% Measurements are made after source-target is connected by default
case 3.2
    figure('Position', [0 0 1120 840])
    
    hittime = [];
    avgs = [];
    for feedback = ["on (2)"]
        for gse = [0.95 0.975 0.985 0.995]
            filename = strcat('export/test3/feedback_',feedback,',gse',num2str(gse),'.txt');
            data = load(filename);
            ndata = [data(:, 1) data(:, 7)];
            ddata = unique(ndata, 'rows');
    %         avgs = [avgs log(median(ddata(:, 2)))];
            avgs = [avgs median(ddata(:, 2))];
            fprintf(strcat("Mean, feedback=", feedback, ", gse=", num2str(gse)))
            fprintf(" = %4.2f\n", median(ddata(:,2)))
            idx1 = max(size(hittime))+1;
    %         hittime = [hittime; log(ddata(:, 2))];
            hittime = [hittime; ddata(:, 2)];
            idx2 = max(size(hittime));
            g(idx1:idx2) = strcat(feedback, ', Gse=',num2str(gse));
        end
    end
    
    boxplot(hittime, g, 'PlotStyle', 'compact', 'Whisker', inf, 'Colors', [0.8500 0.3250 0.0980])
    hold on
    plot(1:4, avgs, 'LineWidth', 3, 'Color', [0.8500 0.3250 0.0980])
    
    hittime = [];
    avgs = [];
    for feedback = ["off"]
        for gse = [0.95 0.975 0.985 0.995]
            filename = strcat('export/test3/feedback_',feedback,',gse',num2str(gse),'.txt');
            data = load(filename);
            ndata = [data(:, 1) data(:, 7)];
            ddata = unique(ndata, 'rows');
    %         avgs = [avgs log(median(ddata(:, 2)))];
            avgs = [avgs median(ddata(:, 2))];
            fprintf(strcat("Mean, feedback=", feedback, ", gse=", num2str(gse)))
            fprintf(" = %4.2f\n", median(ddata(:,2)))
            idx1 = max(size(hittime))+1;
    %         hittime = [hittime; log(ddata(:, 2))];
            hittime = [hittime; ddata(:, 2)];
            idx2 = max(size(hittime));
            g(idx1:idx2) = strcat(feedback, ', Gse=',num2str(gse));
        end
    end
    
    boxplot(hittime, g, 'PlotStyle', 'compact', 'Whisker', inf, 'Colors', [0 0.4470 0.7410])
    hold on
    plot(1:4, avgs, 'LineWidth', 3, 'Color', [0 0.4470 0.7410])
    legend("Feedback: On", "Feedback: Off")
    
    title('Hit times')
    set(gca, "YScale", 'log')
    ylabel("Time steps (Log)")
    set(gca,'FontSize',30)
    xlim([0.5 4.5])
    ylim([-100 5000])


%% For Figure 4 (Test 3/Test 4), showing trend of glue breakage probability
% with respect to ecm strength
case 3.1
    
    close all
    % Breakpage probability
    colors = {[230 159 0]/255, [86 180 233]/255, [0 158 115]/255, [0 114 178]/255, [213 94 0]/255};
    lrb = [0.1 0.3 0.5 0.7 0.9];
    figure
    for i = 1:5
        rb = lrb(i);
        x = linspace(-10, 10, 100);
        y = 1 - (rb + (x>0).*(1-rb).*(2./(1+exp(-x)) - 1) + (x<0).*rb.*(2./(1+exp(-x)) - 1));
        plot(x, y, 'color', colors{i}, 'LineWidth', 3)
        hold on
        plot(x, y.^2, '--', 'color', colors{i}, 'LineWidth', 3)
        legend('s=0.1, w/o feedback', 's=0.1, w/ feedback', ...
            's=0.3, w/o feedback', 's=0.3, w/ feedback', ...
            's=0.5, w/o feedback', 's=0.5, w/ feedback', ...
            's=0.7, w/o feedback', 's=0.7, w/ feedback', ...
            's=0.9, w/o feedback', 's=0.9, w/ feedback')
        title("P(breakage)")
        xlabel("Memory strength")
        ylabel("Pr(unbind)")
    end

    figure
    x = linspace(-10, 10, 100);
    y = 2./(1+exp(-x)) - 1;
    plot(x, y, 'LineWidth', 3)
    
    % The expected duration is all wrong because they are not independent
    % events


%% For Test 4, Expected travel distance when supported by support matrix
case 4
    bf = 0.05;
    mdr = 0.01;
    mdr_on = 0.05;
    t = 20;
    list_ecms = [0 1 5];
    titles = {'Matrix Strength = 0', 'Matrix Strength = 1', 'Matrix Strength = 5'};
    for i = 1:3
    ecms = list_ecms(i);
        figure('Position', [0 0 1120 840])
        hold on
        for n = [20 40 80 100]
            rates = [];
            for gse = [0.2 0.4 0.8 0.95]
                filename = ['export/test4c/n',num2str(n),',t',num2str(t),',b',num2str(bf),',gse',num2str(gse),',f0,ecm',num2str(ecms),',ch0,tc0,mdr',num2str(mdr),',',num2str(mdr_on),'.txt'];
                data = load(filename);
                rates = [rates mean(data(:, 2))];
            end
            plot([0.2 0.4 0.8 0.95], rates, 'LineWidth', 3)
        end
        title(titles{i})
        legend('20', '40', '80', '100')
        xlabel('r_b')
        ylabel('Expected time to travel distance n')
        set(gca,'FontSize',30)
    end

%% For Test 4.1, Hit time with support matrix and feedback on or off
case 4.1
    bf = 0.1;
    mdr = 0.01;
    mdr_on = 0.05;
    t = 20;
    list_ecms = [1 5];
    list_n = [20 40];
    list_gse = [0.8 0.95];
    spcnt = 1;
    figure('Position',[-1080 -850 1080 1920])
    for n = list_n
        for gse = list_gse
            for ecms = list_ecms
                clear hits
                clear g
                t = 100;
                filename = ['export/v0.1/test4.1/n',num2str(n),',t',num2str(t),',b',num2str(bf),',gse',num2str(gse),',f0,ecm',num2str(ecms),',ch0,tc0,mdr',num2str(mdr),',',num2str(mdr_on),'.txt'];
                data = load(filename);
    %             hits1 = data(find(data(:,7)), 7);
                hits1 = data(:, 7);
                t = 20;
                filename = ['export/v0.1/test4.1/n',num2str(n),',t',num2str(t),',b',num2str(bf),',gse',num2str(gse),',f1,ecm',num2str(ecms),',ch0,tc0,mdr',num2str(mdr),',',num2str(mdr_on),'.txt'];
                data = load(filename);
    %             hits2 = data(find(data(:,7)), 7);
                hits2 = data(:, 7);
                hits = [hits1; hits2];
                for i = 1:max(size(hits1))
                    g(i) = "Without feedback";
                end
                for i = max(size(hits1))+1:max(size(hits1)) + max(size(hits2))
                    g(i) = "With feedback";
                end
                subplot(4,2,spcnt)
                spcnt = spcnt+1;
                boxplot(hits, g)
                title({'Hit times with and without feedback', ['n=',num2str(n),', \beta=',num2str(bf),' e_s=',num2str(ecms) ,', r_b=',num2str(gse)]})
                ylim([-50 1200])
            end
        end
    end
    close all
    
    % We're going to pick only n=40, es=5, rb=0.8

    clear hits
    clear g
    n = 40;
    ecms = 5;
    gse = 0.8;
    t = 100;
    filename = ['export/v0.1/test4.1/n',num2str(n),',t',num2str(t),',b',num2str(bf),',gse',num2str(gse),',f0,ecm',num2str(ecms),',ch0,tc0,mdr',num2str(mdr),',',num2str(mdr_on),'.txt'];
    data = load(filename);
    hits1 = data(find(data(:,7)), 7);
%     hits1 = data(:, 7);
    t = 20;
    filename = ['export/v0.1/test4.1/n',num2str(n),',t',num2str(t),',b',num2str(bf),',gse',num2str(gse),',f1,ecm',num2str(ecms),',ch0,tc0,mdr',num2str(mdr),',',num2str(mdr_on),'.txt'];
    data = load(filename);
    hits2 = data(find(data(:,7)), 7);
%     hits2 = data(:, 7);
    hits = [hits1; hits2];
    for i = 1:max(size(hits1))
        g(i) = "Without feedback";
    end
    for i = max(size(hits1))+1:max(size(hits1)) + max(size(hits2))
        g(i) = "With feedback";
    end
    figure('Position', [0 0 1120 840])
    hold on
    boxplot(hits, g)
    title({'Hit times with and without feedback', ['n=',num2str(n),', \beta=',num2str(bf),' e_s=',num2str(ecms) ,', r_b=',num2str(gse)]})
    ylim([-50 1200])
    set(gca,'FontSize',30)
    xlim([0.5 2.5])

%% For Test 5
case 5
    usefeedback = true;
    n = 20;
    t = 50;
    bf = 0.1;
    gse = 0.95;
    list_tc = [n^2 n^2/2 n^2/sqrt(n) 2*n n+1];
    assembly_sizes = [];
    for tc = list_tc
        filename = ['export/test5/n',num2str(n),',t',num2str(t),',b',num2str(bf),',gse',num2str(gse),',f1,ecm0,ch0,tc',num2str(tc),'.txt'];
        data = load(filename);
        assembly_sizes = [assembly_sizes mean(data(:,4))];
    end
    figure
    
    plot(list_tc, assembly_sizes)
    ylabel("Number of Tile Binding Events")
    xlabel("Starting Tile Concentration")

    %% Test 13
    case 13
        cases = [[5 10 15 20] 25.*2.^[0:7]];
        all_sigma = zeros(1, size(cases, 2));
        all_sigma_over_time = zeros(2000, size(cases, 2));
        all_residuals = zeros(1, size(cases, 2));
        all_res_over_time = zeros(2000, size(cases, 2));
        
        for i = 1:size(cases, 2)
            numvars = cases(i);
            populations_filename = strcat("/Users/dfu/Documents/dendritic-stam/frames/radial_disassembly(13)_", num2str(numvars), "(1)/populations.txt");
            colors_filename = strcat("/Users/dfu/Documents/dendritic-stam/frames/radial_disassembly(13)_", num2str(numvars), "(1)/colors.txt");

            [newfig, sigma, sigma_over_time, res, res_over_time, mu] = visualize13(populations_filename, colors_filename, numvars);
            all_sigma(i) = sigma;
            all_sigma_over_time(:, i) = sigma_over_time;
            all_residuals(i) = res;
            all_res_over_time(:, i) = smooth(abs(res_over_time), 200);
        end

        % Residuals over time
        figure
        hold on
        markers = {"-o", "-+", "-*", "-v", "-x", "-square", "-diamond", "-^", "->", "-<", "-pentagram", "-hexagram"};
        for i = 1:size(cases, 2)
            p = plot(all_res_over_time(:, i), markers{i});
            p.MarkerIndices = 1:50:size(all_res_over_time, 1);
        end
        hold off
        legend("5", "10", "15", "20", "25", "50", "100", "200", "400", "800", "1600", "3200")
        title("Variance over Time")

        % Std deviation over time
        figure
        hold on
        markers = {"-o", "-+", "-*", "-v", "-x", "-square", "-diamond", "-^", "->", "-<", "-pentagram", "-hexagram"};
        for i = 1:size(cases, 2)
            p = plot(all_sigma_over_time(:, i), markers{i});
            p.MarkerIndices = 1:50:size(all_sigma_over_time, 1);
        end
        hold off
        legend({"5", "10", "15", "20", "25", "50", "100", "200", "400", "800", "1600", "3200"}, "Location", "northwest")
        title("Std. Dev. over Time")

        % Std deviation at interval time limit populations
        figure
        hold on
        xx = [50 400 800 1200 1600 2000];
        markers = {"-o", "--x", ":square", "-.diamond", "-^", "--*"};
        for i = 1:size(xx, 2)
            x = xx(i);
            plot(log(cases/min(cases))/log(2), all_sigma_over_time(x, :), markers{i})
        end
        legend("50", "400", "800", "1200", "1600", "2000")
        title("Std. Dev. per time interval")
        
        hold off

end

end
