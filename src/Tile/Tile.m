classdef Tile < handle

    %% PROPERTIES
    properties
        Position = [-1 -1];
        

        % Input glues
        % A tile should only ever have two input glues, same direction,
        % one of each channel
        % [FRWD CHANNEL INPUT, BKWD CHANNEL INPUT]
        InputGlues = ["NULL", "NULL"];

        % Output glues
        % A tile can have up to four output glues, two distinct directions,
        % one of each channel
        % [FRWD CHANNEL OUTPUT 1, FRWD CHANNEL OUTPUT 2, BKWD CHANNEL OUTPUT
        % 1, BKWD CHHANEL OUTPUT 2];
        % "NULL" = Glue does not exist on the tile
        OutputGlues = ["NULL", "NULL", "NULL", "NULL"];


        % Strengths match same element-wise formatting
        % Max: 1, Min: 0
        InputStrengths = [0 0];
        OutputStrengths = [0 0 0 0];

        % Connections
        % Per element array saves the connections
        % 1 = ON
        % 0 = LATENT
        % -1 = UNUSED
        % Tile object = Connected
        InputConnections = cell(1, 2);
        OutputConnections = cell(1, 4);

        ColorFlag = 1; % Legend on grid:
                        % -1 gray: obstacle
                        % 0 white: nothing
                        % 1 black: tile exists
                        % 2 red: source tile
                        % 3 blue: target tile
                        % 4 purple: receiving feedback

        SeedColoring = 0; % An RGB value that is set for Source tiles only that propagates a color to its connected seeds

        FBState = -1; % Feedback state. 
                        % -1 Disabled (Default). 
                        % 0.1 Used for Down input. 
                        % 0.2 Used to Up input. 
                        % 1 Available.

        name = "Tile";
    end

    %% METHODS
    methods
        % CLASS CONSTRUCTOR
        function obj = Tile(glue_list, s)
            if nargin == 0
                % No default constructor
                error("Error");
            end

             % Set the glues
             if nargin > 0 
                obj.InputGlues = [glue_list(1) glue_list(2)];
                obj.OutputGlues = [glue_list(3) glue_list(4) glue_list(5) glue_list(6)];

                obj.InputStrengths = [s s];
                obj.OutputStrengths = [s s s s];

                obj.InputConnections{1} = 1; obj.InputConnections{2} = 1;
                obj.OutputConnections{1} = 1; obj.OutputConnections{2} = 0;
                for i = 3:4
                    if glue_list(i) == "NULL"
                        obj.OutputConnections{i} = -1;
                    else
                        obj.OutputConnections{i} = 1;
                    end
                end
                for i = 5:6
                    if glue_list(i) == "NULL"
                        obj.OutputConnections{i} = -1;
                    else
                        obj.OutputConnections{i} = 0;
                    end
                end
             end
        end

        function defn = getDefn(obj)
            defn = [obj.InputGlues obj.OutputGlues];
        end

        function idx = getInputIndex(obj, gluename)
            % Returns the index # of the input glue
            for i = 1:length(obj.InputGlues)
                if strcmp(gluename, obj.InputGlues(i))
                    idx = i;
                    return
                end
            end
            msg = ["Did not find ", gluename, "."];
            error(msg)
        end

        function idx = getOutputIndex(obj, gluename)
            % Returns the index # of the output glue
            for i = 1:length(obj.OutputGlues)
                if strcmp(gluename, obj.OutputGlues(i))
                    idx = i;
                    return
                end
            end
            msg = ["Did not find ", gluename, "."];
            error(msg)
        end
        
        % OTHER FUNCTIONS
        function setglues(obj, arr_i, arr_o)
            obj.InputConnections = arr_i;
            obj.OutputConnections = arr_o;
        end

        function settype(obj, t, varargin)
            p = inputParser;

            addRequired(p, 'obj')
            addRequired(p, 't')
            addParameter(p, 'Num', -1)

            parse(p, obj, t, varargin{:});
            obj = p.Results.obj;
            t = p.Results.t;
            sourcebranches = p.Results.Num;


            if t == "linear-goal"
                % No outputs
                % Only tile with multiple inputs
                obj.InputGlues = ["FIWD", "FIWU", "BIWD", "BIWU"];
                s = obj.InputStrengths(1);
                obj.InputStrengths = [s s s s];
                setglues(obj, {1 1 0 0}, {-1 -1 -1 -1})
                obj.name = "Goal";
            elseif t == "radial-goal"
                % No outputs
                % Only tile with multiple inputs
                obj.InputGlues = ["FIWD", "FIWU", "FISR", "FISL", "FIEU", "FIED", "FINL", "FINR", "BIWD", "BIWU", "BISR", "BISL", "BIEU", "BIED", "BINL", "BINR"];
                s = obj.InputStrengths(1);
                obj.InputStrengths = [s s s s s s s s s s s s s s s s];
                setglues(obj, {1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0}, {-1 -1 -1 -1})
                obj.name = "Goal";
            elseif t == "radial-source"
                % Inputs off
                % Fwd channel outputs on
                % Bwd channel outputs latent
                if sourcebranches == 1
                    obj.OutputGlues = ["FOWD", "BOWD"];
                    s = obj.OutputStrengths(1);
                    obj.OutputStrengths = [s s];
                    setglues(obj, {-1 -1}, {1 0})
                elseif sourcebranches == 2
                    obj.OutputGlues = ["FOWD", "FOEU", "BOWD", "BOEU"];
                    s = obj.OutputStrengths(1);
                    obj.OutputStrengths = [s s s s];
                    setglues(obj, {-1 -1}, {1 1 0 0})
                elseif sourcebranches == 3
                    obj.OutputGlues = ["FOWD", "FOSR", "FOEU", "BOWD", "BOSR", "BOEU"];
                    s = obj.OutputStrengths(1);
                    obj.OutputStrengths = [s s s s s s];
                    setglues(obj, {-1 -1}, {1 1 1 0 0 0})
                elseif sourcebranches == 4
                    obj.OutputGlues = ["FOWD", "FOSR", "FOEU", "FONL", "BOWD", "BOSR", "BOEU", "BONL"];
                    s = obj.OutputStrengths(1);
                    obj.OutputStrengths = [s s s s s s s s];
                    setglues(obj, {-1 -1}, {1 1 1 1 0 0 0 0})
                else
                    error("Unrecognized SourceBranches argument.")
                end

                obj.name = "Source";
            elseif t == "linear-source"
                % Inputs off
                % Fwd channel outputs on
                % Bwd channel outputs latent
                roll = rand<0.5;
                if roll
                    obj.OutputGlues = ["FOEU", "NULL", "BOEU", "NULL"];
                else
                    obj.OutputGlues = ["FOED", "NULL", "BOED", "NULL"];
                end
                setglues(obj, {-1 -1}, {1 -1 0 -1})
                s = obj.OutputStrengths(1);
                obj.OutputStrengths = [s s s s];
                obj.name = "Source";
            elseif t == "dead"
                % All glues off
                setglues(obj, {-1 -1}, {-1 -1 -1 -1})
                obj.ColorFlag = -1;
                obj.name = "Dead";
            elseif t == "tile"
                % All glues in use
                % Forward channel glues on
                % Backward channel glues latent
                setglues(obj, {1 0}, {1 1 0 0})
                obj.ColorFlag = 1;
                obj.name = "Tile";
            else
                error("Not a valid tile type.")
            end
        end
    end
end