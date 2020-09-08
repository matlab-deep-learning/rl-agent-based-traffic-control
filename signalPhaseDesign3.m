function phase = signalPhaseDesign3(action)
% Copyright 2020 The MathWorks, Inc.
% signal phase design 3: each phase has three lanes
if action == 0
    phase = [1, 0, 1, 0, 1, 0];
end
if action == 1
    phase = [1, 0, 0, 1, 0, 0];
end
if action == 2
    phase = [0, 1, 0, 0, 1, 0];
end
if action == 3
    phase = [0, 0, 1, 0, 0, 1];
end
end