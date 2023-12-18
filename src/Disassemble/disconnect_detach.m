function disconnect_detach(pathwayTile, detachedTile)
%DISCONNECT_DETACH Detaches detachedTile from pathwayTile
%   Find detachedTile on the OutputConnections of pathwayTile
%       Return this cell back to 1 (ON)
%   Find pathwayTile on the InputConnections of detachedTile
%       Set this cell to -1 (OFF)

    for oc = 1:length(pathwayTile.OutputConnections)
        if pathwayTile.OutputConnections{oc} == detachedTile
            pathwayTile.OutputConnections{oc} = 1;
        end
    end
    
    for ic = 1:length(detachedTile.InputConnections)
        if detachedTile.InputConnections{ic} == pathwayTile
            detachedTile.InputConnections{ic} = -1;
        end
    end
end
