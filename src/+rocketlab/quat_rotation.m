function R=quat_rotation(q)
% Scalar first Hamilton quaternion: active body-to-NED rotation.
q=q(:); assert(numel(q)==4 && all(isfinite(q)) && norm(q)>1e-12,'rocketlab:Quaternion','Invalid quaternion.');
q=q/norm(q); w=q(1); x=q(2); y=q(3); z=q(4);
R=[1-2*(y*y+z*z),2*(x*y-w*z),2*(x*z+w*y); ...
   2*(x*y+w*z),1-2*(x*x+z*z),2*(y*z-w*x); ...
   2*(x*z-w*y),2*(y*z+w*x),1-2*(x*x+y*y)];
end
