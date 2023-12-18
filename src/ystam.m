function ystam(n, varargin)

close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% IMPORT VARARGIN SETTINGS %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Input handler
    p = inputParser;
    validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && x>=0;
    validText = @(x) ischar(x) || isstring(x);

    %% Mandatory inputs
    addRequired(p, 'n')

    %% Output setup
    addParameter(p, 'ExportImages', '', @ischar)
    addParameter(p, 'ExportHits', false, @islogical)
    addParameter(p, "Filename", 'lastrun', validText)
    addParameter(p, 'ShowRun', false, @islogical)
    addParameter(p, 'ShowHeatMap', false, @islogical)
    addParameter(p, 'ShowECM', false, @islogical)
    addParameter(p, 'SaveVideo', '', @ischar)
    addParameter(p, 'FrameSkip', 50, validScalarPosNum)
    addParameter(p, 'ColorCode', [], @isnumeric)
    addParameter(p, 'SavePopulations', false, @islogical)

    %% Intrinsic properties of tiles
    addParameter(p, 'BranchingFactor', 0, validScalarPosNum)
    addParameter(p, 'TurningFactor', 0, validScalarPosNum)
    addParameter(p, 'SourceBranches', 4)
    addParameter(p, 'Gse', 1, validScalarPosNum)
    addParameter(p, 'Feedback', false, @islogical)

    %% Secondary control layer
    % extracellular support matrix
    %   [ECM Strength, radius of effect, decay rate modifier, tile present 
    %   decay rate modifier, deposition rate modifier, placement modifer]
    addParameter(p, 'ECM', [0 1 0 1 1], @isnumeric)
    % Tile Conc sets a nominal concentration and a reference upper bound
    %   [tc_nominal, tc_max]; Any zero sets to default concentration
    addParameter(p, 'TileConc', [0 0], @isnumeric)
    %   Buffering adds tiles back into the solution at every time step
    addParameter(p, "Buffering", 0, @isnumeric)
    % TileDirBias is for changing relative concentrations of tiles based on
    %   their output glue direction
    %   Indices correspond to [NL NR EU ED SR SL WD WU]
    addParameter(p, 'TileDirBias', [1 1 1 1 1 1 1 1])
    % [Source strength,source radius of effect,target strength,target 
    %   radius of effect]
    addParameter(p, 'CMode', [0 0 0 0], @isnumeric)
    % Obstacle initiates tile type '-1' for null tile type
    %   [Left, bottom, width, height]
    addParameter(p, 'DeadZone', [0 0 0 0], @isnumeric)
    % Obstacle
    %   [Strength,
    %   radius]
    addParameter(p, 'DeadZoneECM', [0 0 0], @isnumeric)
    % Pre-set memory strength track
    %   [list of vertices (x, y) in 2 column array]
    addParameter(p, 'SetTrack', [], @isnumeric)

    %% Run options
    addParameter(p, 'CalcFeedbackOnly', false)
    addParameter(p, 'Continuous', false, @islogical)
    addParameter(p, 'TimeLimit', 100, validScalarPosNum)
    addParameter(p, 'MaxTrials', 1, validScalarPosNum)

    %% Source and Goal tile placement options
    addParameter(p, 'GrowthMode', 'linear')
    % [Number of source tiles,
    % Number of goal tiles]
    addParameter(p, 'NumSeeds', [1 0], @isnumeric)
    addParameter(p, 'SetGoal', [], @isnumeric)
    addParameter(p, 'SetRoot', [ceil(n/2), 1], @isnumeric)
    
    %% COPY PARAMETERS INTO THE ENVIRONMENT
    parse(p, n, varargin{:});

    %% File path setup
    folderlabel = p.Results.Filename;
    root_dir = fileparts(mfilename('fullpath'));
    export_dir = fullfile(root_dir, '..', 'export',folderlabel);
    
    %% Save args into runtime
    %% Output setup
    save_lastframe = ~isempty(p.Results.ExportImages);
    write_hits = p.Results.ExportHits;
    showRun = p.Results.ShowRun;
    showheatmap = p.Results.ShowHeatMap;
    showecm = p.Results.ShowECM;
    if contains(p.Results.ExportImages, 'g') 
        exportgrid=true;% showRun=true; 
    else 
        exportgrid=false; 
    end
    if contains(p.Results.ExportImages, 'm') 
        exportmtx=true;% showecm=true; 
    else 
        exportmtx=false; 
    end
    if contains(p.Results.ExportImages, 'h') 
        exporthm=true;% showheatmap=true; 
    else 
        exporthm=false; 
    end
    save_videoframes = ~isempty(p.Results.SaveVideo);
    if contains(p.Results.SaveVideo, 'g') 
        savegridframes=true; 
    else 
        savegridframes=false; 
    end
    if contains(p.Results.SaveVideo, 'm') 
        savemtxframes=true; 
    else 
        savemtxframes=false; 
    end
    if contains(p.Results.SaveVideo, 'h') 
        savehmframes=true; 
    else 
        savehmframes=false; 
    end
    frameskip = p.Results.FrameSkip;
    color_codes = p.Results.ColorCode;
    write_populations = p.Results.SavePopulations;
    
    %% Intrinsic properties of tiles
    n = p.Results.n;
    branching_factor = p.Results.BranchingFactor;
    turning_factor = p.Results.TurningFactor;
    sourcebranches = p.Results.SourceBranches;
    G_se = p.Results.Gse;
    usefeedback = p.Results.Feedback;
    
    %% Secondary control layer
    useecmtx = p.Results.ECM(1) ~= 0;
    useheatmap = showheatmap;
    ecm_strength = p.Results.ECM(1);
    ecm_signal_radius = p.Results.ECM(2);
    ecm_decay_rate = p.Results.ECM(3);
    ecm_decay_rate_on = p.Results.ECM(4);
    ecm_refresh_rate = p.Results.ECM(5);
    usetileconc = any(p.Results.TileConc);
    if ~usetileconc
        Kd = 1;
        TILE_CONC_MAX = 100;
    else
        Kd = p.Results.TileConc(1);
        TILE_CONC_MAX = p.Results.TileConc(2);
    end
    buffering = p.Results.Buffering;
    tc_dir_bias = p.Results.TileDirBias;
    cmode = p.Results.CMode;
    cmode_source = cmode(1) ~= 0;
    cstrength_source = cmode(1);
    cradius_source = cmode(2);
    cmode_target = cmode(3) ~= 0;
    cstrength_target = cmode(3);
    cradius_target = cmode(4);
    deadzone = p.Results.DeadZone;
    dz_ecm_strength = p.Results.DeadZoneECM(1);
    dz_ecm_radius = p.Results.DeadZoneECM(2);
    dz_refresh_rate = p.Results.DeadZoneECM(3);
    track_path = p.Results.SetTrack;
    
    %% Run options
    calcfeedbackonly = p.Results.CalcFeedbackOnly;
    continuous = p.Results.Continuous;
    time_limit = p.Results.TimeLimit;
    maxtrials = p.Results.MaxTrials;

    %% Source and Goal tile placement options
    growthmode = p.Results.GrowthMode;
    numseeds = p.Results.NumSeeds;
    setgoal = p.Results.SetGoal;
    setroot = p.Results.SetRoot;
    
    %% Figure handles
    figs = init_figs(0, 0, 1120, 840, 100);
    
    % Give the imported handles internal names
    % Hide figures if simulation is not to be displayed
    if showRun || exportgrid
        fig_gr = figs{1};
    elseif ishandle(figs{1}) 
        close(figs{1});
    end
    if showheatmap || exporthm
        fig_hm = figs{2};
    elseif ishandle(figs{2})
        close(figs{2});
    end
    if showecm || exportmtx
        fig_ecm = figs{3};
    elseif ishandle(figs{3})
            close(figs{3});
    end

    % Make the export directory and save the settings if any data is to be
    % exported
    if any([save_lastframe, save_videoframes, write_populations, write_hits])
        if ~exist(export_dir,'dir') 
            mkdir(export_dir);
        end
        settings_filename = fullfile(export_dir,'settings.txt');
        fileID = fopen(settings_filename, 'w');
        for i = 1:length(p.Parameters)
            a = p.Parameters{i};
            if ~strcmp(a, 'figs')
                fprintf(fileID, "%s=%s\n", a, mat2str(p.Results.(a)));
            end
        end
        fclose(fileID);
    end


%% Recorded data across the entire test
numhits = 0; % Count number of target tiles hit
trialnum = 0; % Count number of trials attempted
savehits = []; % record hits

%% Repeat every trial {
% Every loop:
%   Runs an assembly until its termination conditions are met
%   Saves metrics like assembly size and hits on this trial
%   Save run-specific images
%   Adds to test-wide metrics

while(1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% INITIALIZATION %%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    trial_dir = fullfile(export_dir,['trial',num2str(trialnum,'%04.f')]);

    %% Initialize TileSet class
    % Create the tile set with max concentration TILE_CONC
    myTileSet = TileSet(growthmode, usetileconc, Kd, TILE_CONC_MAX);
    
    % Change tile type concentrations
    myTileSet.apply_turning_factor(turning_factor)
    myTileSet.apply_branching_factor(branching_factor)
    myTileSet.apply_direction_bias(tc_dir_bias)
    
    % Shows the tile types and their concentrations
    fprintf("Glues:\n")
    disp(cat(2, myTileSet.TileTypes, myTileSet.Concs));
    
    %% Initialize Grid class
    % Initialize the environment with 
    %   size (n), 
    %   mode (growthmode = radial or unidirectional)
    %   reverse rate G_se
    %   number of output glues on the source tile (source branches)
    %   the tile set (myTileSet)
    myGrid = Grid(n, growthmode, sourcebranches, G_se, myTileSet);
    
    % Add the source tiles
    myGrid.init_sources(growthmode, 'num', numseeds(1), 'pos', setroot);
    if ~isempty(color_codes)
        myGrid.colorbyseed(color_codes);
    end
    % Add the goal tiles
    myGrid.init_goals(growthmode, 'num', numseeds(2), 'pos', setgoal);
    
    % Set extra options
    if ~isempty(track_path)
        myGrid.set_track(track_path)
    end
    
    if ~isempty(deadzone) && any(any(deadzone))
        myGrid.set_dead_zone(deadzone)
    end
    
    if ~isempty(cmode) && any(cmode)
        myGrid.set_trunk(cmode)
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%  RUN ONE TRIAL %%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % Defaults if parameters not set
    if ~useecmtx
        ecm_strength = 0;
    end
    
    % Start a run with empty space and no activity
    myGrid.reset();

    populations = zeros(time_limit, numseeds(1));
    
    timesteps = 0; % Count elapsed discrete time
    hit_time = 0; % Count amount of time source is connected to target
    total_assembly_size = 0;
    
    if calcfeedbackonly
        hitflag=false;
    else % hitflag must be initialized
        hitflag=true;
    end
    
    % Show initialized grid
    if showRun
        figure(fig_gr)
    end
    myGrid.update_grid(showRun);
    title("time="+num2str(timesteps))
    if showRun
        shg
    end

    %% Repeat tile attachment {
    % Every loop:
    %   Degrades the assembly
    %   Looks for growth fronts to growth the assembly again
    %   Updates positional data
    %   Check feedback and termination conditions
    while(1) 
        % [debug_lastLUT, debug_loops] = debug(myGrid, myTileSet, debug_lastLUT, debug_loops);

        % Preserve the last LUT instance as some steps depend on step
        % changes in the LUT
        lastLUT = myGrid.LUT;
        
        %% Evaluate disassembly {
        % Completely skip the disassembly step if we want to skip over to 
        % evaluating the feedback mechanism
        % If the branching didn't actually find the target, cancel the trial
        % will get canceled in the termination step
        if calcfeedbackonly && ~hitflag
            % Skip reverse rate before goal tile is found to test
            % post-feedback activity
        else
            % Perform disassociation
            ecm_params = {ecm_strength, ecm_signal_radius, ecm_refresh_rate, 'FirstOrderSum'};
            
            % Stachastically evaluate each left side glue 
            myGrid.LUT = eval_breaks(myGrid.LUT, myGrid.ecmtx);

            % Settle all the glues
            myGrid.LUT = settle_glues(myGrid.LUT);

            % Propagate all forward and backward signals
            [myGrid.LUT, myGrid.ecmtx] = propagate_deletions(myGrid.LUT, myGrid.ecmtx, n, ecm_params);

            % Settle all the colorflags
            % If part of a feedback branch breaks, the remaining tiles should not
            % be reverted from the feedback signaling color
            if usefeedback
                myGrid.LUT = settle_colors(myGrid.LUT);
            end
        end
        % } Evaluate disassembly
    
        % Update grid after disassembly
        if showRun
            figure(fig_gr)
        end
        if (save_videoframes && mod(timesteps, frameskip) == 0) || timesteps == 1
            myGrid.update_grid(showRun);
        elseif ~save_videoframes
            myGrid.update_grid(showRun);
        end
        title("time="+num2str(timesteps))
        if showRun
            shg
        end
    
        %% Grow the path {
        % Get all free edges
        FreeEdges = {}; % Active growth fronts
        FreeEdges = refresh_free_edges(myGrid.LUT, FreeEdges);
    
        % Update both grids with new tiles
        % pBinding is the probability to bind new tiles
        growth_params = [usetileconc, G_se];
        dz_params = [dz_ecm_strength, dz_ecm_radius, dz_refresh_rate];
        [myGrid.LUT, myGrid.ecmtx] = add_tiles_to_free_edges(myGrid.LUT, myGrid.ecmtx, n, FreeEdges, myTileSet, growth_params, dz_params);
    
        % Count the simultaneous growth at all fronts as one time step
        timesteps = timesteps + 1; 
        % } Grow the path
    
        %% Update position data for grid, support matrix, heatmap after disassembly and tile attachment
        % This must happen before grid update as it is detecting only NEW tiles
        if useecmtx
            decay_params = [ecm_decay_rate ecm_decay_rate_on];
            myGrid.ecmtx = refresh_ecmtx(myGrid.LUT, lastLUT, myGrid.ecmtx, ecm_params, decay_params);
        end
        
        % Refresh chemotropic gradient
        % It should not be degrading, but also should not have instantaneous
        % strength
        if cmode_source && numseeds(1)>0
            myGrid.ecmtx = layer_update(myGrid.ecmtx, [cstrength_source, cradius_source, ecm_refresh_rate], myGrid.t0, n, 'FirstOrder');
        end
        if cmode_target && numseeds(2)>0
            myGrid.ecmtx = layer_update(myGrid.ecmtx, [cstrength_target, cradius_target, ecm_refresh_rate], myGrid.tf(1), n, 'FirstOrder');
        end
        
        % Show the support matrix map
        if showecm
            figure(fig_ecm)
            if (save_videoframes && mod(timesteps, frameskip) == 0) || timesteps == 1
                if strcmp(growthmode, 'linear')
                    outecm = flipud(myGrid.ecmtx);
                else
                    outecm = myGrid.ecmtx;
                end
                
                if n<100
                    pcolor(outecm)
                else
                    imagesc(outecm)
                end
                colormap(jet)
                caxis([-5 5])
                colorbar
                title("time="+num2str(timesteps))
            end
        end
        
        % Update the heatmap
        % This can happen after the grid update as it is showing the presence
        % of tiles per tile
        if useheatmap
            myGrid.heatmap = refresh_hm(myGrid.LUT, myGrid.heatmap, n);
        end
        
        % Show the heatmap
        if showheatmap
            figure(fig_hm)
            if (save_videoframes && mod(timesteps, frameskip) == 0) || timesteps == 1
                if strcmp(growthmode, 'linear')
                    outhm = flipud(myGrid.heatmap);
                else
                    outhm = myGrid.heatmap;
                end
                
                if n<100
                    pcolor(outhm)
                else
                    imagesc(outhm)
                end
                colormap(pink)
                caxis([0 timesteps])
                colorbar
                title("time="+num2str(timesteps))
            end
        end
        
        % Update and show the grid after each single iteration of all growth fronts
        if showRun
            figure(fig_gr)
            if (save_videoframes && mod(timesteps, frameskip) == 0) || timesteps == 1
                myGrid.update_grid(showRun);
            elseif ~save_videoframes
                % To do: Consolidate LUT away from grid
                % If video is hidden, grid still needs to update because we
                % need to compare current state to last state
                myGrid.update_grid(showRun);
            end
            title("time="+num2str(timesteps))
            if showRun
                shg
            end
        end

        % Update assembly size counter
        if write_hits
            assembly_size = sum(find(~cellfun(@isempty, myGrid.LUT))~=0);
            total_assembly_size = total_assembly_size + assembly_size;
        end
        
        %% Exports, if activated
        % Snapshots of the simulation
        if (save_videoframes && mod(timesteps, frameskip) == 0) || timesteps == 1
            tile_frames_dir = fullfile(trial_dir,'frames','tiling');
            exL1_frames_dir = fullfile(trial_dir,'frames','exlayer1');
            hm_frames_dir = fullfile(trial_dir,'frames','heatmap');
            if savegridframes
                if ~exist(tile_frames_dir,'dir') 
                    mkdir(tile_frames_dir);
                end
                run_jpeg = fullfile(tile_frames_dir,[num2str(timesteps,'%06.f'),'.jpg']);
                saveas(fig_gr, run_jpeg)
                figure(fig_gr)
                savefig(fullfile(tile_frames_dir,[num2str(timesteps,'%06.f'),'.fig']))
            end
            if savemtxframes
                if ~exist(exL1_frames_dir,'dir') 
                    mkdir(exL1_frames_dir);
                end
                mtx_jpeg = fullfile(exL1_frames_dir,[num2str(timesteps,'%06.f'),'.jpg']);
                saveas(fig_ecm, mtx_jpeg)
                figure(fig_ecm)
                savefig(fullfile(exL1_frames_dir,[num2str(timesteps,'%06.f'),'.fig']))
            end
            if savehmframes
                if ~exist(hm_frames_dir,'dir') 
                    mkdir(hm_frames_dir);
                end
                hm_jpeg = fullfile(hm_frames_dir,[num2str(timesteps,'%06.f'),'.jpg']);
                saveas(fig_hm, hm_jpeg)
                figure(fig_hm)
                savefig(fullfile(hm_frames_dir,[num2str(timesteps,'%06.f'),'.fig']))
            end
        end

        % Snapshot the population
        if write_populations
            idx = find(~cellfun(@isempty, myGrid.LUT));
            for i = idx
                pidx = myGrid.LUT{i}.SeedColoring;
                if pidx == 0
                else
                    populations(timesteps, pidx) = populations(timesteps, pidx) + 1;
                end
            end
        end
    
        %% Termination conditions
        % Breaks here exit the tile addition loop and move onto calculating metrics
        run_params = [hitflag, hit_time, continuous, calcfeedbackonly, time_limit, usefeedback];
        [doBreak, doFeedback, myGrid.tf, hitflag, hit_time] = is_done(myGrid.LUT, myGrid.grid, n, myGrid.tf, timesteps, run_params);
        if doBreak
            break
        elseif doFeedback && usefeedback
            [myGrid.LUT, myGrid.tf] = feedback(myGrid.LUT, n, myGrid.tf);
        end
    
        % Buffer all tile types. Does nothing if buffering=0 (default)
        myTileSet.buffer(buffering)

        % (Optional) If TileConcs is active, refresh the tile concentration
        %   display (This is very slow)
        % if usetileconc
            % Live update of tile type concentrations
            % clc
            % fprintf("Glues:\n")
            % disp(cat(2, myTileSet.TileTypes, myTileSet.Concs));
        % end
    end 
    % } Repeat tile attachment, within single trial.
    
    %% Metrics
    % Post-processing per trial {
    % Increase the counter keeping track of trials completed
    trialnum = trialnum + 1;
    fprintf("Trial: %d Duration: %d\n", trialnum, timesteps)
    disp(datetime)
    
    % Save the number of tiles placed at the end of this trial
    if write_hits
        assembly_size = sum(find(~cellfun(@isempty, myGrid.LUT))~=0);
    
        % Evaluate the position of all the branch endpoints
        % If no branches reached the last column, mark this trial with '-1'
        % meaning 'incomplete'
        if sum(find(~cellfun(@isempty, myGrid.LUT( (n-2)*n+1:(n-1)*n) ))~=0) == 0
            ux = -1; % Did not reach last column
            is_hit = false;
            % Save the metrics
            savehits = [savehits; trialnum timesteps assembly_size total_assembly_size ux is_hit hit_time];
        % Otherwise, if there are completely traversed branches, save the row
        % position of each terminus
        else
            for i = 1:n
                if ~isempty(myGrid.LUT{(n-2)*n+i})
                    % Save row position of the branch terminus
                    ux = i;
                    % Evaluate whether target was hit
                    idx = (n-2)*n+i;
                    [~, posy] = idx2pos(idx, n);
                    gidx1 = pos2idx(posy+1, n, n);
                    gidx2 = pos2idx(posy-1, n, n);
                    try
                        flag1 = myGrid.LUT{gidx1}.ColorFlag == 3;
                    catch
                        flag1 = false;
                    end
                    try
                        flag2 = myGrid.LUT{gidx2}.ColorFlag == 3;
                    catch
                        flag2 = false;
                    end
                    if (posy+1)<=n && (posy-1)>=1 && (flag1 || flag2)
                        numhits = numhits+1;
                        is_hit = true;
                    else
                        is_hit = false;
                    end
                    % Save the metrics
                    savehits = [savehits; trialnum timesteps assembly_size total_assembly_size ux is_hit hit_time];
                end
            end
        end
    end


    % Save the populations
    if write_populations
        population_filename = fullfile(trial_dir,'populations.txt');
        fileID = fopen(population_filename, 'w');
        for line = 1:time_limit
            fprintf(fileID, "%s\n", mat2str(populations(line, :)));
        end
        fclose(fileID);

        % Also save the coloring and location of each seed
        % Otherwise we have too little information to go back and interpret the
        % populations
        seeds_filename = fullfile(trial_dir, 'seeds.txt');
        fileID = fopen(seeds_filename, 'w');
        for i = 1:length(myGrid.t0)
            fprintf(fileID, "%s\n", mat2str(myGrid.t0{i}.Position));
        end
        fclose(fileID);
    
        colors_filename = fullfile(trial_dir, 'colors.txt');
        fileID = fopen(colors_filename, 'w');
        for i = 1:size(color_codes, 1)
            fprintf(fileID, "%s\n", mat2str(color_codes(i, :)));
        end
        fclose(fileID);
    end

    % Save the final diagrams generated in this trial
    if save_lastframe
        images_path = fullfile(trial_dir);
        if exportgrid
            figure(fig_gr)
            myGrid.update_grid(1);
            run_jpeg = fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_tile.jpg']);
            % run_svg = fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_tile.svg']);
            saveas(fig_gr, run_jpeg)
            % saveas(fig_gr, run_svg, 'svg')
            savefig(fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_tile.fig']))
        end
        if exportmtx
            figure(fig_ecm)
            mtx_jpeg = fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_mtx.jpg']);
            % mtx_svg = fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_mtx.svg']);
            saveas(fig_ecm, mtx_jpeg)
            % saveas(fig_ecm, mtx_svg, 'svg')
            savefig(fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_mtx.fig']))
            
        end
        if exporthm
            figure(fig_hm)
            hm_jpeg = fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_hm.jpg']);
            % hm_svg = fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_hm.svg']);
            saveas(fig_hm, hm_jpeg)
            % saveas(fig_hm, hm_svg, 'svg')
            savefig(fullfile(images_path, ['trial',num2str(trialnum,'%04.f'),'_hm.fig']))
        end
    end
    
    % Exit once we have completed all the trials
    % Quick summary relationship between runtime and accuracy
    if trialnum >= maxtrials
        fprintf("Hit: %d\n", numhits)
        fprintf("Trials: %d\n", trialnum)
        break
    end
    % } Post-processing per trial
end 
% } Repeat every trial

%% { Post-processing at end of program
% Save the data
if write_hits
    hits_filename = fullfile(export_dir,'hits.txt');
    fileID = fopen(hits_filename, 'w');
    sz = size(savehits);
        for i = 1:sz(1)
            fprintf(fileID, "%d,%d,%d,%d,%d,%d,%d\n", savehits(i,1), savehits(i,2), savehits(i,3), savehits(i,4), savehits(i,5), savehits(i,6), savehits(i,7));
        end
    fclose(fileID);
end
% } Post-processing at end of program
fclose('all');
end
