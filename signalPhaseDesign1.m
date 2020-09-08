function phase = signalPhaseDesign1(action)
% Copyright 2020 The MathWorks, Inc.
% signal phase design 1: each phase has two lanes
if action == 0
    phase = [0, 0, 1, 1, 0, 0];
end
if action == 1
    phase = [1, 1, 0, 0, 0, 0];
end
if action == 2
    phase = [0, 0, 0, 0, 1, 1];
end
end