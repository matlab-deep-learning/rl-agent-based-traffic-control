function reward = obtainReward(this, phase)
% Copyright 2020 The MathWorks, Inc.
reward = 0;
driver = [];
for i = 1:this.N
    % get all of the drivers from each of the road
    if ~isempty(this.network(i).Vehicles)
        driver = [this.network(i).Vehicles.MotionStrategy];
    end
    if isempty(driver)
        continue
    end
    % component 1: judge by the distance to intersection
    % distance_to_intersection = network(i).Length - driver.getStationDistance;
    % reward = reward - sum(distance_to_intersection < this.thresholdDistance);
    
    % component 2: waiting time
    % speed of the car is lower that specified speed limit
    % is the one get delay
    speed = driver.getSpeed;
    reward = reward - sum(speed < this.slowSpeedThreshold) * this.scenario.SampleTime;

    % strategy 3: maximize the cars speed
    speed = driver.getSpeed;
    reward = reward + sum(speed) * 0.01;
     
end
% component 4: get reward when car are entering the intersection
for i = 7:12
    if isempty(this.network(i).Vehicles)
        continue
    end
    for j = 1:length(this.network(i).Vehicles)
        if ~ismember(this.network(i).Vehicles(j), this.vehicleEnterJunction)
            reward = reward + this.rewardForPass;
            this.vehicleEnterJunction = [this.vehicleEnterJunction this.network(i).Vehicles(j)];
        end    
    end
end