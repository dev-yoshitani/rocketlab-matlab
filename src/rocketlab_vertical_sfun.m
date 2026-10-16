function rocketlab_vertical_sfun(block)
% Level-2 MATLAB S-function using the same equations as the reference ODE.
block.NumDialogPrms=1; block.NumInputPorts=0; block.NumOutputPorts=1;
block.SetPreCompOutPortInfoToDynamic;
block.OutputPort(1).Dimensions=3; block.OutputPort(1).DatatypeID=0; block.OutputPort(1).Complexity='Real';
block.NumContStates=3; block.SampleTimes=[0,0];
block.SimStateCompliance='DefaultSimState';
block.RegBlockMethod('CheckParameters',@check);
block.RegBlockMethod('InitializeConditions',@initialize);
block.RegBlockMethod('Outputs',@outputs);
block.RegBlockMethod('Derivatives',@derivatives);
end
function check(block)
rocketlab.validate_flight(block.DialogPrm(1).Data);
end
function initialize(block)
p=block.DialogPrm(1).Data; block.ContStates.Data=p.initial(:);
end
function outputs(block)
block.OutputPort(1).Data=block.ContStates.Data;
end
function derivatives(block)
block.Derivatives.Data=rocketlab.vertical_rhs(block.CurrentTime,block.ContStates.Data,block.DialogPrm(1).Data);
end
