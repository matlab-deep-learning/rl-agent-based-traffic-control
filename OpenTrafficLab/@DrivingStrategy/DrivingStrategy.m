classdef DrivingStrategy < driving.scenario.MotionStrategy...
        & driving.scenario.mixin.PropertiesInitializableInConstructor
    %% Properties
    
    properties
       Scenario
       %
       Data = struct('Time',[],...
                     'Station',[],...
                     'Speed',[],...
                     'Node',Node.empty,...
                     'UDStates',[],...
                     'Position',[]);
       NextNode = Node.empty % Vehicle's planned path
       UDStates = [] % User defined states
       
       % Parameters
       DesiredSpeed = 10; % [m/s]
       ReactionTime = 0.8; % [s]
       
       %
       CarFollowingModel = 'Gipps'; % Options: 'IDM','Gipps'
       
       % Flags
       StoreData = true; % Set to True to store time series data in Data structure
       StaticLaneKeeping = true; % % Set to false to implement user define lateral control
    end
    
    properties (Dependent,Access = protected)
        % Vehicle States
        Position(3,1) double {mustBeReal, mustBeFinite}
        Velocity(3,1) double {mustBeReal, mustBeFinite}
        ForwardVector(3,1)double {mustBeReal, mustBeFinite}
        Speed
    end
    
    properties (Access = protected)
        % Input States
        Acceleration(1,1) double {mustBeReal, mustBeFinite} = 0
        AngularAcceleration(1,1) double {mustBeReal, mustBeFinite} = 0
    end
    properties (Access = protected)
        % Position Dependent Variables
        Node = Node.empty;
        Station = [];
        % Environment Dependent Variables
        IsLeader = false;
        Leader = driving.scenario.Vehicle.empty;
        LeaderSpacing = nan;
    end
    
    %% Constructor
    methods
        function obj = DrivingStrategy(egoActor,varargin)
            obj@driving.scenario.MotionStrategy(egoActor);
            obj@driving.scenario.mixin.PropertiesInitializableInConstructor(varargin{:});
            egoActor.MotionStrategy = obj;
            obj.Scenario = egoActor.Scenario;
            obj.Speed = obj.DesiredSpeed;
        end
    end
    %% Set and Get methods
    methods
        % Position
        function set.Position(obj,pos)
             obj.EgoActor.Position = pos;
        end
        function pos = get.Position(obj)
            pos = nan(length(obj),3);
            for idx = 1:length(obj)
                pos(idx,:) = obj(idx).EgoActor.Position;
            end
        end
        % Velocity
        function set.Velocity(obj,vel)
            obj.EgoActor.Velocity = vel;
        end
        function vel = get.Velocity(obj)
            vel = nan(length(obj),3);
            for idx = 1:length(obj)
                vel(idx,:) = obj(idx).EgoActor.Velocity;
            end
        end
        % Forward Vector
        function set.ForwardVector(obj,dir)
            if all(size(dir)==[3,1])
                dir=dir';
            end
            obj.EgoActor.ForwardVector = dir;
        end
        function dir = get.ForwardVector(obj)
            dir = nan(length(obj),3);
            for idx = 1:length(obj)
                dir(idx,:) = obj(idx).EgoActor.ForwardVector;
            end
        end
        % Speed
        function s = get.Speed(obj)
            s = obj.ForwardVector*obj.Velocity';
        end
        function set.Speed(obj,speed)
            obj.EgoActor.Velocity = obj.EgoActor.ForwardVector*speed;
        end
        
        % Node
        function set.Node(obj,node)
            if node == obj.Node
                return
            end
            
            if ~isempty(obj.Node)
                removeVehicle(obj.Node,obj.EgoActor);
                if ~isempty(node)
                    addVehicle(node,obj.EgoActor);
                end
                obj.Node = node;
            else
                if ~isempty(node)
                    addVehicle(node,obj.EgoActor);
                end
                obj.Node = node;
            end
                
            
        end
        
    end
    %% Public Access Methods
    methods (Access = public)
        function s = getStationDistance(obj,time) 
            if nargin<2 %If no time is given assume current sim time
                time = obj(1).Scenario.SimulationTime;
            end
            dt = obj(1).Scenario.SampleTime;
            for idx = 1:length(obj)
                tIdx = round((time-obj(idx).Data.Time(1))/dt)+1;
                if tIdx>0 && tIdx<length(obj(idx).Data.Time)+1
                    s(idx) = obj(idx).Data.Station(tIdx);
                else
                    error('The requested time is not on record')
                end
            end
        end
        function node = getNode(obj,time)
            if nargin<2 %If no time is given assusme current sim time
                time = obj(1).Scenario.SimulationTime;
            end
            dt = obj(1).Scenario.SampleTime;
            for idx = 1:length(obj)
                tIdx = round((time-obj(idx).Data.Time(1))/dt)+1;
                if tIdx>0 && tIdx<length(obj(idx).Data.Time)+1
                    node(idx) = obj(idx).Data.Node(tIdx);
                else
                    error('The requested time is not on record')
                end
            end
        end
        function v = getSpeed(obj,time)
            if nargin<2 %If no time is given assusme current sim time
                time = obj(1).Scenario.SimulationTime;
            end
            dt = obj(1).Scenario.SampleTime;
            for idx = 1:length(obj)
                tIdx = round((time-obj(idx).Data.Time(1))/dt)+1;
                if tIdx>0 && tIdx<length(obj(idx).Data.Time)+1
                    v(idx) = obj(idx).Data.Speed(tIdx);
                else
                    error('The requested time is not on record')
                end
            end
        end
        function pos = getPosition(obj,time)
            if nargin<2 %If no time is given assusme current sim time
                time = obj(1).Scenario.SimulationTime;
            end
            dt = obj(1).Scenario.SampleTime;
            for idx = 1:length(obj)
                tIdx = round((time-obj(idx).Data.Time(1))/dt)+1;
                if tIdx>0 && tIdx<length(obj(idx).Data.Time)+1
                    pos(idx,:) = obj(idx).Data.Position(tIdx,:);
                else
                    error('The requested time is not on record')
                end
            end
        end
        function states = getUDStates(obj,time)
            if nargin<2 %If no time is given assusme current sim time
                time = obj(1).Scenario.SimulationTime;
            end
            dt = obj(1).Scenario.SampleTime;
            for idx = 1:length(obj)
                tIdx = round((time-obj(idx).Data.Time(1))/dt)+1;
                if tIdx>0 && tIdx<length(obj(idx).Data.Time)+1
                    states(idx,:)  = obj(idx).Data.UDStates(tIdx,:);
                else
                    error('The requested time is not on record')
                end
            end
        end
    end
    %% Update State and Environment Dependent Variables

    methods (Access = private)
        function updateUDStates(obj)
            obj.UDStates = obj.UDStates;
        end
    end
    
    %% Helper methods
    methods (Access = protected)
              
        function [s,direction,offset]=getLaneInformation(obj)
            [s,direction,offset]=obj.Node.getStationDistance(obj.Position(1:2));
        end
        
        function length = getSegmentLength(obj)
            length = obj.Node.getRoadSegmentLength();
        end
        
        function goToNextNode(obj,SimulationTime)
            if ~isempty(obj.NextNode)
                obj.Node = obj.NextNode(1);
                obj.NextNode(1)=[];
            else
                obj.EgoActor.ExitTime = SimulationTime;
                obj.EgoActor.IsVisible = false;
                obj.Node = Node.empty;
            end
        end
        
        function injectVehicle(obj,t,speed)
            % Set the new node
            goToNextNode(obj)
            % Set the position and velocity
            obj.Position = getRoadCenterFromStation(obj.Node,0);
            if nargin>2
            obj.Speed = speed;
            end
            obj.Station = 0;
            updateUDStates(obj);
            addData(obj,t)
            obj.EgoActor.IsVisible=true;   
            
        end
        
        function addData(obj,t)
            if ~isempty(obj.Data.Time)
                if t~=obj.Data.Time(end)+obj.Scenario.SampleTime
                    error('Can only add data to the following time step')
                end
            end
            
            obj.Data.Time(end+1) = t;
            obj.Data.Station(end+1) = obj.Station;
            obj.Data.Node(end+1) = obj.Node;
            obj.Data.Speed(end+1) = obj.Speed;
            obj.Data.Position(end+1,:) = obj.Position;
            if ~isempty(obj.UDStates)
                obj.Data.UDStates(end+1,:) = obj.UDStates;
            end
            
            % Delete first entry if store data flag is false
            if ~obj.StoreData && length(obj.Data.Time)>2
                obj.Data.Time(1) = [];
                obj.Data.Station(1) = [];
                obj.Data.Node(1) = [];
                obj.Data.Speed(1) = [];
                obj.Data.Position(1,:) = [];
                if ~isempty(obj.UDStates)
                    obj.Data.UDStates(1,:) = [];
                end
                
            end
        end
        
        function orientEgoActor(obj,direction,offset)
            if nargin == 1
                [s,direction,offset]= obj.getLaneInformation();
            end
            obj.ForwardVector = [direction,0];
            obj.Position = obj.Position + [offset,0];
        end
        
        function [leader,leaderSpacing] = getLeader(obj,tNow)
            % Get other actors in the node and their stations
            actors = getVehiclesInSegment(obj);
            drivers = [actors.MotionStrategy];
            selfIdx = find(drivers == obj);
            stations = [drivers.Station];
            deltaStations = stations - stations(selfIdx);
            deltaStations(deltaStations<0.1)=inf;
            [leaderSpacing,idx]=min(deltaStations);
            if isinf(leaderSpacing)
                leaderSpacing = nan;
                leader = driving.scenario.Vehicle.empty;
                if ~isempty(obj.NextNode)
                    [sLeader,leader] = obj.NextNode(1).getTrailingVehicleStation(tNow);
                    if ~isempty(leader)
                        leaderSpacing = sLeader-leader.Length +(obj.getSegmentLength()-stations(selfIdx));
                    end
                end
            
            else
                leader = actors(idx);
                leaderSpacing = leaderSpacing-leader.Length;
            end
            
        end
        
        function actors = getVehiclesInSegment(obj)
            actors = obj.Node.getActiveVehicles();
        end
        
        function state = getNextNodeState(obj)
            state = 1;
            if ~isempty(obj.NextNode)
                if ~isempty(obj.NextNode(1).TrafficController)
                    state = obj.NextNode(1).getNodeState();
                end
            end
        end
    end
    %% Nominal Driving Logic
    methods
        function mode = determineDrivingMode(obj)
            % This function decides which mode(s) the driver is following,
            % and the creates and outputs the function handle to that mode
            
            segLength = obj.getSegmentLength();
            leader = obj.Leader;
            leaderSpacing = obj.LeaderSpacing;
            distToEnd = segLength-obj.Station;
            state = obj.getNextNodeState();
            isLeader = isempty(leader);
            leaderIsPastRoadEnd = leaderSpacing>distToEnd;
            
            % Determine the mode
            if state
                if isLeader
                    mode = 'ApproachingGreenLight';
                else
                    mode = 'CarFollowing';
                end
            else
                if isLeader
                    mode = 'ApproachingRedLight';
                else
                    if leaderIsPastRoadEnd
                        mode = 'ApproachingRedLight';
                    else
                        mode = 'CarFollowing';
                    end
                end
            end
        end
        
        function inputs = determineDrivingInputs(obj,mode)
            
            segLength = obj.getSegmentLength();
            leader = obj.Leader;
            distToEnd = segLength-obj.Station;
            
            switch mode
                case 'CarFollowing'
                    delVel = leader.MotionStrategy.Speed-obj.Speed;
                    leaderSpacing = obj.LeaderSpacing;
                case 'ApproachingRedLight'
                    delVel = 0 - obj.Speed;
                    leaderSpacing = distToEnd;
                case 'ApproachingGreenLight'
                    delVel = 0;
                    leaderSpacing = inf;
            end
            
            inputs = [carFollowing(obj,leaderSpacing,obj.Speed,delVel),0];
        end
        
        function acc = carFollowing(obj,spacing,speed,speedDiff)
            if strcmp(obj.CarFollowingModel,'IDM')
                acc = drivingBehavior.intelligentDriverModel(spacing,speed,speedDiff);
            end
            
            if strcmp(obj.CarFollowingModel,'Gipps')
                if mod(obj.Scenario.SimulationTime,obj.ReactionTime)<obj.Scenario.SampleTime
                    acc = drivingBehavior.gippsDriverModel(spacing,speed,speedDiff);
                else
                    acc = obj.Acceleration;
                end
                if ~isreal(acc)
                    acc = 0;
                end
            end
            
        end
        
        
        
    end
    %% Inherited Abstract Methods (move, restart)
    methods
        
        function running = move(obj,SimulationTime)
            
            dt =  obj.Scenario.SampleTime;
            tNow = SimulationTime - dt;
            tNext = SimulationTime;
            car = obj.EgoActor;
            
            %% Check vehicle's entry time, and manage injection
            
            if tNow>=car.ExitTime || tNow<car.EntryTime
                car.IsVisible = false;
                running = false;
                return
            end
            
            % Check if the vehicle's entry time has just been reached. If so, confirm there is
            % space in the road for it to enter. Otherwise, push entry time
            % back
            
            if (tNow - car.EntryTime>0)&&(tNow - car.EntryTime<dt)
                
                [s,leader] = getTrailingVehicleStation(obj.NextNode(1));                
                [a,v_b,v_a]=drivingBehavior.gippsDriverModel(s-1,obj.Speed,-obj.Speed);
                if v_b>1
                    speed = min(v_b,v_a);
                    injectVehicle(obj,tNow,speed);
                else
                    car.EntryTime = car.EntryTime+dt;
                    running = true;
                    return;
                end
                %%
                %c = discretize(s-5,[-inf,5,10,inf]);
%                 switch c
%                     case 1 %
%                         car.EntryTime = car.EntryTime+dt;
%                         running = true;
%                         return;
%                     case 2
%                         if ~isempty(leader)
%                             speed = leader.MotionStrategy.getSpeed(tNow);
%                         else
%                             speed=obj.Speed;
%                         end
%                         injectVehicle(obj,tNow);
%                     case 3
%                         injectVehicle(obj,tNow,obj.Speed);
%                         
%                 end
            end
            
            %% Set vehicle's state and variables to tNow
            % State
            obj.Position = getPosition(obj,tNow);
            obj.Speed = getSpeed(obj,tNow);
            % State dependent variables
            obj.Station = getStationDistance(obj,tNow);
            obj.Node = getNode(obj,tNow);
            
            % Environment Dependent Variables
            [obj.Leader,obj.LeaderSpacing]=getLeader(obj,tNow);
            if isempty(obj.Leader)
                obj.IsLeader = true;
            end
            %% Determine Driving Mode
            mode = determineDrivingMode(obj);
            
            %% Get Inputs
            inputs = determineDrivingInputs(obj,mode);
            
            obj.Acceleration = inputs(1);
            obj.AngularAcceleration = inputs(2);
            
            %% Integrate

                % Position and Velocity
            obj.Position = obj.Position + dt*car.Velocity;
            obj.Speed = obj.Speed + dt*obj.Acceleration;
                
                % Forward Vector
            %obj.ForwardVector = ... to be implemented 
            
            %% Update state dependent variables
            % Get new station distance, node and lane information
            [station, direction, offset] = getLaneInformation(obj);
            
            if station > getSegmentLength(obj) % Check if the veh entered a new node
                goToNextNode(obj,tNext)
                if isempty(obj.Node)
                    % The vehicle finished its path
                    running = false;
                    return
                else
                    % Get new staion andlane information
                    [station, direction, offset] = getLaneInformation(obj);
                end
                
            end
            obj.Station = station;
            updateUDStates(obj);
            
            if obj.StaticLaneKeeping %Orient veh along lane if lateral control is deactivated
                obj.orientEgoActor(direction,offset);
            end
            
            addData(obj,tNext);
            running = true;
        end
        
        function restart(obj)
            % Needs to be programmed
            
        end
    end
end

