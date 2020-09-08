% Copyright 2020 The MathWorks, Inc.
% Author: xiangxuezhao@gmail.com
% Last modified: 08-27-2020
% add traffic simulator: OpenTrafficLab to path
folderName = fullfile(cd, 'OpenTrafficLab');
addpath(folderName)
%% Step 1: create RL environment from Matlab template
env = DrivingScenarioEnv;
%% specifiy traffic problem formulation
% specifiy action space
env.TrafficSignalDesign = 1; % or 2, 3
% the dimensio of signal phase is 3 for design 1 and 2, 4 for design 3, as
% shown in the figure
SignalPhaseDim = 3;
env.phaseDuration = 50;
env.clearingPhase = true;
env.clearingPhaseTime = 5;
% specifiy observation space
env.ObservationSpaceDesign = 1; % or 2
% specify reward parameter
% The car's speed below the threshold will be treated as waiting at the
% intersection
slowSpeedThreshold = 3.5;
% Add penalty for frequent/unnecessary signal phase switch
penaltyForFreqSwitch = 1;
% parameter for car collision
env.hitPenalty = 20;
env.safeDistance = 2.25;
% reward for car pass the intersection
env.rewardForPass = 10;

% obtain observation and action info
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
%% Step 3: creat DQN agent
% policy representation by Neural Network
layers = [
    imageInputLayer([obsInfo.Dimension(1) 1 1],"Name","observations","Normalization","none")
    fullyConnectedLayer(256,"Name","obs_fc1")
    reluLayer("Name","obs_relu1")
    fullyConnectedLayer(256,"Name","obs_fc2")
    reluLayer("Name","obs_relu2")
    fullyConnectedLayer(SignalPhaseDim,"Name","Q")
    ];
lgraph = layerGraph(layers);

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
%% Step 4: train agent
% specify training option
trainOpts = rlTrainingOptions;

trainOpts.MaxEpisodes                = 2000;
trainOpts.MaxStepsPerEpisode         = 1000;
trainOpts.StopTrainingCriteria       = "AverageReward";
trainOpts.StopTrainingValue          = 550;
trainOpts.ScoreAveragingWindowLength = 5;

trainOpts.SaveAgentCriteria  = "EpisodeReward";
trainOpts.SaveAgentValue     = 800;
trainOpts.SaveAgentDirectory = "savedAgents";

trainOpts.UseParallel = false;
trainOpts.ParallelizationOptions.Mode = "async";
trainOpts.ParallelizationOptions.DataToSendFromWorkers = "experiences";
trainOpts.ParallelizationOptions.StepsUntilDataIsSent = 30;
trainOpts.ParallelizationOptions.WorkerRandomSeeds = -1;

trainOpts.Verbose = false;
trainOpts.Plots = "training-progress";

% train agent or load existing trained agent
doTraining = false;

if doTraining    
    % Train the agent.
    trainingInfo = train(agent,env,trainOpts);
else
    % Load the pretrained agent for the example.
    folderName = cd; % change current folder
    folderName = fullfile(folderName, 'savedAgents');
    filename = strcat('TjunctionDQNAgentDesign', num2str(env.TrafficSignalDesign), '.mat');
    file = fullfile(folderName, filename);
    load(file);
end
%% Step 5: simulate agent
simOpts = rlSimulationOptions('MaxSteps',1000);
experience = sim(env,agent,simOpts);
totalReward = sum(experience.Reward);
