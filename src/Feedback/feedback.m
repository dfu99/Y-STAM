function [LUT, tf] = feedback(LUT, n, tf)
% Check whether any of the target tiles have adjacent tiles
    for k = 1:max(size(tf))
        [NW, NWidx, NE, NEidx, SE, SEidx, SW, SWidx] = check_inputs(tf{k}, LUT, n);
        % If feedback tile is active
        if tf{k}.FBState == 1
            % Avoid running the code again if the signal is already
            % propagating
            if NW && LUT{NWidx}.ColorFlag ~= 4
                propagate(LUT{NWidx}, tf{k})
            elseif NE && LUT{NEidx}.ColorFlag ~= 4
                propagate(LUT{NEidx}, tf{k})
            elseif SW && LUT{SWidx}.ColorFlag ~= 4
                propagate(LUT{SWidx}, tf{k})
            elseif SE && LUT{SEidx}.ColorFlag ~= 4
                propagate(LUT{SEidx}, tf{k})
            end
        end
    end
end