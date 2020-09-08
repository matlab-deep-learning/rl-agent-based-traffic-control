classdef TrafficLight < trafficControl.TrafficController
    
    properties
        Cliques
        Cycle
        Phase
    end
    
    methods
        function obj = TrafficLight(nodes,varargin)
            obj@trafficControl.TrafficController(nodes,varargin{:});
        end
        
        function running = move(obj,SimulationTime)
            obj.IsOpen = false(size(obj.Nodes));
            t = mod(SimulationTime,obj.Cycle(end));
            phase = discretize(t,obj.Cycle);
            numPhases = max(obj.Cliques);
            for i =1:numPhases
                if phase==i
                    obj.IsOpen(obj.Cliques==i)=true;
                end
            end
            running = true;
        end
    end
end

