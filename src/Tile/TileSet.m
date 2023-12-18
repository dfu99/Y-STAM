classdef TileSet < handle

    properties
        TileTypes = [];
        Concs = [];
        Kd = 1;
        concs_max = 0;
        usetileconc = 0;
    end

    methods
        function obj = TileSet(mode, usetileconc, Kd, concs_max)
            if nargin == 0
                msg = "TileSet needs mode and concentrations.";
                error(msg)
            elseif nargin > 0
                % Populate a dictionary of Tile Types and their
                % Concentrations according to conflict rules
                if mode == "linear"
                    [obj.TileTypes, obj.Concs] = obj.init_linear_tile_set(concs_max);
                elseif mode == "radial"
                    [obj.TileTypes, obj.Concs] = obj.init_radial_tile_set(concs_max);
                else
                    error("Invalid growth mode.")
                end
                obj.concs_max = concs_max;
                obj.Kd = Kd;
                obj.usetileconc = usetileconc;
            end 
        end

        %% Tile conc modifiers
        function dec_conc(obj, defn)
            % Decreases the concentration of a tile type by 1 unit
            index = ismember(obj.TileTypes, defn, 'rows');
            idx = find(index);
            if isempty(idx)
                error("Incorrect tile definition.")
            end
            if obj.Concs(idx) > 0
                obj.Concs(idx) = obj.Concs(idx) - 1;
            end
        end

        function inc_conc(obj, defn)
            % Increases the concentration of a tile type by 1 unit
            index = ismember(obj.TileTypes, defn, 'rows');
            idx = find(index);
            if isempty(idx)
                error("Incorrect tile definition.")
            end
            obj.Concs(idx) = obj.Concs(idx) + 1;
        end

        function buffer(obj, num)
            % Increases the concentration of all tile types by 'num' units
            obj.Concs = obj.Concs + num;
        end

        function apply_branching_factor(obj, b)
            % Re-weights branching tile types according to branching factor
            for tt = 1:size(obj.TileTypes, 1)
                % A branching tile has additional output glues defined on its 4 and 6 elements
                if obj.TileTypes(tt, 4) ~= "NULL" && obj.TileTypes(tt, 6) ~= "NULL"
                    obj.Concs(tt) = obj.Concs(tt) * b;
                end
            end
        end

        function apply_turning_factor(obj, t)
            % Re-weights turning tile types according to turning factor
            for tt = 1:size(obj.TileTypes, 1)
                if is_turning(obj.TileTypes(tt, :))
                    obj.Concs(tt) = obj.Concs(tt) * t;
                end
            end
        end

        function apply_direction_bias(obj, d)
            % Re-weights tiles according to their output growth direction
            % d: indices correspond to [NL NR EU ED SR SL WD WU]
            % Does not affect branching tiles
            for tt = 1:size(obj.TileTypes, 1)
                if is_direction(obj.TileTypes(tt, :), 'NL') && ~strcmp(eval_tile_defn(obj.TileTypes(tt, :)), "branching")
                    obj.Concs(tt) = obj.Concs(tt) * d(1);
                elseif is_direction(obj.TileTypes(tt, :), 'NR') && ~strcmp(eval_tile_defn(obj.TileTypes(tt, :)), "branching")
                    obj.Concs(tt) = obj.Concs(tt) * d(2);
                elseif is_direction(obj.TileTypes(tt, :), 'EU') && ~strcmp(eval_tile_defn(obj.TileTypes(tt, :)), "branching")
                    obj.Concs(tt) = obj.Concs(tt) * d(3);
                elseif is_direction(obj.TileTypes(tt, :), 'ED') && ~strcmp(eval_tile_defn(obj.TileTypes(tt, :)), "branching")
                    obj.Concs(tt) = obj.Concs(tt) * d(4);
                elseif is_direction(obj.TileTypes(tt, :), 'SR') && ~strcmp(eval_tile_defn(obj.TileTypes(tt, :)), "branching")
                    obj.Concs(tt) = obj.Concs(tt) * d(5);
                elseif is_direction(obj.TileTypes(tt, :), 'SL') && ~strcmp(eval_tile_defn(obj.TileTypes(tt, :)), "branching")
                    obj.Concs(tt) = obj.Concs(tt) * d(6);
                elseif is_direction(obj.TileTypes(tt, :), 'WD') && ~strcmp(eval_tile_defn(obj.TileTypes(tt, :)), "branching")
                    obj.Concs(tt) = obj.Concs(tt) * d(7);
                elseif is_direction(obj.TileTypes(tt, :), 'WU') && ~strcmp(eval_tile_defn(obj.TileTypes(tt, :)), "branching")
                    obj.Concs(tt) = obj.Concs(tt) * d(8);
                end
            end
        end

        function apply_turning_angle(obj, angle)
            % Warning: this implementation is deprecated but remains as a
            % placeholder
            % Re-weights tile types according to their turn angle
            % Only selects for tiles with the input angle
            for tt = 1:size(obj.TileTypes, 1)
                if has_turn_angle(obj.TileTypes(tt, :), angle)
                else
                    obj.Concs(tt) = 0;
                end
            end
        end
        
        %% Tile getters
        function defn = get_weighted_random(obj)
            cdf = [0 zeros(1, size(obj.Concs, 1))];
            for i = 1:size(obj.Concs, 1)
                cdf(i+1) = sum(obj.Concs(1:i));
            end

            % Make a random selection using cmumlative distribution
            % function and RV X
            X = rand;
            for i = 2:size(cdf, 2)
                if X < cdf(i) && X > cdf(i-1)
                    defn = obj.TileTypes(i-1, :);
                    return;
                end
            end
        end

        function defn = get_weighted_filtered_random(obj, gluename)
            % Get a valid tile type complement of parameter glue name from
            % a weighted random selection of all tile types in the tile set
            [filtered_list, filtered_concs] = obj.filter_by_input(gluename);
            % If using tile concentration kinetics, re-weight using Hill,
            % n=1
            if obj.usetileconc
                weights = filtered_concs./ (obj.Kd + filtered_concs);
            % Otherwise just re-weight linearly
            else
                weights = filtered_concs/sum(filtered_concs);
            end
            cdf = [0 zeros(1, size(weights, 1))];
            for i = 1:size(weights, 1)
                cdf(i+1) = sum(weights(1:i));
            end

            % Make a random selection using cmumlative distribution
            % function and RV X
            % Scale RV X to range of cdf
            X = min(cdf) + rand * ( max(cdf)-min(cdf) );
            for i = 2:size(cdf, 2)
                if X < cdf(i) && X > cdf(i-1)
                    defn = filtered_list(i-1, :);
                    % If Tile Concentration is enabled, re-weight for 
                    % binding probability assuming
                    % Michaelis-Menten kinetics
                    if obj.usetileconc
                        tile_conc = filtered_concs(i-1);
                        pBinding = tile_conc/(obj.Kd + tile_conc);
                        Y = rand;
                        if Y<pBinding
                            % Returns the selected tile definition that is
                            % within the range of receptor-ligand binding
                            % as defined by Michaelis-Menten kinetics
                            return;
                        else
                            % No tile should be grown
                            defn = "NULL";
                            return;
                        end
                    else
                        % Return a linearly weighted random tile
                        return;
                    end
                end
            end
            % No valid tiles exist, return NULL
            defn = "NULL";            
        end

        function [new_list, new_concs] = filter_by_input(obj, gluename)
            % Return only tile types that have the corresponding input glue
            % to the output glue parameter (gluename)
            new_list = [];
            new_concs = [];
            for tt = 1:size(obj.TileTypes, 1)
                if obj.TileTypes(tt, 1) == gluename
                    new_list = [new_list; obj.TileTypes(tt, :)];
                    new_concs = [new_concs; obj.Concs(tt)];
                end
            end
        end
    end

    methods(Static)

        %% Tile set initialization for different modes
        function [tile_list, concs] = init_linear_tile_set(concentration)
            % For the linear tile set
            % The only glue directions are WU, WD, EU, and ED
            % Only WU and WD can be inputs
            % Only EU and ED can be outputs
            % Populate all combinations of single inputs to one or two
            % outputs
            % Then double it for both the forward and backward channels

            % Initiate storage variables for the list of tile types and
            % their concentrations
            tile_list = [];
            concs = [];
            % Define the allowable glue directions
            input_dirs = ["WU", "WD"];
            output_dirs = ["EU", "ED"];

            % Enumerate combinations of channel, i/o, and directions
            fwd_input_glues = enum_glues('F', 'I', input_dirs);
            fwd_output_glues = enum_glues('F', 'O', output_dirs);
            bwd_input_glues = enum_glues('B', 'I', input_dirs);
            bwd_output_glues = enum_glues('B', 'O', output_dirs);

            % Match glues together into a standard tile type
            for i = 1:size(fwd_input_glues, 2)
                for o = 1:size(fwd_output_glues, 2)
                    g1 = fwd_input_glues(i);
                    g2 = bwd_input_glues(i);
                    g3 = fwd_output_glues(o);
                    g4 = "NULL";
                    g5 = bwd_output_glues(o);
                    g6 = "NULL";
                    if ~same_dir(g1, g3)
                        tile_list = [tile_list; g1 g2 g3 g4 g5 g6];
                        concs = [concs; concentration];
                    end
                end
            end
            
            % Match glues together into a branching tile type
            for i = 1:size(fwd_input_glues, 2)
                g1 = fwd_input_glues(i);
                g2 = bwd_input_glues(i);
                g3 = fwd_output_glues(1);
                g4 = fwd_output_glues(2);
                g5 = bwd_output_glues(1);
                g6 = bwd_output_glues(2);
                tile_list = [tile_list; g1 g2 g3 g4 g5 g6];
                concs = [concs; concentration];
            end
        end

        function [tile_list, concs] = init_radial_tile_set(concentration)
            % Initiate storage variables for the list of tile types and
            % their concentrations
            tile_list = [];
            concs = [];
            % Define the allowable glue directions
            input_dirs = ["NL", "NR", "SR", "SL", "WU", "WD", "EU", "ED"];
            output_dirs = ["NL", "NR", "SR", "SL", "WU", "WD", "EU", "ED"];

            % Enumerate combinations of channel, i/o, and directions
            fwd_input_glues = enum_glues('F', 'I', input_dirs);
            fwd_output_glues = enum_glues('F', 'O', output_dirs);
            bwd_input_glues = enum_glues('B', 'I', input_dirs);
            bwd_output_glues = enum_glues('B', 'O', output_dirs);

            % Radial needs to enforce additional rules:
            % 1. Since all directions can be inputs AND outputs, output
            % glues cannot be in the same direction as the inputs
            % 2. On branching tiles, output glues need to be on the same
            % side as each other
            % 3. Corner glues (e.g. input on SR, output on ED) are not
            % allowed as it is an immediate conflict

            % Match glues together into a standard tile type
            for i = 1:size(fwd_input_glues, 2)
                for o = 1:size(fwd_output_glues, 2)
                    g1 = fwd_input_glues(i);
                    g2 = bwd_input_glues(i);
                    g3 = fwd_output_glues(o);
                    g4 = "NULL";
                    g5 = bwd_output_glues(o);
                    g6 = "NULL";
                    if ~same_side(g1, g3) && ~same_corner(g1, g3)
                        tile_list = [tile_list; g1 g2 g3 g4 g5 g6];
                        concs = [concs; concentration];
                    end
                end
            end
            
            % Match glues together into a branching tile type
            fwd_combinations = combinations(fwd_output_glues, fwd_output_glues);
            bwd_combinations = combinations(bwd_output_glues, bwd_output_glues);

            for i = 1:size(fwd_input_glues, 2)
                for o = 1:size(fwd_combinations, 1)
                    g1 = fwd_input_glues(i);
                    g2 = bwd_input_glues(i);
                    g3 = fwd_combinations(o, 1);
                    g4 = fwd_combinations(o, 2);
                    g5 = bwd_combinations(o, 1);
                    g6 = bwd_combinations(o, 2);
                    if ~same_side(g1, g3) && ~same_side(g1, g4) && same_side(g3, g4) && ~same_dir(g3, g4) && ~same_corner(g1, g3) && ~same_corner(g1, g4)
                        tile_list = [tile_list; g1 g2 g3 g4 g5 g6];
                        concs = [concs; concentration];
                    end
                end
            end
        end
    end
end