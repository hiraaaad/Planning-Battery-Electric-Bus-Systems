function out = Cost(Ebattery,NCharger,Charger_Power,Ta,dt,Driving,Charging,SOCstart,c_elec,e,BusNo,Pavg,Battery)


switch Battery
    case 'LFP'
        c_bat = 86.4;       % Battery specific cost in  $/Kwh
    case 'NMC'
        c_bat = 156.6;
    case 'NCA'
        c_bat = 97.2;
    case 'LI'
        c_bat = 167;
end



n_vehicle = 21;         
r = 0.0056;            % Annual discount factor
t_charger = 10;        % charging station lifetime in years
c_cha_fixed = 20000;   % fixed charging station cost in $
c_cha_variable = 445;  % variable charging station cost in $


res = EOL(Ebattery, dt, Ta,SOCstart,Driving,Charger_Power,NCharger,Charging,BusNo,e,c_elec,Pavg,Battery);
t_EOL = res.teol_a;

clearvars Driving Charging 

Ccons = res.Ccons;
Cbat = 10^(-3)*n_vehicle*c_bat*Ebattery*(r/(1-exp(-r*t_EOL)));   % K$/year
Cinf = 0.001*NCharger*(c_cha_fixed + c_cha_variable*Charger_Power)*r/(1-exp(-r*t_charger));% K$/year

y = Cbat + Ccons + Cinf;
out.C.Cbat = Cbat;
out.C.Cinf = Cinf;
out.C.Ccons = Ccons;
out.TCO = y;
out.emission = res.emission;
out.teol = t_EOL;
end