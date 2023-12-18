function canBind = binding_rules(GlueName1, GlueName2)
 
    % Each glue name is "<Channel><I/O><Direction>"
    % Glues can only bind diagonal directions
    % Opposite I/O
    % Same Channel
    
    % Enforce char typing
    GlueName1 = char(GlueName1);
    GlueName2 = char(GlueName2);

    % Verify Channels
    if GlueName1(1) == GlueName2(1)
        correct_channel = true;
    else
        canBind = false;
        return;
    end

    % Verify I/O
    if GlueName1(2) == 'O' && GlueName2(2) == 'I'
        correct_io = true;
    elseif GlueName1(2) == 'I' && GlueName2(2) == 'O'
        correct_io = true;
    else
        canBind = false;
        return;
    end
    
    % Verify Directions
    correct_compass = false;
    GlueDir = [GlueName1(3) GlueName2(3)];
    AllowedDirs = ["NS", "SN", "WE", "EW"];
    for i = 1:4
        if GlueDir == AllowedDirs(i)
            correct_compass = true;
        end
    end
    correct_diag = false;
    GlueDiag = [GlueName1(4) GlueName2(4)];
    AllowedDiag = ["UD", "DU", "LR", "RL"];
    for i = 1:4
        if GlueDiag == AllowedDiag(i)
            correct_diag = true;
        end
    end
    if correct_diag && correct_compass
        correct_dir = true;
    else
        correct_dir = false;
    end
    
    % Match all
    if correct_io && correct_channel && correct_dir
        canBind = true;
    else
        canBind = false;
    end
    return;
end