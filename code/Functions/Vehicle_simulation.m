function [Pavg, Prms, Pthr] = Vehicle_simulation(Ebat, Vehicle, DRIVING_CYCLE, plottrue)

mbattotal = Ebat/Vehicle.mbat*1000; %Battery weight [kg]
m_vehicle = Vehicle.m_nonbat+mbattotal; %Total vehicle weight [kg]

t = DRIVING_CYCLE(:,1);
v = DRIVING_CYCLE(:,2);
a = [diff(v)./diff(t); 0];

Proll = zeros(1,length(v));
Pdrag = zeros(1,length(v));
Pacc = zeros(1,length(v));
Pac = zeros(1,length(v));

Eroll = zeros(1,length(v));
Edrag = zeros(1,length(v));
Eacc = zeros(1,length(v));
Eac = zeros(1,length(v));
Pregen = zeros(1,length(v));
Pdriving = zeros(1,length(v));

for i = 1:length(v)
    
    if a(i) >= 0 %Acceleration
        Proll(i) = 1/1000*Vehicle.fr*9.81*m_vehicle*v(i)/Vehicle.eta_powertrain; %Rolling resistance power [kW]
        Pdrag(i) = 1/1000*0.5*Vehicle.Cd*Vehicle.A*Vehicle.rho*v(i)^3/Vehicle.eta_powertrain; %Drag resistance power [kW]
        Pacc(i)  = 1/1000*v(i)*m_vehicle*a(i)/Vehicle.eta_powertrain; %Acceleration power [kW]
    else %Decelaration
        Proll(i) = 0;
        Pdrag(i) = 0;

        Proll_oncar = 1/1000*Vehicle.fr*9.81*m_vehicle*v(i);
        Pdrag_oncar = 1/1000*0.5*Vehicle.Cd*Vehicle.A*Vehicle.rho*v(i)^3;
        Pacc(i)  = (1/1002*v(i)*m_vehicle*a(i)+Pdrag_oncar+Proll_oncar)*Vehicle.eta_powertrain; %Regeneration power [kW]
    end
    
    Pac(i) = Vehicle.P_aircon; %
    
    Eroll(i) = trapz(Proll(1:i))/3600; %Cummulative Energy for rolling resistance [kWh]
    Edrag(i) = trapz(Pdrag(1:i))/3600; %Cummulative Energy for drag [kWh] 
    Eacc(i)  = trapz(Pacc(1:i))/3600; %Cummulative Energy for acceleration [kWh]
    Eac(i)   = trapz(Pac(1:i))/3600; %Cummulative Energy for AC [kWh]   
end

Ptotal = Proll + Pdrag + Pacc + Pac; %Total driving power consumption [kW]
Pregen(Ptotal<0) = Ptotal(Ptotal<0);
Pdriving(Ptotal>=0) = Ptotal(Ptotal>=0);

%% Results

Pavg = mean(Ptotal);          %Average power consumption in kW
Prms = sqrt(mean(Ptotal.^2)); %Root mean squared in kW
Pthr = mean(Pdriving)+abs(mean(Pregen));%Average power throughput in kW



%% plot
if plottrue
    figure
    subplot(3,1,1)
    plot(t,v)
    xlabel('Time [s]')
    ylabel('Vehicle speed [m/s]')
    title('Driving cycle')

    subplot(4,1,2)
    plot(t,a)
    xlabel('Time [s]')
    ylabel('Vehicle acceleration [m/s^2]')
    title('Driving cycle')

    subplot(3,1,2)
    hold on
    plot(t,Proll)
    plot(t,Pdrag)
    plot(t,Pacc)
    plot(t,Pac)
    plot(t,Ptotal)
    hold off
    xlabel('Time [s]')
    ylabel('Power [W]')
    title('Powerflow over time [kW]')
    legend('Proll','Pdrag','Pacc','Pac','Ptotal')

    subplot(3,1,3)
    area(t/60,[Eac; Edrag; Eroll; Eacc]')
    xlabel('\it t_{drivingcycle} \rm in minutes')
    xlim([0 22])
    ylabel('kWh')
    legend('\it E_{aux}','\it E_{L}','\it E_{RR}','\it E_{B}','Location','NorthWest')
    title('Cummulative energy consumption')

    figure
    plot(DRIVING_CYCLE(:,1),DRIVING_CYCLE(:,2))
    xlabel('Time [s]')
    ylabel('Vehicle speed [m/s]')
end

end