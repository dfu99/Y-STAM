function tfTurns = is_turning(defn)
% Determines whether a tile changes the direction of the pathway
% A turning tile usually has adjacent compass glues, e.g. N and E
% A linear tile has opposite glues, e.g. W and E

% Do not have to check all positions
% Structure of definitions ensures that first two elements are forward and
% backward channels
% Last four elements are output glues that are all on the same tile edge

input_defn = char(defn(1));
output_defn = char(defn(3));

input_compass = input_defn(3);
output_compass = output_defn(3);

if strcmp(input_compass, 'N') && strcmp(output_compass, 'S')
    tfTurns = 0;
elseif strcmp(input_compass, 'S') && strcmp(output_compass, 'N')
    tfTurns = 0;
elseif strcmp(input_compass, 'W') && strcmp(output_compass, 'E')
    tfTurns = 0;
elseif strcmp(input_compass, 'E') && strcmp(output_compass, 'W')
    tfTurns = 0;
else
    tfTurns = 1;
end

end