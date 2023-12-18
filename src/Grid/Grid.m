classdef Grid < handle
    properties
        t0 = {};
        tf = {};
        n = 1;
        G_se = 1;
        % Initialize data structures
        grid = zeros(1); % Image output
        ecmtx = zeros(1);
        heatmap = zeros(1);
        LUT = cell(1, 1); % Tiles per grid location
        growthmode = "linear";


        % Deadzone settings
        % [left, bottom, width, height]
        deadzone = [0 0 0 0];

        % Source tile default settings
        source_tiles = [];
        source_colors = [];
        sourcebranches = 4;

        % Goal tile default settings
        goal_tiles = [];

        % Trunk settings
        cstrength_source = 0;
        cradius_source = 0;
        cstrength_goal = 0;
        cradius_goal = 0;

        % Track settings
        
        track = [0 0 0; 0 0 0];

        % Defaults for extra settings
        hasTrack = 0;
        hasDeadZone = 0;
        hasTrunk = 0;

        % TileSet
        TileSet = -1;
    end

    methods
        %% Class constructor
        function obj = Grid(n, growthmode, sourcebranches, G_se, TileSet)
            if nargin == 0
                msg = 'Grid must be initialized with a size n.';
                error(msg)
            end

             % Assign property values if provided
             if nargin > 0 
                obj.grid = zeros(n);
                obj.ecmtx = zeros(n);
                obj.heatmap = zeros(n);
                obj.LUT = cell(1, n*n);
                obj.growthmode = growthmode;
                obj.sourcebranches = sourcebranches;
                obj.n = n;
                obj.G_se = G_se;
                obj.source_tiles = [ceil(obj.n/2) 1];
                obj.init_goals("linear");
                obj.TileSet = TileSet;
             end
        end
        
        %% Clear the grid, re-add the same source and goal tiles
        function reset(obj)
            obj.grid = zeros(obj.n);
            obj.ecmtx = zeros(obj.n);
            obj.heatmap = zeros(obj.n);
            obj.LUT = cell(1, obj.n*obj.n);

            obj.add_source_tiles(obj.G_se)
            obj.add_goal_tiles(obj.G_se)
            if obj.hasTrack
                obj.add_track()
            end
            if obj.hasTrunk
                obj.add_trunk()
            end
            if obj.hasDeadZone
                obj.add_dead_zone()
            end
        end

        %% Update the grid
        function update_grid(obj, showRun)
        % Update the grid
            % Default coloring
            % Set the colors according to the ColorFlag of each tile
                % [ -1: Deadzone (Gray)
                % 0: No Tile (White)
                % 1: Tile (Black)
                % 2: Source
                % 3: Goal
                % 4: Feedback
                map = [0.5 0.5 0.5
                    1 1 1
                    0 0 0
                    1 0 0
                    0 0 1
                    0.63 0.26 0.63];
            % Check if source-based color coding is active
            if ~isempty(obj.source_colors)
                color_limit = 4+size(obj.source_colors, 1);
                map = [map; obj.source_colors];
            else
                color_limit = 4;
            end
        
            obj.grid = LUT2grid(obj.LUT);
            % Pad it into the right dimensions
            bGrid = obj.grid;
            bGrid(:, end+1) = 0;
            bGrid(end+1, :) = 0;
            
            % Show grid
            if showRun
                if obj.n<100
                    pcolor(bGrid)
                else
                    imagesc(bGrid)
                end
            end
        
            caxis([-1 color_limit])
            colormap(map)
        
            axis image % equal scale on both axes
            axis ij % use if you want the origin at the top, like with imagesc
        end
        
        %% Source tile
        function add_source_tiles(obj, G_se)
        % Uses the source tile positions in the class attribute
        % source_tiles to place all the source tiles
            for i = 1:size(obj.source_tiles, 1)
                % This gets overwritten by hardcode definition later but still easiest way to generate an input parameter for making the next tile
                glue_list = obj.TileSet.get_weighted_random(); 
                % Make the tile
                t = Tile(glue_list, G_se);
                % Designate it as a source, which controls which glues are
                % ON or disabled
                % Both of these hardcode glue definitions
                if obj.growthmode == "radial"
                    settype(t, "radial-source", "Num", obj.sourcebranches);
                else
                    settype(t, "linear-source");
                end
                % Set its positions
                t.Position = obj.source_tiles(i, :);
                % ColorFlag attribute will mark this tile with a specific
                % color on the grid
                t.ColorFlag = 2;
                % Calculate its specific index in the lookup table data
                % structure
                idx = pos2idx(t.Position(1), t.Position(2), obj.n);
                % Save it to the lookup table
                obj.LUT{idx} = t;
                % Maintain a cache of all the source tiles
                obj.t0{end+1} = t;
                if ~isempty(obj.source_colors)
                    t.SeedColoring = i;
                end
            end
        end

        function init_sources(obj, mode, varargin)
        % Determines the positions of all source tiles
            p = inputParser;
            addRequired(p, 'mode')
            addParameter(p, 'num', 1)
            addParameter(p, 'pos', [ceil(obj.n/2), 1])
            parse(p, mode, varargin{:});
            mode = p.Results.mode;
            pos = p.Results.pos;
            num = p.Results.num;
            % Single, fixed position in LHS column
            if num == 1 && size(pos, 1) == 1
                obj.source_tiles = pos;
            % Multiple, pre-defined positions
            elseif num > 1 && size(pos, 1) == num
                obj.source_tiles = pos;
            % In Linear mode, tiles are expected to grow left-to-right
            % The source tile should be in the LHS column
            elseif mode == "linear"
            % Multiple, random positions
                mod_pattern = mod(pos(1), 2);
                obj.source_tiles = [zeros(num, 2)];
                randpos = (2-mod_pattern):2:obj.n;
                rpos = randsample(randpos, num);
                for i = 1:num
                    obj.source_tiles(i, :) = [rpos(i) 1];
                end
            % In Radial mode, tiles are expected to grow in 2-D
            % The source tile can be anywhere in the environment
            elseif mode == "radial"
                % Multiple, random positions
                mod_pattern = 1;
                i = 1;
                while(i<=num)
                    randpos = randi(obj.n, 1, 2);
                    mod_check = mod(randpos(1) + randpos(2), 2);
                    if mod_check == mod_pattern
                        obj.source_tiles(i, :) = randpos;
                        i=i+1;
                    else
                        continue;
                    end
                end
            else
                error("Invalid operating mode.")
            end
        end

        function colorbyseed(obj, colorcode)
            % For every entry in obj.source_tiles, add a color code to its
            % tile that will be processed when the grid is displayed in
            % update_grid
            if isempty(colorcode)
                return
            elseif size(colorcode,1)~= size(obj.source_tiles,1)
                error("A color code was provided but it does not match the number of seeds.")
            end
            obj.source_colors = colorcode;
        end

        %% Goal tile
        function add_goal_tiles(obj, G_se)
        % Uses the source tile positions in the class attribute
        % goal_tiles to place all the goal tiles
            for i = 1:size(obj.goal_tiles, 1)
                % This gets overwritten by hardcode definition later but still easiest way to generate an input parameter for making the next tile
                glue_list = obj.TileSet.get_weighted_random(); 
                % Make the tile
                t = Tile(glue_list, G_se);
                % Designate it as a goal, which controls which glues are ON
                % or disabled
                % Both of these hardcode glue definitions
                if obj.growthmode == "radial"
                    settype(t, "radial-goal");
                else
                    settype(t, "linear-goal");
                end
                % The feedback state activates the backward channel signal
                t.FBState = 1;
                % Set its positions
                t.Position = obj.goal_tiles(i, :);
                % ColorFlag attribute will mark this tile with a specific
                % color on the grid
                t.ColorFlag = 3;
                % Calculate its specific index in the lookup table data
                idx = pos2idx(t.Position(1), t.Position(2), obj.n);
                % Save it to the lookup table
                obj.LUT{idx} = t;
                % Maintain a cache of all the source tiles
                obj.tf{end+1} = t;
            end
        end

        function init_goals(obj, mode, varargin)
            % Determines the positions of all goal tiles either by user
            % input or randomly
            p = inputParser;
            addRequired(p, 'mode')
            addParameter(p, 'num', 0)
            addParameter(p, 'pos', [ceil(obj.n/2), obj.n])
            parse(p, mode, varargin{:});
            mode = p.Results.mode;
            pos = p.Results.pos;
            num = p.Results.num;

            % Calculate the mod pattern from the first source tile            
            mod_pattern = mod(obj.source_tiles(1, 1)+obj.source_tiles(1, 2), 2);
            
            if num == 0
                % No goal, just grows spontaneously from a seed
                % Don't have to do anything
            elseif num == 1 && size(pos, 1) == 1
                % Shift into mod pattern if necessary
                if mod(pos(1) + pos(2), 2) ~= mod_pattern
                    pos(1) = pos(1) + 1;
                end
                obj.goal_tiles = pos;
            % Manual inputs
            % It is up to the user to ensure the mods match
            elseif num > 1 && size(pos, 1) == num
                obj.goal_tiles = pos;
            elseif mode == "linear"                
                % Multiple, random positions
                obj.goal_tiles = [zeros(num, 2)];
                randpos = (2-mod_pattern):2:obj.n;
                rpos = randsample(randpos, num);
                for i = 1:num
                    obj.goal_tiles(i, :) = [rpos(i) obj.n];
                end
            elseif mode == "radial"
                % Multiple, random positions
                % Build a matrix that includes the source tiles and a
                % radius of tiles around it
                source_radius = [];
                goal_radius = [];
                rad = [0 0; 1 1; 1 -1; -1 1; 1 1];
                for row = size(obj.source_tiles, 1)
                    for loop = 1:5
                        source_radius = [source_radius; obj.source_tiles(row, :)+rad(loop, :)];
                    end
                end
                % Generate random positions
                i = 1;
                while(i<=num)
                    randpos = randi(obj.n, 1, 2);    
                    % Repeat if there are overlaps
                    while ismember(randpos, [source_radius; goal_radius], 'rows')
                        randpos = randi(obj.n, 1, 2);
                    end
                    mod_check = mod(randpos(1) + randpos(2), 2);
                    % Valid entry
                    if mod_check == mod_pattern
                        obj.goal_tiles(i, :) = randpos;
                        % Also do not allow further goal tiles to spawn
                        % adjacent to this one
                        for loop = 1:5
                            goal_radius = [goal_radius; randpos+rad(loop, :)];
                        end
                        i=i+1;
                    else
                        continue;
                    end
                end
            else
                error("Invalid operating mode.")
            end
        end
        
        %% Dead zone
        function add_dead_zone(obj)
            if ~(sum(obj.deadzone(1, 3:4))>0)
                return;
            end
            dzsz = size(obj.deadzone);
            for i = 1:dzsz(1) % For each deadzone (rows)
                % Get the position (left, bottom) and dimensions (width, height)
                left = ceil(obj.n*obj.deadzone(i, 1));
                bottom = ceil(obj.n*obj.deadzone(i, 2));
                width = floor(obj.n*obj.deadzone(i, 3));
                height = floor(obj.n*obj.deadzone(i, 4));
                % Iterate through each cell
                for w = left:left+width
                    for h = bottom:bottom+height
                        idx = pos2idx(h, w, obj.n);
                        dz_defn = ["NULL" "NULL" "NULL" "NULL" "NULL" "NULL"];
                        t = Tile(dz_defn, 0);
                        settype(t, "dead")
                        t.ColorFlag = -1;
                        t.Position = [h w];
                        obj.LUT{idx} = t;
                    end
                end
            end
        end

        function set_dead_zone(obj, input)
            if sum(input(1, 3:4))>0
                obj.deadzone = input;
                obj.hasDeadZone = 1;
            end
        end
        %% Trunk zone

        function add_trunk(obj)
            % Controller for other trunks
            if obj.hasTrunk
                if ~isempty(obj.t0)
                    obj.add_source_trunks();
                end
                if ~isempty(obj.tf)
                    obj.add_goal_trunks();
                end
            end
        end
        function add_source_trunks(obj)
            % Add a chemoaffinity region around all source tiles
            obj.ecmtx = layer_update(obj.ecmtx, [obj.cstrength_source, obj.cradius_source], obj.t0, obj.n, 'FirstOrder');
        end

        function add_goal_trunks(obj)
            % Add a chemoaffinity region around ONLY the initial target tile
            obj.ecmtx = layer_update(obj.ecmtx, [obj.cstrength_goal, obj.cradius_goal], {obj.tf{1}}, obj.n, 'FirstOrder');
        end

        function set_trunk(obj, cmode)
            obj.hasTrunk = 1;
            obj.set_source_trunks(cmode(1), cmode(2))
            obj.set_goal_trunks(cmode(3), cmode(4))

        end

        function set_source_trunks(obj, strength, radius)
            % Sets the trunk settings for the source tiles
            obj.cstrength_source = strength;
            obj.cradius_source = radius;
        end

        function set_goal_trunks(obj, strength, radius)
            % Sets the trunk settings for the goal tiles
            obj.cstrength_goal = strength;
            obj.cradius_goal = radius;
        end

        %% Tracks
        function add_track(obj)
            % Draws the tracks
            idx = 1;
            sz = size(obj.track);
            while 1
                if idx == sz(1)
                    break
                end
                % Draws a line between points (r0, c0) and (r1, c1) as a y=mx+b line
                r0 = round(obj.track(idx, 1) * obj.n);
                c0 = round(obj.track(idx, 2) * obj.n);
                r1 = round(obj.track(idx+1, 1) * obj.n);
                c1 = round(obj.track(idx+1, 2) * obj.n);
                cc = c0:c1;
                m = (r1 - r0)/(c1 - c0);
                b = r1 - m*c1;
                for c = cc % Iterate across x to calculate y
                    r = round(m * c + b);
                    obj.ecmtx = layer_update(obj.ecmtx, [obj.track(idx, 3) 1.5 1], [r c], obj.n, 'Flat');
                end
                idx = idx+1;
            end
        end
        function set_track(obj, input)
            % Input should be a vector
            % Each row is [row (y) coord, column (x) coord, strength]
            % Needs to be of size m x 3
            obj.track = input;
            obj.hasTrack = 1;
        end
    end
end