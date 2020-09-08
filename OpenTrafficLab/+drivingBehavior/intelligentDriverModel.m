function [acc] = intelligentDriverModel(spacing,speed,speedDiff,varargin)
    % Parameters
        % NAME          REALISTIC BOUNDS      DEFAULT     UNITS
        % desiredSpeed       [0,11]              33         m/s
        % safeHeadway        [1,3]               1.6          s
        % accelMax           [0.5,2]             0.73     m/s^2
        % decelConf          [0.5,2]             1.67     m/s^2
        % beta                                    4
        % minJamSpacing      [0,5]                2           m
        % nonLinJamSpacing   [0,5]                3           m
    
    % Need to program input parse to pass new parameters
    desiredSpeed       = 10;
    safeHeadway        = 1.6;
    accelMax           = 0.73;
    decelConf          = 1.67;
    beta               = 4;
    minJamSpacing      = 2;
    nonLinJamSpacing   = 0;
    
    desiredSpacing = minJamSpacing + nonLinJamSpacing*sqrt(speed/desiredSpeed)...
                     +speed*safeHeadway-speed*speedDiff/2/sqrt(accelMax*decelConf);
    
    acc = accelMax*(1-(speed/desiredSpeed)^beta-(desiredSpacing/spacing)^2);
    
    if acc<-10 || acc>3 || isnan(acc)
        acc;
    end
end

