function opts = createTrainOpts()
% Copyright 2020 The MathWorks, Inc.
opts = rlTrainingOptions;

opts.MaxEpisodes                = 2000;
opts.MaxStepsPerEpisode         = 10000;
opts.StopTrainingCriteria       = "AverageReward";
opts.StopTrainingValue          = 550;
opts.ScoreAveragingWindowLength = 5;

opts.SaveAgentCriteria  = "EpisodeReward";
opts.SaveAgentValue     = 800;
opts.SaveAgentDirectory = "savedAgents";

opts.UseParallel = true;
opts.ParallelizationOptions.Mode = "async";
opts.ParallelizationOptions.DataToSendFromWorkers = "experiences";
opts.ParallelizationOptions.StepsUntilDataIsSent = 30;
opts.ParallelizationOptions.WorkerRandomSeeds = -1;

opts.Verbose = false;
opts.Plots =   "training-progress";
