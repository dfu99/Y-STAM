function updated = LUT_updated(lastLUT, thisLUT)
% Verifies if there were changes to the lookup table

    % Instead of comparing the entire n x n table, only compare the
    % non-empty cells
    LLUT_idx = find(~cellfun(@isempty, lastLUT));
    TLUT_idx = find(~cellfun(@isempty, thisLUT));

    % If the lookup tables have different number of entries, updated = true
    if max(size(LLUT_idx)) ~= max(size(TLUT_idx))
        updated = 1;
        return;
    end

    % If the entries are different, updated = true
    if LLUT_idx ~= TLUT_idx
        updated = 1;
        return;
    end
    % Otherwise there were not any updates detected, updated = false
    updated = 0;
end