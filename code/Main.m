
% This is the main script for generating data. Since the number of instances
% for a specific region, and battery is extremely large, and 
% therefore it is imposible to gather the whloe data in a single matrix,So we
% decided to break the results into small matrices. For instance for a
% specific region, and battery, it generates 321 matrices with different
% names, then you can augment all matrices to creat a single matrix for analysis. For
% instance if you select Singapore and NMC battery, it will generate
% matrices like: Data_NMC_140_Singapore, ..... ,Data_NMC_320_Singapore, and
% strore them in the "Data" folder.
 
clc;
clear;
close all;
BatteryTypes = {'LFP', 'NCA', 'NMC', 'LI'};
[BatteryIndex, tf] = listdlg('ListString', BatteryTypes, ...
    'SelectionMode', 'single', ...
    'PromptString', 'Select a battery type:', ...
    'Name', 'Battery Type Selection');

if tf
    SelectedBattery = BatteryTypes{BatteryIndex};
    disp(['Battery: ', SelectedBattery]);
else
    disp('No Battery Selected.');
end


Regions = {'Singapore', 'Adelaide', 'Munich', 'Calgary'};
[CityIndex, tf] = listdlg('ListString', Regions, ...
    'SelectionMode', 'single', ...
    'PromptString', 'Select a Region:', ...
    'Name', 'Region');

if tf
    Region = Regions{CityIndex};
    disp(['Region: ', Region]);
else
    disp('No Region Selected.');
end

disp('Running code for ' + string(Regions(CityIndex)) + ' and ' + string(BatteryTypes(BatteryIndex)) + ' Battery');

addpath('Functions');  % Adjust the folder name if needed

% Ebat in range of 140 to 320 kWh has been tested, feel free to change
% accordingly.
for Ebat = 140:320
  Data_Generation(Region,SelectedBattery,Ebat);
end