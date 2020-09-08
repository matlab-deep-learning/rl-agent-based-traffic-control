classdef DrivingScenarioEnv < rl.env.MATLABEnvironment
    % Copyright 2020 The MathWorks, Inc.
    %MYENVIRONMENT: Template for defining custom environment in MATLAB.    
    
    % parameters for simulation environment
    properties
        scenario
        network
        traffic
        cars
        state
        driver
        InjectionRate
        TurnRatio
        N = 3 % number of road
        phaseDuration = 50 % time duration for each of the phase
        T 
    end
    
    % simulation doesn't have yellow light
    % manually set up clearning phase here if needed
    properties
        clearingPhase = false
        clearingPhaseTime = 0
        TrafficSignalDesign
        ObservationSpaceDesign
    end
        
    % parameter for reward definition
    properties
       rewardForPass = 0
       vehicleEnterJunction % keep record of cars pass the intersection
       hitPenalty = 20
       penaltyForFreqSwitch = 1
       safeDistance = 2.25 % check collision 
       slowSpeedThreshold = 3.5 % check whether car is waiting
    end

    properties
       recordVid = false
       vid 
    end
 
    properties
        discrete_action = [0 1 2];
        dim =10;
    end
        
    properties(Access = protected)
        IsDone = false        
    end

    %% Necessary Methods
    methods              
        function this = DrivingScenarioEnv()
            % Initialize Observation settings
            ObservationInfo = rlNumericSpec([10, 1]); % # of state
            ObservationInfo.Name = 'real-time traffic information';
            ObservationInfo.Description = '';

            % Initialize action settings   
            ActionInfo = rlFiniteSetSpec([0 1 2]); % three phases
            ActionInfo.Name = 'traffic signal phases';

            % The following line implements built-in functions of the RL environment
            this = this@rl.env.MATLABEnvironment(ObservationInfo,ActionInfo);
        end
        
        function [state, Reward,IsDone,LoggedSignals] = step(this, Action)
            Action = getForce(this, Action);
            % update the action
            pre_phase = this.traffic.IsOpen;
            if this.TrafficSignalDesign == 1
                cur_phase = signalPhaseDesign1(Action);
            elseif this.TrafficSignalDesign == 2
                cur_phase = signalPhaseDesign2(Action);
            elseif this.TrafficSignalDesign == 3
                cur_phase = signalPhaseDesign3(Action);
            end
                        
            % Reward: penalty for signal phase switch
            changed = ~isequal(pre_phase, cur_phase);
            Reward = this.penaltyForFreqSwitch * (1 - changed);
            
            % (yellow light time)add clearing phase when signal phase switch 
            if changed && this.clearingPhase
                for i = 1:this.clearingPhaseTime
                    this.traffic.IsOpen = [0, 0, 0, 0, 0, 0];
                    advance(this.scenario);   
                    this.T = this.T + this.scenario.SampleTime;
                    notifyEnvUpdated(this);
                    % check terminal condition
                    IsHit = checkCollision(this);
                    Reward = Reward - IsHit * this.hitPenalty;
                    this.IsDone = IsHit || this.T+0.5 >= this.scenario.StopTime;
                    if this.IsDone
                        break
                    end
                end
            end
            
            % (green light time)simulate the signal phase based on the action by RL
            this.traffic.IsOpen = cur_phase;
            if ~this.IsDone
                for i = 1:this.phaseDuration 
                    % update traffic state
                    advance(this.scenario);   
                    this.T = this.T + this.scenario.SampleTime;
                    % update visulization
                    notifyEnvUpdated(this);
                    % check terminal condition
                    IsHit = checkCollision(this);
                    Reward = Reward - IsHit * this.hitPenalty;
                    this.IsDone = IsHit || this.T+0.5 >= this.scenario.StopTime;
                    if this.IsDone
                        break
                    end
                    % obtain reward
                    Reward = Reward + obtainReward(this, cur_phase);
                end
            end
            if this.ObservationSpaceDesign == 1
                state = observationSpace1(this, Action);
            else
                state = observationSpace2(this, Action);
            end
            this.state = state;
            IsDone = this.IsDone;
            LoggedSignals = [];
        end
        
   
        function InitialState = reset(this)
            % flag for record simulation 
            this.recordVid = false;
            % Initialize scenario
            this.scenario = createTJunctionScenario();
            this.scenario.StopTime = 100;
            this.scenario.SampleTime = 0.05;
            this.T = 0;
            % initialize network
            this.network = createTJunctionNetwork(this.scenario);
            this.traffic = trafficControl.TrafficController(this.network(7:12));
            % car parameters
            this.InjectionRate = [250, 250, 250]; % veh/hour
            this.TurnRatio = [50, 50];
            this.cars = createVehiclesForTJunction(this.scenario, this.network, this.InjectionRate, this.TurnRatio);
            this.vehicleEnterJunction = [];
            % obtain state from traffic and network
            if this.ObservationSpaceDesign == 1
                InitialState = observationSpace1(this, 0);
            else
                InitialState = observationSpace2(this, 0);
            end
            % visulization
            notifyEnvUpdated(this);            
        end
    end

    methods               
        function force = getForce(this,action)
            if ~ismember(action,this.ActionInfo.Elements)
                error('Action must be integer from 1 to numAction');
            end
            force = action;           
        end
        % update the action info based on max force
        function updateActionInfo(this)        
              this.ActionInfo.Elements = this.discrete_action;
        end        
    end
    
    methods (Access = protected)
        function envUpdatedCallback(this)
            if this.T == 0
                close all;
                plot(this.scenario)
                set(gcf,'Visible','On');
                if this.recordVid
                    this.vid = VideoWriter('baseRLlearningProcess33');
                    this.vid.FrameRate=20;
                    open(this.vid)
                end
            end
            if this.recordVid
                frame = getframe(gcf);
                writeVideo(this.vid,frame);
            end 
            this.traffic.plotOpenPaths()
            drawnow
        end
    end
end