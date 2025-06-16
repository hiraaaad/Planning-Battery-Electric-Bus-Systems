function out = EOL(Ebat, dt, Ta,SOCstart,Driving,Pch,Nch,Charging,BusNo,e,c_elec,Pavg,Battery)



switch Battery

    case 'LFP'
        Unom = 3.2;
        Qnom = 3;
        Ri_init = 18*10^-3;
    case 'NMC'
        Unom = 3.7;
        Qnom = 5.36;
        Ri_init = 15*10^-3;
    case 'NCA'
        Unom = 3.6;
        Qnom = 3.35;
        Ri_init = 36*10^-3;
    case 'LI'
        Unom = 3.6;
        Qnom = 2.15;
        Ri_init = 83.7*10^-3;
end

lifeMdl = LifeMdl_LoadParameters(Battery);
xx = zeros(lifeMdl.n_states,1);
n_outputs = lifeMdl.n_outputs;
yy = ones(1,n_outputs);

driving = Driving(BusNo,:);
clear Driving

emission = 0;
Ccons = 0;


nyear = 30;
taging_eval = 3600*24; %Time interval at which aging status is updated 
Qloss_EOL = 0.2;      % EOL criterium 
tmax = 3600*24*365*nyear; %Maximum simulation duration [Assumption]
SOCmin = 0.15;


ncells = Ebat*1000/(Unom*Qnom); %number of cells in the pack
maxsteps = floor(tmax/dt); % Maximum number of steps in simulation
SOC = zeros(1, maxsteps); % SOC
Tcell = zeros(1, maxsteps); % Cell temperature
Th = zeros(1, maxsteps); % Housing temperature
Pheat = zeros(1, maxsteps); % Thermal system energy consumption
Pcool = zeros(1, maxsteps); % Thermal system energy consumption
Ploss = zeros(1, maxsteps); % Ohmic losses energy consumption
iaging = floor(taging_eval/dt); % Index range over which aging is evaluated
% Set starting conditions of all states
Tcell(1) = 25; % Starting temperature cells
Th(1) = 25; % Starting temperature housing
SOC(1) = SOCstart; % Starting SOC


Theat = 23;
Tcool = 40;
Ta = Ta(:,2);

for i = 1:(maxsteps-1)
    
    charging = Charging(BusNo,:);
    
    Uocv = Unom;

    ind = floor(i*dt/3600)+1;
    iT = mod(ind-1,length(Ta))+1;
    step_counter = mod(i-1,iaging)+1;
    
    [Pheat(i),Pcool(i),SOC(i+1),Ploss(i)] = New_Emodel(charging, driving,SOC(i),dt,Pavg,Pch,Tcell(i),Theat,Tcool,step_counter,Ebat,ncells,Uocv,Ri_init,Unom,Battery);
    [Tcell(i+1), Th(i+1)] = thermalmodel(Tcell(i), Th(i), Ploss(i), Pheat(i), Pcool(i),Ta(iT),dt,ncells,Battery);

    
            if mod(i, iaging) == 0
                
                                    
                                    day = floor(i/iaging);
                                    tsec = ((day-1)*iaging:day*iaging-1)*dt;
                                    Taging =  Tcell((day-1)*iaging+1:day*iaging);
                                    SOCaging = SOC((day-1)*iaging+1:day*iaging)';
                                    Day = mod(day-1,365)+1;
                                    Celec = c_elec((Day-1)*iaging+1:Day*iaging);
                                    
                                    subcycle = struct();
                                    subcycle.tsec  = tsec';
                                    subcycle.t = subcycle.tsec ./ (24*3600);
                                    subcycle.soc = SOCaging;
                                    subcycle.TdegC = Taging';
                                    clearvars tsec Taging 
                  
                                    subcycle = LifeMdl_StressStatistics(subcycle);
                                    xx =  LifeMdl_UpdateStates(subcycle,xx,Battery);
                                    yy = [yy ; LifeMdl_UpdateOutput(xx,Battery)];
                                    Qend = yy(end,1);
                                     
                                    
                                    [emission,Ccons,Charging,ChInd] = NightlyCharging(Charging,Pch,Ebat,dt,emission,Ccons,Celec,SOCaging,SOCstart,BusNo,Nch,e);
                                    
                                    if ChInd > 230              %% This line means after 5:45 A.M no charger is availble, Since bus fleet starts at this time
                                        emission = +Inf;
                                        Ccons = +Inf;
                                        break;
                                    end
                                    

                                    
                                    

                                   
                                    %Check if EOL was reached


                                      if    (Qend < 1 - Qloss_EOL)  || (min(SOCaging) < SOCmin)
                                          break;
                                      end



                
            end
            
end
            
            
iend = floor(day*taging_eval/dt);
Tcell = Tcell(1:iend);
SOC = SOC(1:iend);
qrel = yy(:,1);

%Compute results
teol = day*taging_eval; %battery lifetime in seconds
teol_a = teol/3600/24/365; %battery lifetime in years
theater = sum(Pheat > 0)*dt/3600/teol_a/365;
tcooler = sum(Pcool > 0)*dt/3600/teol_a/365;

out.SOC = SOC(1:iend);
out.teol_a = teol_a;
out.Tcell = Tcell(1:iend);
out.qrel = qrel;
out.Ccons = Ccons/teol_a;
out.emission = emission/teol_a;

% figure(1)
% xaxis = (1:length(qrel))/365;
% plot(xaxis',qrel,'LineWidth', 2);
% xlabel('Year');
% ylabel('Q Relative');
% 
% figure(2);
% plot(Tcell(1:iend));
% xlabel('steps');
% ylabel('Temperature');


% figure(3);
% plot(Pheat(1:iend));
% xlabel('steps');
% ylabel('Pheat');
% 
% figure(4);
% plot(Pcool(1:iend));
% xlabel('steps');
% ylabel('Pcool');
 
Eheater = 15*theater;
Ecooler = 13*tcooler;
disp(['End Of Life is : ' num2str(teol_a) ' Years']);
disp(['The Heater is ON for  : ' num2str(theater) ' Hours per day']);
disp(['The Heater uses : ' num2str(Eheater) 'Kwh per day for heating the battery']);
disp(['The Cooler uses : ' num2str(Ecooler) 'Kwh per day for cooling the battery']);


end





