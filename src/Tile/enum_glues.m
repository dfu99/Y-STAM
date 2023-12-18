function glue_list = enum_glues(channel, io, dir)
    
    % Wrong typing will mess things up
    if ~isstring(dir)
        system("error")
    end
    max_enum = size(channel, 2) * size(dir, 2) * size(io, 2);
    glue_list(1:max_enum) = "";
    idx = 1;
    for i = 1:size(channel, 2)
        for j = 1:size(io, 2)
            for k = 1:size(dir, 2)
                glue_list(idx) = [channel(i) io(j) char(dir(k))];
                idx = idx+1;
            end
        end
    end
end