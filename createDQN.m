function agent = createDQN(obsInfo, actInfo)
% Copyright 2020 The MathWorks, Inc.
% policy representation by Neural Network
layers = [
    imageInputLayer([obsInfo.Dimension(1) 1 1],"Name","observations","Normalization","none")
    fullyConnectedLayer(256,"Name","obs_fc1")
    reluLayer("Name","obs_relu1")
    fullyConnectedLayer(256,"Name","obs_fc2")
    reluLayer("Name","obs_relu2")
    fullyConnectedLayer(3,"Name","Q")
    ];
lgraph = layerGraph(layers);
% visualization
figure
plot(lgraph)

% critic options
criticOpts = rlRepresentationOptions('LearnRate',5e-03,'GradientThreshold',1);
criticOpts.Optimizer = 'sgdm';
criticOpts.UseDevice = 'cpu';
% create critic function
critic = rlQValueRepresentation(lgraph,obsInfo,actInfo,...
    'Observation',{'observations'},criticOpts);
% agent options
agentOpts = rlDQNAgentOptions;
agentOpts.EpsilonGreedyExploration.EpsilonDecay = 1e-4;
agentOpts.DiscountFactor = 0.99;
agentOpts.TargetUpdateFrequency = 1; 
% create agent
agent = rlDQNAgent(critic, agentOpts);
end