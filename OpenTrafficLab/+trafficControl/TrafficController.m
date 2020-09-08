classdef TrafficController  < driving.scenario.MotionStrategy...
        & driving.scenario.mixin.PropertiesInitializableInConstructor
    
    
    properties 
        Scenario
        Nodes = Node.empty % List of nodes the traffic controller manages
        IsOpen % Boolean list indicating wether the node can be entered
        PlotHandles = plot3([],[],[]);
    end
    
    methods
        function obj = TrafficController(nodes,varargin)
            
            obj@driving.scenario.MotionStrategy(nodes(1).Scenario.actor);
            obj@driving.scenario.mixin.PropertiesInitializableInConstructor(varargin{:});
            
            obj.EgoActor.MotionStrategy = obj;
            obj.EgoActor.IsVisible = false;
            %obj.EgoActor.Position = nodes(1).getRoadCenterFromStation(10);
            
            obj.Scenario = nodes(1).Scenario;
            obj.Nodes = nodes;
            obj.IsOpen = false(size(nodes));
            
        end
        
        function set.Nodes(obj,nodes)
            for node = nodes
                if ~any(obj.Nodes==node)
                    obj.Nodes(end+1)=node;
                    node.TrafficController=obj;
                end
            end
        end
        
        function running = move(obj,SimulationTime)
            
            running = true;
        end
        
        function running = restart(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
    
    methods
        function state = getNodeState(obj,node)
            state = obj.IsOpen(obj.Nodes==node);
        end
    end
    
    methods % plot methods
        function plotOpenPaths(obj,ax)
            green = [0.4660 0.6740 0.1880];
            red = [0.6350 0.0780 0.1840];
            yellow = [0.9290 0.6940 0.1250];
            if nargin<2
                ax=gca;
            end
            hold on
            if isempty(obj.PlotHandles)
                for node=obj.Nodes
                    obj.PlotHandles(end+1) = plot3(ax,node.Mapping(:,2),node.Mapping(:,3),node.Mapping(:,4)+10);
                end
            end
            for idx = 1:length(obj.Nodes)
                p = obj.PlotHandles(idx);
                node = obj.Nodes(idx);
                p.XData = node.Mapping(:,2);
                p.YData = node.Mapping(:,3);
                p.ZData = node.Mapping(:,4)+0;
                
                p.LineWidth = 2;
                if obj.IsOpen(idx)==true
                    p.Color = [green,1];
                else
                    p.Color = [red,0.2];
                end
            end
        end
    end
end

