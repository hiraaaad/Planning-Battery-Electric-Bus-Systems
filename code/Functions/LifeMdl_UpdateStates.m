function xx = LifeMdl_UpdateStates(cycle,xx0,Battery)

        % Normalized stressor values
        cycle.TdegKN = cycle.TdegK ./ (273.15 + 35);
        cycle.TdegC = cycle.TdegK - 273.15;
        cycle.UaN = cycle.Ua ./ 0.123;
        scalingfactor = 1;
        
        lifeMdl = LifeMdl_LoadParameters(Battery);
        
switch Battery
    case "NCA"
        p = lifeMdl; 
        % Calculate the degradation coefficients
        k_cal = p.qcal_A * exp(p.qcal_B./cycle.TdegK) .* exp(p.qcal_C*cycle.soc./cycle.TdegK);
        k_cyc = ((p.qcyc_A + p.qcyc_B*cycle.Crate + p.qcyc_C*cycle.dod) * (exp(p.qcyc_D./cycle.TdegK) + exp(-p.qcyc_E./cycle.TdegK)));

        % Calculate time based average of each rate
        k_cal = trapz(cycle.tsec, k_cal) / cycle.delta_tsec;
        k_cyc = trapz(cycle.tsec, k_cyc) / cycle.delta_tsec;

        % Calculate incremental state changes
        
        dq_t = scalingfactor * dynamicPowerLaw(xx0(1), cycle.delta_tdays, k_cal, p.qcal_p);
        dq_EFC = scalingfactor * dynamicPowerLaw(xx0(2), cycle.dEFC, k_cyc, p.qcyc_p);
        dxx = [dq_t;dq_EFC];
        xx = xx0 + dxx;
        
    case "LFP"
        p = lifeMdl.p;
        p_rdc = lifeMdl.p_rdc;
        
        q1 = abs(p.q1_b0 .* exp(p.q1_b1 .* (1./(cycle.TdegK.^2)) .* (cycle.Ua.^0.5)) .* exp(p.q1_b2 .* (1./cycle.TdegK) .* (cycle.Ua.^0.5)));
        q3 = abs(p.q3_b0 .* exp(p.q3_b1 .* (1./(cycle.TdegK.^4)) .* (cycle.Ua.^(1/3))) .* exp(p.q3_b2 .* (cycle.TdegK.^3) .* (cycle.Ua.^(1/4))) .* exp(p.q3_b3 .* (1./(cycle.TdegK.^3)) .* (cycle.Ua.^(1/3))) .* exp(p.q3_b4 .* (cycle.TdegK.^2) .* (cycle.Ua.^(1/4))));
        q5 = abs(p.q5_b0 + p.q5_b1 .*cycle. dod + p.q5_b2 .* exp((cycle.dod.^2) .* (cycle.Crate.^3)));
        q7 = abs(p.q7_b0 .* skewnormpdf(cycle.soc, p.q7_soc_skew, p.q7_soc_width) .* skewnormpdf(cycle.dod, p.q7_dod_skew, p.q7_dod_width) .* sigmoid(cycle.dod, 1, p.q7_dod_growth, 1));
        k_temp_r_cal = p_rdc.k_ref_r_cal .* exp((-p_rdc.Ea_r_cal / 8.3144) .* (1./cycle.TdegK - 1./298.15));
        k_soc_r_cal = p_rdc.C_r_cal .* (cycle.soc - 0.5).^3 + p_rdc.D_r_cal;
        k_Crate_r_cyc = p_rdc.A_r_cyc .* cycle.Crate + p_rdc.B_r_cyc;
        k_dod_r_cyc = p_rdc.C_r_cyc .* (cycle.dod - 0.5).^3 + p_rdc.D_r_cyc;
        q1 = trapz(cycle.tsec, q1) / cycle.delta_tsec;
        q3 = trapz(cycle.tsec, q3) / cycle.delta_tsec;
        q7 = trapz(cycle.tsec, q7) / cycle.delta_tsec; 
        k_temp_r_cal = trapz(cycle.tsec, k_temp_r_cal) / cycle.delta_tsec;
        k_soc_r_cal = trapz(cycle.tsec, k_soc_r_cal) / cycle.delta_tsec; 
         
        % Calendar loss
        dqLossCal = dynamicSigmoid(xx0(1), cycle.delta_tdays, q1, p.q2, q3);
        % Cycling loss
        dqLossCyc =  scalingfactor*dynamicPowerLaw(xx0(2), cycle.dEFC, q5, p.q6);
        
        if cycle.dEFC / cycle.delta_tdays > 2 % only evalaute if more than 2 full cycles per day
                dq_BreakIn_EFC = dynamicSigmoid(xx0(3), cycle.dEFC, q7, p.q8, p.q9);
        else
                dq_BreakIn_EFC = 0;
        end

        
        % resistance
        drGainCal =  k_temp_r_cal .* k_soc_r_cal * cycle.delta_tsec;
        drGainCyc =  scalingfactor*k_Crate_r_cyc .* k_dod_r_cyc * cycle.dEFC / 100;
        
         
        % Pack up & accumulate state vector forward in time
        dxx = [dqLossCal; dqLossCyc;dq_BreakIn_EFC; drGainCal; drGainCyc];
        xx = xx0 + dxx;

    case "NMC"

        q1 = lifeMdl.q1_0 .* exp(lifeMdl.q1_1 .* (1 ./ cycle.TdegKN)) .* exp(lifeMdl.q1_2 .* (cycle.UaN ./ cycle.TdegKN));
        q3 = lifeMdl.q3_0 .* exp(lifeMdl.q3_1 .* (1 ./ cycle.TdegKN)) .* exp(lifeMdl.q3_2 .* exp(cycle.dod.^2));
        q5 = lifeMdl.q5_0 + lifeMdl.q5_1 .* (cycle.TdegC - 55) .* cycle.dod;
        
        q1 = trapz(cycle.tsec, q1) / cycle.delta_tsec;
        q3 = trapz(cycle.tsec, q3) / cycle.delta_tsec;
        q5 = trapz(cycle.tsec, q5) / cycle.delta_tsec;

        % Calculate incremental state changes
        dq_LLI_t = scalingfactor*dynamicPowerLaw(xx0(1), cycle.delta_tdays, 2*q1, lifeMdl.q2);
        dq_LLI_EFC = scalingfactor*dynamicPowerLaw(xx0(2), cycle.dEFC, q3, lifeMdl.q4);
        dq_LAM = scalingfactor*dynamicSigmoid(xx0(3), cycle.dEFC, 1, 1/q5, lifeMdl.p_LAM);
        dr_LLI_t = scalingfactor*dynamicPowerLaw(xx0(4), cycle.delta_tdays, lifeMdl.r1 * q1, lifeMdl.r2);
        dr_LLI_EFC = scalingfactor*dynamicPowerLaw(xx0(5), cycle.dEFC, lifeMdl.r3 * q3, lifeMdl.r4);

        % Pack up
        dxx = [dq_LLI_t; dq_LLI_EFC; dq_LAM; dr_LLI_t; dr_LLI_EFC; xx0(6)];
        xx = xx0 + dxx;
    case "LI"

        p = lifeMdl.p;
        p_rdc = lifeMdl.p_rdc;
        
        
        q1 = abs(p.q1_b0 .* exp(p.q1_b1 .* (1./(cycle.TdegK.^2)) .* (cycle.Ua.^0.5)) .* exp(p.q1_b2 .* (1./cycle.TdegK) .* (cycle.Ua.^0.5)));
        q3 = abs(p.q3_b0 .* exp(p.q3_b1 .* (1./(cycle.TdegK.^4)) .* (cycle.Ua.^(1/3))) .* exp(p.q3_b2 .* (cycle.TdegK.^3) .* (cycle.Ua.^(1/4))) .* exp(p.q3_b3 .* (1./(cycle.TdegK.^3)) .* (cycle.Ua.^(1/3))) .* exp(p.q3_b4 .* (cycle.TdegK.^2) .* (cycle.Ua.^(1/4))));
        q5 = abs(p.q5_b0 + p.q5_b1 .*cycle. dod + p.q5_b2 .* exp((cycle.dod.^2) .* (cycle.Crate.^3)));
        q7 = abs(p.q7_b0 .* skewnormpdf(cycle.soc, p.q7_soc_skew, p.q7_soc_width) .* skewnormpdf(cycle.dod, p.q7_dod_skew, p.q7_dod_width) .* sigmoid(cycle.dod, 1, p.q7_dod_growth, 1));
        k_temp_r_cal = p_rdc.k_ref_r_cal .* exp((-p_rdc.Ea_r_cal / 8.3144) .* (1./cycle.TdegK - 1./298.15));
        k_soc_r_cal = p_rdc.C_r_cal .* (cycle.soc - 0.5).^3 + p_rdc.D_r_cal;
        k_Crate_r_cyc = p_rdc.A_r_cyc .* cycle.Crate + p_rdc.B_r_cyc;
        k_dod_r_cyc = p_rdc.C_r_cyc .* (cycle.dod - 0.5).^3 + p_rdc.D_r_cyc;
        q1 = trapz(cycle.tsec, q1) / cycle.delta_tsec;
        q3 = trapz(cycle.tsec, q3) / cycle.delta_tsec;
        q7 = trapz(cycle.tsec, q7) / cycle.delta_tsec; 
        k_temp_r_cal = trapz(cycle.tsec, k_temp_r_cal) / cycle.delta_tsec;
        k_soc_r_cal = trapz(cycle.tsec, k_soc_r_cal) / cycle.delta_tsec; 
         
        % Calendar loss
        dqLossCal = dynamicSigmoid(xx0(1), cycle.delta_tdays, q1, p.q2, q3);
        % Cycling loss
        dqLossCyc =  scalingfactor*dynamicPowerLaw(xx0(2), cycle.dEFC, q5, p.q6);
        
        if cycle.dEFC / cycle.delta_tdays > 2 % only evalaute if more than 2 full cycles per day
                dq_BreakIn_EFC = dynamicSigmoid(xx0(3), cycle.dEFC, q7, p.q8, p.q9);
        else
                dq_BreakIn_EFC = 0;
        end

        
        % resistance
        drGainCal =  k_temp_r_cal .* k_soc_r_cal * cycle.delta_tsec;
        drGainCyc =  scalingfactor*k_Crate_r_cyc .* k_dod_r_cyc * cycle.dEFC / 100;
        
         
        % Pack up & accumulate state vector forward in time
        dxx = [dqLossCal; dqLossCyc;dq_BreakIn_EFC; drGainCal; drGainCyc];
        xx = xx0 + dxx;
        
end
    
end



function dy = dynamicPowerLaw(y0, dx, k, p)
        % DYNAMICPOWERLAW calculates the change of state for states modeled by a
        % power law equation, y = k*x^p. The output is instantaneous slope of dy
        % with respect to dx.
        if y0 == 0
            if dx == 0
                dydx = 0;
            else
                y0   = k * dx^p;
                dydx = y0 / dx;
            end
        else
            if dx == 0
                dydx = 0;
            else
                dydx = k * p * (y0 / k)^((p-1) / p);
            end
        end
        dy = dydx * dx;
end

function dy = dynamicSigmoid(y0, dx, y_inf, k, p)
        if y0 == 0
            if dx == 0
                dydx = 0;
            else
                dy = 2 * y_inf * (1/2 - 1 / (1 + exp((k * dx) ^ p)));
                dydx = dy / dx;
            end
        else
            if dx == 0
                dydx = 0;
            else
                x_inv = (1 / k) * ((log(-(2 * y_inf/(y0-y_inf)) - 1)) ^ (1 / p) );
                z = (k * x_inv) ^ p;
                dydx = (2 * y_inf * p * exp(z) * z) / (x_inv * (exp(z) + 1) ^ 2);
            end
        end
        dy = dydx * dx;
    end


function y = sigmoid(x, alpha, beta, gamma)
    y = 2*alpha*(1/2 - 1./(1 + exp((beta*x).^gamma)));
end

function y = skewnormpdf(x, skew, width)
    x_prime = (x-0.5)./width;
    y = 2 * normpdf(x_prime) .* normcdf(skew .* x_prime);
end