function [center, left, kappa, dkappa, dx_y] = roadDistanceToCenterAndLeft(xr, hcd, hl, hip, course, k0, k1, vpp, bpp)

%   Copyright 2017 The MathWorks, Inc.

% find index/indices into table 
idx = discretize(xr, hcd);
% If nan values come at end of the indices, it replace the maximum value at end of
% the indices.
if isnan(idx(end))
    idx(isnan(idx)) = idx(find(isnan(idx)==0, 1, 'last' ));
end
% fetch clothoid segment at index and initial position.
dkappa = (k1(idx)-k0(idx))./hl(idx);
kappa0 = k0(idx);
theta = course(idx);
p0 = hip(idx);

% get length and curvature into clothoid segment
l = xr-hcd(idx);
kappa = kappa0 + l.*dkappa;

% get corresponding points in complex plane and derivative w.r.t. road length
x_y = matlabshared.tracking.internal.scenario.fresnelg2(l, dkappa, kappa0, theta);
dx_y = matlabshared.tracking.internal.scenario.dfresnelg2(l, dkappa, kappa0, theta);

% get elevation and derivative w.r.t road length
zp = ppval(vpp, xr);

% get banking angles
bank = ppval(bpp, xr);

% assemble the 3D positions of the road centers.  This corresponds to (xr, 0) in road coordinates.
center = [real(x_y+p0) imag(x_y+p0) zp];
            
% assemble unit tangent to xy in xy plane (neglecting derivative of elevation)
forward = [real(dx_y) imag(dx_y) zeros(length(x_y),1)];
forward = forward ./ sqrt(sum(forward.^2,2));
up = repmat([0 0 1],length(x_y),1);
left = cross(up,forward,2);
left = left ./ sqrt(sum(left.^2,2));

% apply bank angles
left = [left(:,1).*cos(bank) left(:,2).*cos(bank) sin(bank)];