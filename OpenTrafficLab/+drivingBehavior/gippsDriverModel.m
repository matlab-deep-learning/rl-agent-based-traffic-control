function [acc,v_b,v_a] = gippsDriverModel(spacing,speed,speedDiff,varargin)

desiredSpeed = 10; %Desired speed
maxSpeed = 20; %max. speed
minSpeed = 0; % min. speed
minAcc = -3; %min. acceleration
maxAcc = 3; %max. acceleration
minAccEstimate = minAcc;
reactionTime = 0.8;
S0 = 2;

v_now = speed;
v_infront = speed+speedDiff;

v_a = v_now + 2.5*maxAcc*reactionTime*(1-v_now/desiredSpeed)*sqrt(0.025+v_now/desiredSpeed);
v_b = minAcc*reactionTime + sqrt((minAcc*reactionTime)^2-minAcc*(2*(spacing-S0)-v_now*reactionTime-v_infront^2/minAccEstimate));

v_b = max(v_b,minSpeed);
v_a = min(v_a,maxSpeed);
v_new = min([v_a,v_b]);

acc = (v_new-v_now)/reactionTime;

end

