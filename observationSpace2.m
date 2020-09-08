function state = observationSpace2(env, curPhase)
%  Copyright 2020 The MathWorks, Inc.
%  Observation space 2: (3*4 + 1 = 13)
%  Each road:
%       - head car distance to intersection
%       - head car velocity
%       - head car intention: right or left
%       - number of cars
%  Current signal phase

    % current signal phase
    state = [curPhase];    
    % observation of each of the road
    for i = 1:env.N    
        % get obs from each road
        if isempty(env.network(i).Vehicles)
           % if no car
           obs = [env.network(i).Length, 0, 0, 0];   
        else
           % find the head car
           car = headCar(env.network(i));
           % head car distance
           dist = env.network(i).Length - car.getStationDistance;
           % head car velocity
           vel = car.getSpeed;
           % head car intention: right or left
            NextNode = car.NextNode(1);
            intent = -1; % default is turn left
            % update if it turns right
            if i == 1
                if NextNode == env.network(7)
                    intent = 1;
                end
            elseif i == 2
                if NextNode == env.network(11)
                    intent = 1;
                end
            elseif i == 3
                if NextNode == env.network(9)
                    intent = 1;
                end
            end
           % number of cars
           numCars = length(env.network(i).Vehicles);
           obs = [dist, vel, numCars, intent];
        end
        % merge observations from each road
        state = [state, obs];        
    end
    
    % set up the lower and upper limit for distance, velocity and number of
    % cars
    carLow = [0, 0, 0, -1];
    carHigh = [50, 15, 10, 1];
    lowLimit = [0 carLow carLow carLow];
    highLimit = [2 carHigh carHigh carHigh];    
    
    % normalize the observation
    state = (state - lowLimit) ./ (highLimit - lowLimit);
end

function headcar = headCar(net)
% find the head car distance to the intersection
cars = [net.Vehicles.MotionStrategy];
% find the head car index
index = headCarIndex(net, cars);
% head car
headcar = cars(index);
end

function Index = headCarIndex(net, cars)
Index = 1;
if length(net.Vehicles) > 1
    travelDistance = cars.getStationDistance;
    [~, Index] = max(travelDistance);
end
end