function q=euler_quat(e)
% Roll, pitch, yaw [rad]; body-to-NED Rz(yaw)*Ry(pitch)*Rx(roll).
e=e(:)/2; c=cos(e); s=sin(e);
q=[c(1)*c(2)*c(3)+s(1)*s(2)*s(3);s(1)*c(2)*c(3)-c(1)*s(2)*s(3); ...
 c(1)*s(2)*c(3)+s(1)*c(2)*s(3);c(1)*c(2)*s(3)-s(1)*s(2)*c(3)];
end
