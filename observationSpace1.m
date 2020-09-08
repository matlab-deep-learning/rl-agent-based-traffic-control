function state = observationSpace1(env, curPhase)
%  Copyright 2020 The MathWorks, Inc.
%  Observation space 1: (3*3 + 1 = 10)
%  Each road:
%       - head car distance to intersection
%       - head car velocity
%       - number of cars
%  Current signal phase

    % current signal phase
    state = [curPhase];    
    % observation of each of the road
    for i = 1:env.N    
        % get obs from each road
        if isempty(env.network(i).Vehicles)
           % if no car
           obs = [env.network(i).Length, 0, 0];   
        else
           % find the head car
           car = headCar(env.network(i));
           % head car distance
           dist = env.network(i).Length - car.getStationDistance;
           % head car velocity
           vel = car.getSpeed;
           % number of cars
           numCars = length(env.network(i).Vehicles);
           obs = [dist, vel, numCars];
        end
        % merge observations from each road
        state = [state, obs];        
    end
    
    % set up the lower and upper limit for distance, velocity and number of
    % cars
    carLow = [0, 0, 0];
    carHigh = [50, 15, 10];
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
