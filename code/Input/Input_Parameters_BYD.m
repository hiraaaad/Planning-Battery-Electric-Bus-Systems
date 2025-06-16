function Param = Input_Parameters_BYD(Battery)

%% Bus Operation
Param.Cycle       = load('DriveCycle_ECE_R15.mat');
Param.Demand      = load('Demand_Route15.mat');


%% Vehicle model
switch  Battery
    case 'LFP'
        Param.Vehicle.mbat = 105;    %Battery specific weight Wh/kg 
    case "NCA"
        Param.Vehicle.mbat = 243;
    case 'NMC'
        Param.Vehicle.mbat = 162;
    case 'LI'
        Param.Vehicle.mbat = 140;
end
    
Param.Vehicle.m_nonbat = 16046; %Bus weight excluding the battery [kg]
Param.Vehicle.A = 2.55*3.36; %Bus frontal area [m^2]
Param.Vehicle.Cd = 0.7; %Drag coeffiecient
Param.Vehicle.rho = 1.184; %Air density [kg/m^3]
Param.Vehicle.fr = 0.008; %Rolling resistance 
Param.Vehicle.eta_powertrain = 0.8593; %Powertrain efficiency
Param.Vehicle.P_aircon = 10; %Airconditioning power [kW]

end