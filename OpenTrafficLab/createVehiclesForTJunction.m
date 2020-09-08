function cars = createVehiclesForTJunction(s,net,InjectionRate,TurnRatio)
% Copyright 2020 The MathWorks, Inc.
%  rng(33);
numEntryRoads = 3;
numTurns = 2;

[s,net,InjectionRate,TurnRatio] = checkInputs(s,net,InjectionRate,TurnRatio); 

cars = driving.scenario.Vehicle.empty;

for i=1:3
    entryTimes = generatePoissonEntryTimes(s.SimulationTime,s.StopTime,InjectionRate(i));
    
    for entryTime =entryTimes
        j  = discretize(rand, [0 cumsum(TurnRatio)]);
        path = [net(i), net(i).ConnectsTo(j), net(i).ConnectsTo(j).ConnectsTo(1)];
        pos = path(1).getRoadCenterFromStation(0);
        [station,direction,offset]=path(1).getStationDistance(pos(1:2));
        car = vehicle(s,'Position',pos,'EntryTime',entryTime,'Velocity',[10,0,0]);
        car.ForwardVector = [direction,0];
%         ms = DrivingStrategy(car,'NextNode',path);
        ms = DrivingStrategyRL(car,'NextNode',path,'DesiredSpeed',10);
        cars(end+1)=car;
    end
end

end

function entryTimes = generatePoissonEntryTimes(tMin,tMax,mu)

t=tMin;
minHeadway = 1;
entryTimes = [];
while t<tMax
    headway = (-log(rand)*3600/mu);
    headway = max(minHeadway,headway);
    t = t+headway;
    if t<tMax
        entryTimes(end+1)=t;
    end
end

end

function [s,net,InjectionRate,TurnRatio] = checkInputs(s,net,InjectionRate,TurnRatio) 
    if isinf(s.StopTime)
        error('Simulation Stop Time cannot be infinite')
    end
    
    if length(InjectionRate)==1
        InjectionRate = [InjectionRate,InjectionRate,InjectionRate];
    elseif length(InjectionRate)~=3
        error('Incorrect number of Injection Times')
    end
    
    TurnRatio = TurnRatio./sum(TurnRatio);
end

