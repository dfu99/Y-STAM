function [lastLUT, loops_since_last_update] = debug(myGrid, myTileSet, lastLUT, loops_since_last_update)

    % DEBUG SANITY CHECK
    % If the LUT has not updated after X iterations, something is
    % likely wrong
    disp_LUT(myGrid.LUT, myTileSet);
    if LUT_updated(lastLUT, myGrid.LUT)
        lastLUT = myGrid.LUT;
        loops_since_last_update = 0;
    elseif loops_since_last_update > 100
        disp_LUT(myGrid.LUT, myTileSet);
        error("Something is wrong.")
    else
        loops_since_last_update = loops_since_last_update + 1;
    end
    disp("Loops since last update:")
    disp(loops_since_last_update)
end