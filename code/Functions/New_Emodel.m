function [Pheat,Pcool,SOC_new,Ploss] = New_Emodel(charging, driving,SOC,dt,Pavg,Pch,Tcell,Theat,Tcool,step_counter,Ebat,ncell,Uocv,Ri,Unom,Battery)

Pheater = 15000;  % Heating power to warm the battery
Pcooler = 13000;  % Cooling power to cool the battery

if ( Tcell < Theat   && driving(step_counter))
    Pheat = Pheater;
    Pcool = 0;
elseif ( Tcell > Tcool  && driving(step_counter))
    Pheat = 0;
    Pcool = Pcooler;
else 
    Pheat = 0;
    Pcool = 0;
end



if driving(step_counter)
    SOC_new = SOC - Pavg*(dt/3600)/Ebat - Pheat*dt/3600/Ebat/1000  - Pcool*dt/3600/Ebat/1000;
elseif charging(step_counter)
    SOC_new = SOC + Pch*(dt/3600)/Ebat;
else
    SOC_new = SOC;
end
SOC_new = clamp(SOC_new,0,0.95);
Ri_ch = Ri;
Ri_dch = Ri;
[Pmin, Pmax] = powerlim(Uocv, Ri_ch, Ri_dch,Battery);
Eloss = abs(SOC_new - SOC)*Ebat;
Ploss_total = Eloss*1000/(dt/3600);
Itotal = Ploss_total/Unom;
Ploss = (Itotal/ncell)^2*Ri_ch;

Ploss = clamp( Ploss, Pmin, Pmax);


end


function [Pmin, Pmax] = powerlim(Uocv, Ri_ch, Ri_dch,Battery)
  
    switch Battery
        case "LFP"
            Imin = -20;  % Discharge current limit
            Imax = 3;    % Charge current limit
        case "NMC"
            Imin = -5.36;
            Imax = 5.36;
        case "NCA"
            Imin = -6.8;
            Imax = 3.4;
        case "LI"
            Imin = -3.6;
            Imax = 3.6;
    end

	Pmin = (Uocv+Ri_dch*Imin)*Imin; % Discharge power limit
    Pmax = (Uocv+Ri_ch*Imax)*Imax;  % Charge Power limit
end


function z = clamp(x, lo, hi)
    if x < lo
        z = lo;
    elseif x > hi
        z =  hi;
    else
        z =  x;
    end
end