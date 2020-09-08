function [net] = createTJunctionNetwork(scenario)
% Copyright 2020 The MathWorks, Inc.
%Create the Network of Node Objects
% First Road:
for i =1:3
    net(i) = Node(scenario,scenario.RoadSegments(i),-1);
end

for i =1:3
    net(3+i) = Node(scenario,scenario.RoadSegments(i),1);
end

for i = 1:6
    rs = scenario.RoadSegments(i+3);
    net(i+6) = Node(scenario,rs,1);
end

net(1).ConnectsTo = net(7);
net(1).ConnectsTo = net(8);
net(1).SharesRoadWith = net(4);

net(2).ConnectsTo = net(11);
net(2).ConnectsTo = net(12);
net(2).SharesRoadWith = net(5);

net(3).ConnectsTo = net(9);
net(3).ConnectsTo = net(10);
net(3).SharesRoadWith = net(6);

net(10).ConnectsTo = net(4);
net(11).ConnectsTo = net(4);
net(10).SharesRoadWith = net([7:9,11,12]);
net(11).SharesRoadWith = net([7:11,12]);

net(8).ConnectsTo = net(5);
net(9).ConnectsTo = net(5);
net(8).SharesRoadWith = net([7,9:12]);
net(9).SharesRoadWith = net([7,8,10:12]);


net(7).ConnectsTo = net(6);
net(12).ConnectsTo = net(6);
net(7).SharesRoadWith = net([8:12]);
net(12).SharesRoadWith = net([7:11]);


end

