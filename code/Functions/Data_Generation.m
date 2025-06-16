function Data_Generation(Region,Battery, Ebat)


addpath(genpath(cd))

%% Loading Inputs such as physical attributes of the vehicle, Ambient Temperature, Electricity price, and Emission

Param = Input_Parameters_BYD(Battery);        % Physical attributes of the bus
Temp = load("Temperature");          % Load ambient temperature and solar irradiation
c_elec = load("Electricity_Price");  % Electriciy price
Emission = load("Emission");         % Emissions



FolderName = "Data_"+Battery+"_"+Region;   % Creates a folder to strore the results in
FileName = "Data_" +Battery + "_" + num2str(Ebat) + "_" + Region;   % Saves the Data by this name



%% Extracting Temperature , Electricity price, and Emission based on the city that is selected by the user

switch Region
    case 'Singapore'
        Ta = Temp.T(:,[1,2]);
        c_elec = c_elec.Price(:,5);
        emission = Emission.Emission(:,5);
    case 'Munich'
        Ta = Temp.T(:,[1,3]);
        c_elec = c_elec.Price(:,4);
        emission = Emission.Emission(:,4);
    case 'Calgary'
        Ta = Temp.T(:,[1,4]);
        c_elec = c_elec.Price(:,3);
        emission = Emission.Emission(:,3);
    case 'Adelaide'
        Ta = Temp.T(:,[1,5]);
        c_elec = c_elec.Price(:,2);
        emission = Emission.Emission(:,2);
end

clearvars Temp Emission     % Clears these matrixes to speed up the process of collecting Data


%% Specifying the design variables and their equivalent range


Charger_Power = 40:140;
NCharger = 2:10;




%% Specifying the size of output matrix, simulation timestep
Data = zeros(numel(Ebat)*numel(Charger_Power)*numel(NCharger),9);   % ouput matrix
dt = 90;                                                            % Simulation timestep in second

%% Filling output matrix

row = 0;
for ebat = Ebat
     
     
     for P = Charger_Power
         
         for N = NCharger

                disp(['Ebat, ChargerPower, Ncharger are:   ', num2str(Ebat), ', ', num2str(P), ', ', num2str(N)]);
                
                row = row +1 ;
                Pavg = Vehicle_simulation(ebat, Param.Vehicle, Param.Cycle.DRIVING_CYCLE, false);   % The average power needed to run the bus
                [Emax, EEbat, Driving, Charging] = Scheduler(Pavg, N, P, Param.Demand, false,ebat,dt); % Finding the sequence of driving and charging
                    
                if isnan(Emax)
                        Data(row,1) = N;  
                        Data(row,2) = P;
                        Data(row,3) = ebat;    
                        Data(row,4:9) = NaN;        % This Line means that no solutin has been found based on the selected design variables.
                        clearvars EEbat Driving Charging
                else
                        BusNo = 1;
                        while abs(abs(EEbat(BusNo,1)) - abs(EEbat(BusNo,end)))/ebat > 0.04    % This line finds the bus with stedy state of SOC( Starts ...
                            BusNo = BusNo +1;                                                  % with an specific soc and returns to same state at the end of the day
                        end

                        
                        
                        
                        SOCstart = 0.95 - abs(EEbat(BusNo,1))/ebat;
                        [~,nt] = size(Driving);
                        Pdem = zeros(1,nt-1);

                        for ii = 1:nt-1

                            if Driving(BusNo,ii)
                                Pdem(ii) = -Pavg*1000;
                            elseif Charging(BusNo,ii)
                                Pdem(ii) = P*1000;
                            else 
                                Pdem(ii) = 0;
                            end
                        end
                        
                        y = Cost(ebat,N,P,Ta,dt,Driving,Charging,SOCstart,c_elec,emission,BusNo,Pavg,Battery);
                        Data(row,1) = N;
                        Data(row,2) = P;
                        Data(row,3) = ebat;
                        Data(row,4) = y.teol;
                        Data(row,5) = y.C.Cinf;
                        Data(row,6) = y.C.Cbat;
                        Data(row,7) = y.C.Ccons;
                        Data(row,8) = y.TCO;
                        Data(row,9) = y.emission;
                        
                    
                end
                         
         end
         
     end
     
 end

FilePath = fullfile(FolderName, FileName+".mat");
mkdir(FolderName);
save(FilePath,'Data');












