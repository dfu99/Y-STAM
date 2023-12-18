function LUT = settle_colors(LUT)

    idx = find(~cellfun(@isempty, LUT));
    for i = idx
    % for i = n:-1:1 % Go backwards
        u = LUT{i};
        if isobject(u)
            % Ignore disassembly steps for Source and Goal tiles
            if u.name == "Source" || u.name == "Goal"
                continue;
            end
            connected = false;
            if u.ColorFlag == 4
                for vidx = 1:length(u.OutputConnections)
                    v = u.OutputConnections{vidx};
                    if isobject(v) && v.ColorFlag >= 3
                        connected = true;
                    end
                end
                if ~connected
                    u.ColorFlag = 1;
                end
            end
        end
    end
end