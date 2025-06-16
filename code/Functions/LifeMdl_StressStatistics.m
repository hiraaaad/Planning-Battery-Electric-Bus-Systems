function cycle = LifeMdl_StressStatistics(cycle)
tsec = cycle.tsec;

dt = cycle.tsec(end) - cycle.tsec(1);
delta_t_days = cycle.t(end) - cycle.t(1);

% TdegK
TdegK = cycle.TdegC + 273.15;

% soc
soc = cycle.soc;

% Ua:
x_a_eq = @(SOC) 8.5e-3 + SOC.*(7.8e-1 - 8.5e-3);
Ua_eq = @(x_a) 0.6379 + 0.5416.*exp(-305.5309.*x_a) + 0.044.*tanh(-1.*(x_a-0.1958)./0.1088) - 0.1978.*tanh((x_a-1.0571)./0.0854) - 0.6875.*tanh((x_a+0.0117)./0.0529) - 0.0175.*tanh((x_a-0.5692)./0.0875);
Ua = Ua_eq(x_a_eq(soc));

% DOD
dod = max(cycle.soc) - min(cycle.soc);

% Crate
Crate = diff(cycle.soc)./diff(cycle.t .* 24);
Crate = abs(Crate);
maskNonResting = Crate > 1e-3;
if any(maskNonResting)
    Crate = Crate(maskNonResting);
    difft = diff(cycle.t);
    difft = difft(maskNonResting);
    tNonResting = cumsum(difft);
    Crate = trapz(tNonResting, Crate)/(tNonResting(end)-tNonResting(1));
else
    Crate = 0;
end


dEFC = sum(abs(diff(cycle.soc)))/2;

% output the extracted stress statistics
cycle = struct();
cycle.tsec = tsec;
cycle.delta_tsec = dt;
cycle.delta_tdays = delta_t_days;
cycle.dEFC =    dEFC;
cycle.TdegK =   TdegK;
cycle.soc =     soc;
cycle.Ua =      Ua;
cycle.dod =     dod;
cycle.Crate =   Crate;
end
