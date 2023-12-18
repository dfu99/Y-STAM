function tf = is_direction(defn, direction)
% Checks if a tile outputs in the given direction

    % Default input
    tf = 0;
    % Iterate through every glue
    for glue = defn
        g = char(glue); % Convert to char array
        if g(2) == 'O'
            if g(3:4) == direction % Check direction code
                tf = 1;
            end
        end
    end
end