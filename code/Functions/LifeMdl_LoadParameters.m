function lifeMdl = LifeMdl_LoadParameters(Battery)

    switch Battery

        case "NCA"
           lifeMdl.n_states = 2;      % number of states in model that are integrated with time or cycles
           lifeMdl.n_outputs= 3;
           
           % Model Parameters
           lifeMdl.qcal_A =  75.4;
           lifeMdl.qcal_B = -3.34e+03;
           lifeMdl.qcal_C = 353;
           lifeMdl.qcal_p = 0.512;
           lifeMdl.qcyc_A = 1.86e-06;
           lifeMdl.qcyc_B = 4.74e-11;
           lifeMdl.qcyc_C = 0.000177;
           lifeMdl.qcyc_D = 3.34e-11;
           lifeMdl.qcyc_E = 2.81e-09;
           lifeMdl.qcyc_p = 0.699;
        
        case 'NMC'
            lifeMdl.n_states = 6;      % number of states in model that are integrated with time or cycles
            lifeMdl.n_outputs= 10;      % number of outputs in model
    
            % Model parameters
            lifeMdl.q1_0 = 2.66e7;
            lifeMdl.q1_1 = -17.8;
            lifeMdl.q1_2 = -5.21;
            lifeMdl.q2 = 0.357;
            lifeMdl.q3_0 = 3.80e3;
            lifeMdl.q3_1 = -18.4;
            lifeMdl.q3_2 = 1.04;
            lifeMdl.q4 = 0.778;
            lifeMdl.q5_0 = 1e4;
            lifeMdl.q5_1 = 153;
            lifeMdl.p_LAM = 10;
            lifeMdl.r1 = 0.0570;
            lifeMdl.r2 = 1.25;
            lifeMdl.r3 = 4.87;
            lifeMdl.r4 = 0.712;
            lifeMdl.r5 = -0.08;
            lifeMdl.r6 = 1.09;
           
        case 'LFP'
            lifeMdl.n_states = 5;      
            lifeMdl.n_outputs= 7;     
    
            % Instantiate parameter table
            pVars = {'q2','q1_b0','q1_b1','q1_b2','q3_b0','q3_b1','q3_b2','q3_b3','q3_b4','q8','q9','q7_b0','q7_soc_skew','q7_soc_width','q7_dod_skew', 'q7_dod_width','q7_dod_growth','q6','q5_b0','q5_b1','q5_b2'};
            p = [0.000130510034211874,0.989687151293590,-2881067.56019324,8742.06309157261,0.000332850281062177,734553185711.369,-2.82161575620780e-06,-3284991315.45121,0.00127227593657290,0.00303553871631028,1.43752162947637,0.582258029148225,0.0583128906965484,0.208738181522897,-3.80744333129564,1.16126260428210,25.4130804598602,1.12847759334355,-6.81260579372875e-06,2.59615973160844e-05,2.11559710307295e-06];
            p = array2table(p, 'VariableNames', pVars);
            lifeMdl.p = p;
    
            pvars_rdc = {'k_ref_r_cal','Ea_r_cal','C_r_cal','D_r_cal','A_r_cyc','B_r_cyc','C_r_cyc','D_r_cyc'};
            p_rdc = [3.4194e-10,71827,-3.3903,1.5604,-0.002,0.0021,6.8477,0.91882];
            p_rdc = array2table(p_rdc, 'VariableNames', pvars_rdc);
            lifeMdl.p_rdc = p_rdc;

        case 'LI'
            lifeMdl.n_states = 5;      
            lifeMdl.n_outputs= 7;      
    
            % Instantiate parameter table
            pVars = {'q2','q1_b0','q1_b1','q1_b2','q3_b0','q3_b1','q3_b2','q3_b3','q3_b4','q8','q9','q7_b0','q7_soc_skew','q7_soc_width','q7_dod_skew', 'q7_dod_width','q7_dod_growth','q6','q5_b0','q5_b1','q5_b2'};
            p = [0.000130510034211874,0.989687151293590,-2881067.56019324,8742.06309157261,0.000332850281062177,734553185711.369,-2.82161575620780e-06,-3284991315.45121,0.00127227593657290,0.00303553871631028,1.43752162947637,0.582258029148225,0.0583128906965484,0.208738181522897,-3.80744333129564,1.16126260428210,25.4130804598602,1.12847759334355,-6.81260579372875e-06,2.59615973160844e-05,2.11559710307295e-06];
            p = array2table(p, 'VariableNames', pVars);
            lifeMdl.p = p;
    
            pvars_rdc = {'k_ref_r_cal','Ea_r_cal','C_r_cal','D_r_cal','A_r_cyc','B_r_cyc','C_r_cyc','D_r_cyc'};
            p_rdc = [3.4194e-10,71827,-3.3903,1.5604,-0.002,0.0021,6.8477,0.91882];
            p_rdc = array2table(p_rdc, 'VariableNames', pvars_rdc);
            lifeMdl.p_rdc = p_rdc;
    end

end