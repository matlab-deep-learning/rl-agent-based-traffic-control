classdef DrivingStrategyRL  < DrivingStrategy
    % Copyright 2020 The MathWorks, Inc.
    % DrivingStrategy specialized in reinforcement learning setting
    
    methods
        function obj = DrivingStrategyRL(egoActor,varargin)
            obj@DrivingStrategy(egoActor,varargin{:});
        end
        
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
            timeToInt = distToEnd/obj.Speed;
            minHeadway = 0;
            % Determine the mode
            if isLeader
                if state
                    mode = 'ApproachingGreenLight';
                elseif timeToInt>minHeadway
                    mode = 'ApproachingRedLight';
                else
                    mode = 'ApproachingGreenLight';
                end
            else
                if leaderIsPastRoadEnd
                    if state
                        mode = 'CarFollowing';
                    elseif timeToInt>minHeadway
                        mode = 'ApproachingRedLight';
                    else
                        mode = 'ApproachingGreenLight';
                    end
                else
                    mode = 'CarFollowing';
                end
            end
            
            
        end
        
        function acc = carFollowing(obj,spacing,speed,speedDiff)
            acc = drivingBehavior.intelligentDriverModel(spacing,speed,speedDiff);
            aMin = (0-obj.Speed)/obj.Scenario.SampleTime;
            acc = max(acc,aMin);
        end
        
    end
end

