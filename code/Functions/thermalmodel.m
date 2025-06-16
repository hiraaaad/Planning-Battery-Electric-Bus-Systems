function [Tcell_new, Th_new] = thermalmodel(Tcell, Th, Ploss, Pheat, Pcool, Ta, dt,ncells,Battery)
   [mhousing, Atop, ltop, Asides_conv, Asides_rad, Rins] = TMparam(ncells);
    
    if Battery == "NCA"
        Ccell = 39;   % Cell heat capacity J/K
    else
        Ccell = 76.27;
    end

    Rth_in = 3.3; % Thermal resistance between cell and cell housing in K/W
    COPheat = 1; % Coefficient of performance of heating system
    COPcool = -3; % Coefficient of performance of cooling system
    cphousing = 896; % Specific heat capacity of housing material in J/kg/K

    % Cell temperature update
    Tcell_new = Tcell + (Ploss + (Th - Tcell) / Rth_in) * dt / Ccell;

    % Housing temperature update
    Rout = ConvRad(Th, Ta, Atop, ltop, Asides_conv, Asides_rad, Rins); % Thermal resistance between surface and ambient
    Th_new = Th + (Pheat * COPheat + Pcool * COPcool + ...
                   ncells * (Tcell - Th) / Rth_in + ...
                   (Ta - Th) / Rout) * dt / (mhousing * cphousing);
end


function [mhousing, Atop, ltop, Asides_conv, Asides_rad, Rins] = TMparam(ncells)
    
    h = 2.2; % battery pack height in meters [Heliox]
    w = 0.8; % battery pack width in meters [Heliox]
    l = 0.8; % battery pack length in meters [Heliox]
    sfins = 0.05; % Fin spacing [Assumption]
    lfins = 0.0; % fin length in meter [Assumption]
    t_ins = 0.0; % insulation thickness in m [Assumption]
    kfoam = 0.035; % Thermal conductivity of expanded polystyrene in W/K/m [Lienhard et al. A heat transfer textbook p.718]

%     Housing weight
    m_celltopack = 1/0.552; % Assuming a value for m_celltopack, update if needed
    mhousing = ncells * m_celltopack * (m_celltopack - 1); % Weight of battery housing in kg
    
%     SES dimensions
    Atop = (l + 2 * t_ins) * (w + 2 * t_ins); % Battery pack top surface in m^2
    Ptop = (2 * l + 2 * w + 8 * t_ins); % Battery pack top surface perimeter in m
    ltop = Atop / Ptop; % Battery pack top surface characteristic length for natural convection in m
    nfins = Ptop / sfins + 4; % Number of cooling fins
    Asides_conv = h * (Ptop + 2 * lfins * nfins); % Side surface area for natural convection in m^2
    Asides_rad = h * (Ptop + 8 * lfins); % Side surface for radiation in m^2

%     Insulation resistance
    Rins = t_ins / kfoam / (Atop + Asides_rad); % Thermal resistance of insulation in K/W
end

function Rout = ConvRad(Th_Celsius, Ta_Celsius, Atop, ltop, Asides_conv, Asides_rad,Rins)
    
    Th = Th_Celsius + 273.15;
    Ta = Ta_Celsius + 273.15;

    % Constants
    g = 9.80665; % Standard acceleration of gravity in m/s^2
    Pr = 0.707; % Prandtl number for air
    nu = 1.575e-5; % Kinematic viscosity of air at 300K in m^2/s
    kair = 0.0264; % Thermal conductivity of air at 20°C in W/K/m
    epsilon = 0.92; % Emissivity of a painted surface
    sigma = 5.67e-8; % Stefan-Boltzmann constant in W/(m^2*K^4)
    h = 2.2; % Battery pack height in meters

    % Convection top
    Ra_top = g / Ta * abs(Th - Ta) * ltop^3 / nu^2 * Pr;
    if Th > Ta % heated plate
        Nu_top = 0.15 * (Ra_top * (1 + (0.322 / Pr)^(11 / 20))^(-20 / 11))^(1 / 3);
    else % cooled plate
        Nu_top = 0.6 * (Ra_top * (1 + (0.492 / Pr)^(9 / 16))^(-16 / 9))^0.2;
    end
    R_top = ltop / Nu_top / kair / Atop;

    % Convection sides
    Ra_sides = g / Ta * abs(Th - Ta) * h^3 / nu^2 * Pr;
    Nu_sides = (0.825 + 0.387 * (Ra_sides^(1 / 6) / (1 + (0.492 / Pr)^(9 / 16))^(8 / 27)))^2;
    R_sides = h / Nu_sides / kair / Asides_conv;

    % Radiation
    R_rad = 1 / (epsilon * sigma * (Th^2 + Ta^2) * (Th + Ta) * (Asides_rad + Atop));

    % Total thermal resistance
    if Th == Ta
        Rout = Rins + R_rad;
    else
        Rout = Rins + (1 / R_top + 1 / R_sides + 1 / R_rad)^-1;
    end
end

