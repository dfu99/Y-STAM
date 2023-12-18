function [doBreak, doFeedback, tf, hitflag, hit_time] = is_done(LUT, grid, n, tf, timesteps, run_params)

    hitflag = run_params(1);
    hit_time = run_params(2);
    continuous = run_params(3);
    calcfeedbackonly = run_params(4);
    time_limit = run_params(5);
    usefeedback = run_params(6);
    
    % Default outputs
    doFeedback = false;
    doBreak = false;

    % Case 1: Not continuous and hit the target tile
    % (likely not testing feedback)
    if ~isempty(find(grid(:, end-1), 1)) && ~continuous
        doBreak = true;
        return;
    % Case 2: Continuous mode runs until the time limit
    % Only continuous mode accomodates feedback functionality
    elseif continuous
        % Case 2.1: Over the time limit, break
        if timesteps >= time_limit
            doBreak = true;
            return;
        end

        % We only count hits for last column, terminal tiles
        % Don't count hits for multistage intermediate feedback tiles
        [NW, ~, NE, ~, SE, ~, SW, ~] = check_inputs(tf{1}, LUT, n);
        % Update hit time counter
        if NW || NE || SE || SW
            if calcfeedbackonly
                hitflag = true; 
            end
            hit_time = hit_time + 1;

        % Case 2.2: Special case scenario for quantifying feedback
        % Can't assess feedback if we completely missed the target tile
        elseif ~isempty(find(grid(:, end-1), 1)) && calcfeedbackonly && ~hitflag
            doBreak = true;
            return;
        % Case 2.3: Special case scenario for quantifying feedback
        % Once the first feedback-activated pathway breaks, stop the trial
        else
            if calcfeedbackonly && hitflag
                doBreak = true;
                return;
            end
        end

        % Skip feedback if usefeedback is false
        % Evaluating calcfeedbackonly takes precedence over this
        if usefeedback
            doBreak = false;
            doFeedback = true;
            return;
        end
    % Case 3: Not continuous but failed to travel full distance within the
    % time limit
    elseif ~continuous && time_limit > 0
        if timesteps >= time_limit
            doBreak = true;
            return;
        end
    end
    % Case 4: Otherwise, keep going
    return;
end