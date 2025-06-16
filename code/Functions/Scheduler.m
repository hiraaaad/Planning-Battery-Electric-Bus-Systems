function [Emax, Ebat, Driving, Charging] = Scheduler(b_h, Nchargers, P, Param, plottrue,Ebat_tot,dt)

timestep = dt/3600; %timestep [s]

n_tripsteps = round(Param.t_trip/60/timestep); %Number of timesteps
energyconsumed = timestep*b_h; %Energy consumed in each timestep [kWh]
energycharged = timestep*P; %Charged energy timestep [kWh]

%map demandcurve to timestep
t_raw = Param.Demand(:,1)/3600;  
demand_raw = Param.Demand(:,2);

t = t_raw(1):timestep:t_raw(end); %timevector
demand = interp1(t_raw,demand_raw,t,'previous');

%% Determine day time schedule

Ebat_start = zeros(Param.Nmod,1);
Driving_start = zeros(Param.Nmod,1);
Charging_start = zeros(Param.Nmod,1);
laststarted = ones(Param.Nmod,1)*10^9; %multiplication with large number necessary to avoid finding wrong donedriving values

%Parameter for finding continuum
threshold = -324; % Abort threshold for average energy drained at the end of the day
iterationcounter = 0;
continuous = false;

while not(continuous) 
    %Preallocate matrices
    Ebat = zeros(Param.Nmod,length(t)); %Amount of energy in battery [kWh]
    Driving = zeros(Param.Nmod,length(t)); %Driving = 1, not-driving = 0
    Charging = zeros(Param.Nmod,length(t)); %Charging = 1, not-charging = 0
    modulestarted = zeros(Param.Nmod,length(t)); 
    moduledone = zeros(Param.Nmod,length(t));
    chargestarted = zeros(Param.Nmod,length(t));
    chargedone = zeros(Param.Nmod,length(t));

    %Set starting point and pass on laststarted values
    Ebat(:,1) = Ebat_start;
    Driving(:,1) = Driving_start;
    Charging(:,1) = Charging_start;
    laststarted = round(laststarted-24/timestep);

    for i = 1:length(t)
        
        %stop driving vehicles that have ended their trip
        donedriving = find(laststarted == (i-n_tripsteps)); %Find modules that are done driving
        Driving(donedriving,i) = 0; %Stop driving
        moduledone(donedriving,i) = 1; %Mark point for plotting the markers
        
        %Stop charging vehicles that have reached full charge
        full = find(Ebat(:,i)>0);
        Ebat(full,i) = 0; 
        Charging(full,i) = 0;
        chargedone(full,i) = 1;
        Nchargers = Nchargers + length(full);
        
        %Start vehicles if demand exceeds supply
        demand_diff = (demand(i)-sum(Driving(:,i))); %difference between demand and supply
        for j = 1:demand_diff
            available = find(Driving(:,i)==0); %look for available modules
            [~, Index] = max(Ebat(available,i)); %find available module with the least energy drained
            module = available(Index); 
            Driving(module,i) = 1; %Start this module on a trip
            laststarted(module) = i; %Mark point for checking which modules are done driving
            modulestarted(module,i) = 1; %Mark point for plotting markers 
            %Make charger available again if the module was charging in the
            %previous Schedule.timestep
            if Charging(module,i) == 1
                Charging(module,i) = 0;
                chargedone(module,i) = 1;
                Nchargers = Nchargers + 1; 
            end
        end          
        
        %Connect free modules that are in need of charge to available
        %charger(s)
        for j = 1:Nchargers    %Fill up all available chargers
            needcharge = find(Driving(:,i) == 0 & Charging(:,i) == 0 & Ebat(:,i) < 0); %Find modules that are idling and need to charge
            if isempty(needcharge), break, end  %Check for the need to charge
            [~, Index] = min(Ebat(needcharge,i)); %Find module with most energy drained
            module = needcharge(Index); 
            Charging(module,i) = 1; %Set status to charging
            chargestarted(module,i) = 1; %Set marker for plots
            Nchargers = Nchargers - 1;%Set charer status to occupied  
        end
        
        %Set values for next step
        if not(i == length(t))
            %determine module statuses
            driving = find(Driving(:,i) == 1);
            charging = find(Charging(:,i)==1);
            idling = find(Driving(:,i) == 0 & Charging(:,i)==0);

            %set parameters for the next step
            Ebat(driving,i+1) = Ebat(driving,i) - energyconsumed; %calculate new energy content
            Ebat(charging,i+1) = Ebat(charging,i) + energycharged; %Add charged energy to battery
            Ebat(idling,i+1) = Ebat(idling,i); %Energy in the batteries of idling vehicles stays the same
            Driving(:,i+1) = Driving(:,i);
            Charging(:,i+1) = Charging(:,i);
        end
    end
    
    %Check whether continuity was reached
    E_difference = mean(Ebat(:,end) - Ebat_start);
    if and(E_difference < 0.01, E_difference >= 0)
        continuous = true;
    else
        iterationcounter = iterationcounter + 1;
        if  max(Ebat(:,end)) > threshold && iterationcounter < 10
            continuous = false;
            Ebat_start = Ebat(:,end);
            Driving_start = Driving(:,end);
            Charging_start = Charging(:,end);
        else
            disp(['No solution found for P = ' num2str(P) ' Nchargers = ' num2str(Nchargers)])
            Emax = NaN;
            return
        end 
    end
end

%calculate key figures
Ebat_required = min(Ebat,[],'all');
Emax = abs(Ebat_required);


%% Plot results
if plottrue    
    time = datetime(2018,1,1,floor(t),floor(mod(t,1)*60),mod(t,1/60)*3600);
    
    figure
    hold on
    for i = 1:Param.Nmod
        %Find driving start and end points
        if Driving(i,1) == 1
            I_modulestarted = [1 find(modulestarted(i,:))];
            I_moduledone = [find(moduledone(i,:)) length(t)];
        else
            I_modulestarted = find(modulestarted(i,:));
            I_moduledone = find(moduledone(i,:));  
        end
        %Find charging start and end points
        if Charging(i,1) == 1
            I_chargestarted = [1 find(chargestarted(i,:))];
            I_chargedone = [ find(chargedone(i,:)) length(t)];
        else
            I_chargestarted = find(chargestarted(i,:));
            I_chargedone = find(chargedone(i,:));
        end
        
        %Draw driving blocks
        for j = 1:length(I_modulestarted)
            hdriving = fill([time(I_modulestarted(j)) time(I_moduledone(j)) time(I_moduledone(j)) time(I_modulestarted(j))],...
            [i-1 i-1 i i],'b');
        end
        %Draw charging blocks
        for j = 1:length(I_chargestarted)
            hcharging = fill([time(I_chargestarted(j)) time(I_chargedone(j)) time(I_chargedone(j)) time(I_chargestarted(j))],...
            [i-1 i-1 i i],'r');
        end
    end
    datetick('x','HH PM','keeplimits','keepticks')   
    ylim([0 21])
    ylabel('Vehicle')
    legend([hdriving hcharging],'Driving','Charging','Location','NorthWest')  
    set(gca,'TickDir','out','FontName','Times New Roman','FontSize',10)
    set(gcf, 'Units', 'centimeters', 'Position', [15, 10, 10, 8])
    
    Max_module = 1;
    %   Determine points for Ebat line, makes the figure file size smaller
    I_modulestarted = find(modulestarted(Max_module,:));
    I_moduledone = find(moduledone(Max_module,:));  
    I_chargestarted = find(chargestarted(Max_module,:));
    I_chargedone = find(chargedone(Max_module,:));

    points = [1 I_modulestarted I_moduledone I_chargestarted I_chargedone length(t)];
    Y = sort(points);
    figure
    hold on
    plot(time(Y),100*(Ebat_tot/2-mean(Ebat(Max_module,Y))+Ebat(Max_module,Y))/Ebat_tot)
    datetick('x','HH PM','keeplimits','keepticks')
    ylabel('SOC in %')
    set(gca,'TickDir','out','FontName','Times New Roman','FontSize',10)
    set(gcf, 'Units', 'centimeters', 'Position', [15, 10, 10, 8])

end
