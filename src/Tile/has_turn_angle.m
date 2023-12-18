function tfAngle = has_turn_angle(defn, angle)
% Determines whether a tiles directions changes in the specific direction
% Counter-clockwise rotation around a compass is +'ve angle
% Clockwise rotation is -'ve angle

    % Fix to 90 degree angles
    angle = mod(round(angle/360*4) * 90, 360);
    
    % Get the input compass direction
    input_defn = char(defn(1));
    output_defn = char(defn(3));
    
    input_compass = input_defn(3);
    % output_compass = output_defn(3);
    
    if strcmp(input_compass, 'N') && (strcmp(output_defn(3:4), 'WU') || strcmp(output_defn(3:4), 'WD') || strcmp(output_defn(3:4), 'SL'))
        turnAngle = 90;
    elseif strcmp(input_compass, 'S') && (strcmp(output_defn(3:4), 'EU') || strcmp(output_defn(3:4), 'ED') || strcmp(output_defn(3:4), 'NR'))
        turnAngle = 90;
    elseif strcmp(input_compass, 'E') && (strcmp(output_defn(3:4), 'NR') || strcmp(output_defn(3:4), 'NL') || strcmp(output_defn(3:4), 'WU'))
        turnAngle = 90;
    elseif strcmp(input_compass, 'W') && (strcmp(output_defn(3:4), 'SL') || strcmp(output_defn(3:4), 'SR') || strcmp(output_defn(3:4), 'ED'))
        turnAngle = 90;
    elseif strcmp(input_compass, 'N') && (strcmp(output_defn(3:4), 'EU') || strcmp(output_defn(3:4), 'ED') || strcmp(output_defn(3:4), 'SR'))
        turnAngle = 270;
    elseif strcmp(input_compass, 'S') && (strcmp(output_defn(3:4), 'ED') || strcmp(output_defn(3:4), 'EU') || strcmp(output_defn(3:4), 'NL'))
        turnAngle = 270;
    elseif strcmp(input_compass, 'E') && (strcmp(output_defn(3:4), 'SR') || strcmp(output_defn(3:4), 'SL') || strcmp(output_defn(3:4), 'WD'))
        turnAngle = 270;
    elseif strcmp(input_compass, 'W') && (strcmp(output_defn(3:4), 'NL') || strcmp(output_defn(3:4), 'NR') || strcmp(output_defn(3:4), 'EU'))
        turnAngle = 270;
    else
        tfAngle = false;
        return
    end
    
    if turnAngle == angle
        tfAngle = true;
    else
        tfAngle = false;
    end

end