function glueC = glue_complement(GlueName1)
% Return the binding complement of a glue
    % Cast any strings to char
    GlueName1 = char(GlueName1);

    % Complement each feature
    channel = GlueName1(1);
    if GlueName1(2) == 'I'
        io = 'O';
    elseif GlueName1(2) == 'O'
        io = 'I';
    else
        msg = strcat("Cannot complement ", GlueName1(2), " from glue ", GlueName1, ".");
        error(msg)
    end
    
    if GlueName1(3) == 'N'
        compass = 'S';
    elseif GlueName1(3) == 'S'
        compass = 'N';
    elseif GlueName1(3) == 'E'
        compass = 'W';
    elseif GlueName1(3) == 'W'
        compass = 'E';
    else
        msg = "Cannot complement " + str(GlueName1(3)) + ".";
        error(msg)
    end
    
    if GlueName1(4) == 'L'
        side = 'R';
    elseif GlueName1(4) == 'R'
        side = 'L';
    elseif GlueName1(4) == 'U'
        side = 'D';
    elseif GlueName1(4) == 'D'
        side = 'U';
    else
        msg = "Cannot complement " + str(GlueName1(4)) + ".";
        error(msg)
    end
    
    glueC = [channel io compass side];

end