function propagate(tileToSource, tileToGoal)
% Inputs    u: The Goal tile
%           v: pathway input into the target tile
% Outputs   n/a
% Process   Connects the backward channels of tiles from the Goal to the
%           Source

    % Error flagging
    % First confirm that u is the Goal tile
    if tileToGoal.name ~= "Goal"
        error("Non-Goal tile cannot initiate the backward channel signal propagation.")
    end
    % Check connection
    if ~is_adjacent(tileToGoal, tileToSource)
        error("Tile must be adjacent to Goal tile to trigger feedback signal.")
    end

    % Find their relative position
    % Then figure out which glues to connect
    [glue1, glue2] = probe_glues(tileToSource, tileToGoal);
    
    % Connect the forward channel of the tiles
    idx1 = tileToSource.getOutputIndex(glue1);
    idx2 = tileToGoal.getInputIndex(glue2);
    tileToSource.OutputConnections{idx1} = tileToGoal;
    tileToGoal.InputConnections{idx2} = tileToSource;

    % Now propagate the signal backwards
    % Update the ColorFlag to indicate it is backward signal-passing
    tileToSource.ColorFlag = 4;
    % Then iterate back towards the source tile
    while(1)
        % Error checking
        % Make sure we are iterating backwards to a real tile
        if ~isobject(tileToSource.InputConnections{1})
            disp(tileToSource)
            msg = "The traceback encountered a break in the pathway at Tile position " + mat2str(tileToSource.Position);
            error(msg)
        end

        % next_tileToSource is iterating one step back along the
        % pathway towards the Source tile
        % By default, any Tile only has one Input glue that is doubled for
        % both channels. {1} is the forward channel and {2} is the backward
        % channel. But the Output glue index on next_tileToSource is not
        % guaranteed if it was branching tile.

        next_tileToSource = tileToSource.InputConnections{1};
        bwd_gluename = tileToSource.InputGlues(2);
        next_gluename = glue_complement(bwd_gluename);
        output_idx = next_tileToSource.getOutputIndex(next_gluename);

        % Stitch up the back channels
        tileToSource.InputConnections{2} = next_tileToSource;
        next_tileToSource.OutputConnections{output_idx} = tileToSource;

        % Move the iterator
        tileToSource = next_tileToSource;

        % Reached the source tile AND finished stitching the first tile in
        % the pathway to the source tile
        if tileToSource.name == "Source"
            break
        else % This will update all the tile coloring except for the Source tile on the last loop
            tileToSource.ColorFlag = 4;
        end
    end
   
end