function yy = LifeMdl_UpdateOutput(xx,Battery)

        lifeMdl = LifeMdl_LoadParameters(Battery);
        switch Battery
            case "NCA"
                q_Cal = 1 - xx(1);
                q_EFC = 1 - xx(2);
                q = 1 - xx(1)- xx(2);
                
                yy = [q q_Cal q_EFC];
            case "LFP"
                qCal = 1 - xx(1);
                % Scale cycling loss to assume cells aren't so long lived as the
                % Sony Murata cells are (10-15 thousand EFCs).
                qCyc = 1 - xx(2);
                q_BreakIn_EFC = 1 - xx(3); 
                
                q = 1 - xx(1) - xx(2) - xx(3);
                
                rGainCal = 1 + xx(4);
                rGainCyc = 1 + xx(5);
                r = 1 + xx(4) + xx(5);
                yy = [q qCal qCyc q_BreakIn_EFC r rGainCal rGainCyc];
            case "NMC"
             
                q_LLI = 1 - xx(1) - xx(2);
                q_LLI_t = 1 - xx(1);
                q_LLI_EFC = 1 -  xx(2);
                q_LAM = 1.01 - xx(3);
                q = min([q_LLI, q_LAM]);
        
                % Resistance
                r_LLI = 1 + xx(4) + xx(5);
                r_LLI_t = 1 + xx(4);
                r_LLI_EFC = 1 + xx(5);
                r_LAM = lifeMdl.r5 + lifeMdl.r6 * (1 / q_LAM);
                r = max([r_LLI, r_LAM]);
        
                % Assemble output
                yy = [q, q_LLI, q_LLI_t, q_LLI_EFC, q_LAM, r, r_LLI, r_LLI_t, r_LLI_EFC, r_LAM];
            case "LI"
                qCal = 1 - xx(1);

                qCyc = 1 - xx(2);
                q_BreakIn_EFC = 1 - xx(3); 
                
                q = 1 - xx(1) - xx(2) - xx(3);
                
                rGainCal = 1 + xx(4);
                rGainCyc = 1 + xx(5);
                r = 1 + xx(4) + xx(5);
                yy = [q qCal qCyc q_BreakIn_EFC r rGainCal rGainCyc];
        end

end