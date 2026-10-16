function rocketlab_sixdof_forces_sfun(block)
% Applied loads only. Native Aerospace Blockset integrates the rigid-body EOM.
block.NumDialogPrms=1; block.NumInputPorts=1; block.NumOutputPorts=5;
block.SetPreCompInpPortInfoToDynamic; block.SetPreCompOutPortInfoToDynamic;
block.InputPort(1).Dimensions=13; block.InputPort(1).DirectFeedthrough=true;
dims={3,3,1,[3,3],[3,3]};
for k=1:5, block.OutputPort(k).Dimensions=dims{k}; end
block.SampleTimes=[0,0]; block.SimStateCompliance='DefaultSimState';
block.RegBlockMethod('Outputs',@outputs);
end
function outputs(block)
a=rocketlab.sixdof_forces(block.CurrentTime,block.InputPort(1).Data,block.DialogPrm(1).Data);
block.OutputPort(1).Data=a.force_B; block.OutputPort(2).Data=a.momentCG_B;
block.OutputPort(3).Data=a.mass_kg; block.OutputPort(4).Data=a.Idot_B; block.OutputPort(5).Data=a.I_B;
end
