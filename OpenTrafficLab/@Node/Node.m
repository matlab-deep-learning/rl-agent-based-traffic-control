classdef Node < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        ConnectsTo = Node.empty % Node it spills into
        ConnectsFrom = Node.empty % Node that feeds it
        SharesRoadWith = Node.empty % Road or Junction it is a part of
        InjectionRate
        TurnRatio
        
    end
    
    properties (SetAccess = protected)
        Scenario
        RoadSegment
        Lane
        Length
        Mapping
        Vehicles = driving.scenario.Vehicle.empty
    end
    
    properties (SetAccess  = {?trafficControl.TrafficController})
        TrafficController
    end
    
    %% Constructor and Setup methods
    methods
        function obj = Node(scenario,rs,lane)
            obj.Scenario = scenario;
            obj.RoadSegment = rs;
            obj.Lane = lane;
            obj.setMapping;
        end
        
        function setMapping(obj)
            rs = obj.RoadSegment;
            xr = 0:0.1:rs.hcd(end);
            map = nan(length(xr),6);
            if obj.Lane == -1
                xr = fliplr(xr);
            end
            for idx = 1:length(xr)
                
                [center, left, kappa, dkappa, dx_y] = obj.roadDistanceToCenterAndLeft(xr(idx), rs.hcd, rs.hl, rs.hip, rs.course, rs.k0, rs.k1, rs.vpp, rs.bpp);
                left = left*(-obj.Lane);
                dx_y = dx_y*(obj.Lane);
                center = center + left*3.65/2;
                
                if obj.Lane == -1
                    map(idx,:) = [xr(end+1-idx),center,real(dx_y),imag(dx_y)];
                else
                    map(idx,:) = [xr(idx),center,real(dx_y),imag(dx_y)];
                end
            end
            %map = sortrows(map);
            obj.Mapping = map;
            obj.Length = max(xr);
        end
        
        function set.ConnectsTo(this,those)
            for that=those
                if ~any(this.ConnectsTo==that)
                    this.ConnectsTo(end+1) = that;
                end
                if ~any(that.ConnectsFrom==this)
                    that.ConnectsFrom(end+1) = this;
                end
            end
        end
        
        function set.SharesRoadWith(this,those)
            for that = those
                if ~any(this.SharesRoadWith==that)
                    this.SharesRoadWith(end+1) = that;
                end
                if ~any(that.SharesRoadWith==this)
                    that.SharesRoadWith(end+1) = this;
                end
            end
        end
        
    end
    %% Public facing methods
    methods
       
        function [dist,forwardVector,offsetVector] = getStationDistance(obj,pos)
            % Given a position, this function returns the station distance
            % along the road,  along with the direction of the road, and
            % the distance vector from the point to the road.
            distanceToPoints = sqrt(sum((obj.Mapping(:,2:3)-pos).^2,2));
            [~,idx] = min(distanceToPoints);
            sampleToPosVector = pos-obj.Mapping(idx,2:3);
            forwardVector = obj.Mapping(idx,5:6);
            dist = obj.Mapping(idx,1)+dot(forwardVector,sampleToPosVector);
            sideVector = cross([forwardVector,0],[0,0,1]);
            offsetVector = -dot(sideVector(1:2),sampleToPosVector)*sideVector(1:2);
        end
            
        function [center,indexes] = getRoadCenterFromStation(obj,stations)
            center = zeros(length(stations),3);
            indexes = zeros(size(stations));
            for idx = 1:length(stations)
                s = stations(idx);
                dist = (obj.Mapping(:,1)-s).^2;
                [~,ii] = min(dist);
                center(idx,:) = obj.Mapping(ii,2:4);
                indexes(idx)= ii;
            end
        end
        
        function length = getRoadSegmentLength(obj)
            length = obj.Length;
        end
        
        function added = addVehicle(obj,vehicle)
            if ~any(obj.Vehicles==vehicle)
                obj.Vehicles(end+1)=vehicle;
                added = true;
            else
                added = true;
                %error('Vehicle  is already in the node');
            end
            
        end
        
        function removed = removeVehicle(obj,vehicle)
            if any(obj.Vehicles==vehicle)
                obj.Vehicles(obj.Vehicles==vehicle)=[];
                removed = true;
            else
                error('Vehicle is not in the node')
            end
            
        end
        
        function actors = getActiveVehicles(obj)
            actors = obj.Vehicles;
        end
        
        function [s,veh] = getTrailingVehicleStation(obj,time)
            if nargin<2 %If no time is given assume current sim time
                time = obj.Scenario.SimulationTime;
            end
            drivers = [obj.Vehicles.MotionStrategy];
            if isempty(drivers)
                s = obj.getRoadSegmentLength();
                veh = driving.scenario.Vehicle.empty;
                return
            end
            [s,idx] = min(getStationDistance(drivers,time));
            veh = drivers(idx).EgoActor;
        end
        
        function s = getLeadingVehicleStation(obj,time)
            if nargin<2 %If no time is given assusme current sim time
                time = obj.Scenario.SimulationTime;
            end
            drivers = [obj.Vehicles.MotionStrategy];
            if isempty(drivers)
                s = 0;
                return
            end
            s = max(getStationDistance(drivers,time));
        end
        
        function plotPath(obj,ax)
            if nargin<2
                ax=gca;
            end
            for node=obj
            plot3(ax,node.Mapping(:,2),node.Mapping(:,3),node.Mapping(:,4)+10)
            end
        end
        
        function state = getNodeState(obj)
            state = obj.TrafficController.getNodeState(obj);
        end
        
        function clearVehicles(obj)
            for idx = 1:length(obj)
                obj(idx).Vehicles = [];
            end
        end
    end
  %% Helper methods
    methods(Static)
        [c, l, k, d, dx_y] = roadDistanceToCenterAndLeft(xr, hcd, hl, hip, course, k0, k1, vpp, bpp)
    end
end

