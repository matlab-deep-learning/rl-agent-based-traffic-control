function IsHit = checkCollision(this)
% Copyright 2020 The MathWorks, Inc.
driver = [];
network = this.network;
IsHit = false;

% get pairwise distance between all of cars within the intersection
for i = 7:size(network, 2)
    if ~isempty(network(i).Vehicles)
        driver = [driver, network(i).Vehicles.MotionStrategy];
    end
end
% find whether there is cars distance below the threshould
if length(driver) > 1
    dist = pdist(driver.getPosition);
    if min(dist) < this.safeDistance
        IsHit = true;
    end
end
% visulization
% if IsHit
%    disp('OMG Car Collision!!') 
%    disp(driver.getPosition)  
% end

