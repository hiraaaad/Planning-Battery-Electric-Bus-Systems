function [emission,Ccons,New_Charging,Max_Ch_Index] = NightlyCharging(Charging,Pch,Ebat,dt,emission,Ccons,Celec,SOCaging,SOCstart,BusNo,Nch,e)

        Nightly_Charging_Start_Index = 70;      % Starting Nightly charging from 1:45 A.M  and may last untile 5:45 A.M

        New_Charging = Charging;
        dSOC = SOCaging(end) - SOCstart;

                                    
                                    if dSOC < 0  
                                        
                                                tcharging = Ebat*abs(dSOC)/Pch;
                                                ntsteps = floor(tcharging*3600/dt);
                                                Buses = unique([BusNo,1:21]);
                                                if  mod(21,Nch) == 0
                                                    NChargingPriod = 21/Nch;
                                                else
                                                    NChargingPriod = floor(21/Nch)+1;
                                                end

                                                for j = 1:NChargingPriod
                                                    js = (j-1)*Nch+1;
                                                    je = min(21,j*Nch);
                                                    ChInd = (Nightly_Charging_Start_Index + (j-1)*(ntsteps+1)) : (Nightly_Charging_Start_Index+ j*(ntsteps+1)-1);
                                                    New_Charging(Buses(js:je),ChInd) = 1;
                                                end
                                                
                                                scharging = sum(New_Charging(:,1:end-1),1);
                                                emission = emission + sum(e'.*scharging)*0.001*(dt/3600)*Pch;
                                                Ccons = Ccons + sum(Celec'.*scharging)*dt*Pch/10^6/3600;
                                                Max_Ch_Index = max(ChInd);
                                    else
                                        
                                            Max_Ch_Index = 1;  
                                            New_Charging = Charging;
                                            scharging = sum(New_Charging(:,1:end-1),1);
                                            emission = emission + sum(e'.*scharging)*0.001*(dt/3600)*Pch;
                                            Ccons = Ccons + sum(Celec'.*scharging)*dt*Pch/10^6/3600;
                                    
                                        
                                    end
                                    
                                    


end