function tf = is_connected(u, v)
    % v.OutputConnections has u && u.InputConnections has v
    % means they are connected
    % v is the tile closer to the source
    % u is the tile closer to the goal
    u_has_v = 0;
    v_has_u = 0;
    for vv = v.OutputConnections
        if vv == u
            v_has_u = 1;
        end
    end
    for uu = u.InputConnections
        if uu == v
            u_has_v = 1;
        end
    end
    if u_has_v && v_has_u
        tf = 1;
    else
        tf = 0;
    end
end