function [LUT, ecmtx] = propagate_deletions(LUT, ecmtx, n, ecm_params)
    % Deletes orphaned branches and paths
    % Must be run after glues are settled otherwise cases will be incorrect

    ecm_strength = ecm_params{1};
    ecm_signal_radius = ecm_params{2};
    mtx_refresh_rate = ecm_params{3};
    update_mode = ecm_params{4};


    % stack
    stack = [];
    % Find all Tiles from the LookupTable
    idx = find(~cellfun(@isempty, LUT));
    for i = idx
        u = LUT{i};

        %% Error checking
        if ~isobject(u)
            continue
        % Ignore disassembly steps for Source and Goal tiles
        elseif isobject(u) && (u.name == "Source" || u.name == "Goal")
                continue;
        elseif u.ColorFlag == 3 || u.ColorFlag == -1
            % Ignore on multistage, deadzone
            continue
        end

        %% Build the pending deletion stack
        % Build a stack from completely disconnected tiles, these represent
        % orphaned paths.
        if ~isobject(u.InputConnections{1}) && ~isobject(u.InputConnections{2})
            stack = [stack i];
        end
    end

    % resolve the stack
    while(~isempty(stack))
        pop_idx = stack(1);
        stack = stack(2:end);
        this_tile = LUT{pop_idx};
        % If there is negative ecm_strength, we are using chemorepulsive
        % options - aka, something failed here, so stay away from the
        % region for the time being
        if ecm_strength < 0
            ecmtx = layer_update(ecmtx, [ecm_strength, ecm_signal_radius, mtx_refresh_rate], {this_tile}, n, update_mode);
        end
        % Skip, avoid removing Goal tiles that might exist along a
        % pathway when multiple goal tiles exist throughout the
        % simulation space
        if this_tile.name == "Goal"
            % Stack was already popped, so do nothing
        else
            for next_tile_idx = 1:length(this_tile.OutputConnections)
                next_tile = this_tile.OutputConnections{next_tile_idx};
                if isobject(next_tile)
                    disconnect_detach(this_tile, next_tile)
                    push_idx = pos2idx(next_tile.Position(1), next_tile.Position(2), n);
                    stack = [stack push_idx];
                end
            end

            % Tile concs are not restored by default
            % if usetileconc
            %     this_defn = this_tile.getDefn();
            %     myTileSet.inc_conc(this_defn);
            % end
            LUT{pop_idx} = [];
        end
    end
end