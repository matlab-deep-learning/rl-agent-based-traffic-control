% Copyright 2020 The MathWorks, Inc.
% load simulated result
folderName = cd;
fileName = 'rewardforEachTest.mat';
file = fullfile(folderName, fileName);
load(file)
% calculate cumulative reward for each traffic control
cumReward = zeros(4, 40);
for i = 1: 4
    for j = 1:40
        cumReward(i, j) = sum(data(i, 1:j));
    end
end
% visualization
figure
hold on
plot(1:40, cumReward(1:3, :), "LineWidth", 1.5)
plot(1:40, cumReward(4, :), 'k-', "LineWidth", 1.5)
legend('RL traffic signal design 1', 'RL traffic signal design 2','RL traffic signal design 3','Fixed time signal control')
xlabel('Time')
ylabel('Cumulative reward')
title('Traffic Performance Comparison')