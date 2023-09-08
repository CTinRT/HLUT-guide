% HLUT calibration and evaluation code, Copyright (c) 2023, MAASTRO.
% 
% This software (any code and/or associated documentation: the "Software")
% is distributed under the terms of the MIT license (the "License").
% Refer to the License for more details. You should have received a copy of
% the License along with the code. If not, see 
% https://choosealicense.com/licenses/mit/.
% SPDX-License-Identifier: MIT
%
% PLEASE NOTE THAT THIS SOFTWARE IS NOT PUBLISHED AS (AN ACCESSORY TO) A MEDICAL DEVICE!
% Read the README file for more details.
%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Instructions for use:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is the main file for the HLUT calibration and evalaution. This code
% follows the guide described in DOI: 
% https://doi.org/10.1016/j.radonc.2023.109675

% In the user input should be specified in the first section, specifically
% in line 42, 44, 47, 51 and 56 below.

% The code first imports the measured CT numbers, as specified in the input 
% Excel file (please be aware that this Excel should be closed before 
% running this Matlab code). Secondly the code calibrates the HLUT and plot
% the results, followed by an evaluation of the generated HLUTs. Lastly, a 
% PDF file is generated (if the user has access to the toolbox allowing for
% this) which contains all the results. 
% Figures and files with the HLUT connection points (in txt and csv format)
% are saved to the results folder (folder name specified in line 47).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Define Input and Output files - only section which needs to be changed:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all; clc;
format compact; format shortG;

%Define Excel file with CT numbers:
%Input folder name:
Input_Folder_Name='Input_folder';
%File name - for Excel file with CT numbers and phantom data:
File_name='DataForCTCalibration_Philips_CT7500_Mono70keV.xlsx';

%Folder name to save the results to (either relative or absolute path):
Output_Folder_Name='Results';

%Define folder where additional Matlab files are stored (either relative or
%absolute path):
Folder_additional_scripts='Extra_files';

%% Define parameters:

%Initial energy of proton beam (MeV):
E_kin=100;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Check Matlab version:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Matlab version:
matlab_version=version('-release');

if str2double(matlab_version(1:4))<2019
    error(['We are sorry, but the script is not guarenteed to run on ',...
        'older versions than 2019. Some functionality might still work, ',...
        'but some changes will be most likely be needed.'])
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Check if needed Matlab Toolboxes are installed:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~any(any(contains(struct2cell(ver), 'Optimization Toolbox'))) || ...
        ~license('checkout','optimization_toolbox')
    error('Without the Optimization ToolBox, this script cannot run')
end
if ~any(any(contains(struct2cell(ver), 'Statistics and Machine Learning Toolbox'))) || ...
        ~license('checkout','statistics_toolbox')
    error('Without the Statistics and Machine Learning Toolbox, this script cannot run')
end
PDF_generator_exist=true;
if ~any(any(contains(struct2cell(ver), 'MATLAB Report Generator'))) || ...
        ~license('checkout','matlab_report_gen')
    warning('Without MATLAB Report Generator, no PDF can be created')
    PDF_generator_exist=false;
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Check if needed folders exist:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Check if the Output folder exists, else make it:
if ~exist(Output_Folder_Name,'dir')
    mkdir(Output_Folder_Name)
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Load Excel file with CT numbers and phantom data:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Add folder with additional Matlab scripts to search path:
addpath(Folder_additional_scripts)

%Load the input data from the Excel input file:
[CTnumbers,SPR,Data_Phantom,Data_TabulatedHumanTissues,Data_Elements,...
    Data_water]=load_inputdata(Input_Folder_Name,File_name,matlab_version);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Perform calibration procedure:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute theoretical SPR values:

%Phantom inserts:
SPR.Phantom.SPR_Theoretical=Compute_theoretical_SPR(E_kin,...
    Data_Phantom.MaterialParameters.Density,Data_Phantom.wi,...
    Data_Elements.Zi,Data_Elements.Ai,Data_Elements.Ii,Data_water,true);

%Tabulated Human Tissues:
SPR.TabulatedHumanTissues=table;
SPR.TabulatedHumanTissues.Tissue_names=Data_TabulatedHumanTissues...
    .MaterialParameters.Tissue_names;
SPR.TabulatedHumanTissues.SPR_Theoretical=Compute_theoretical_SPR(E_kin,...
    Data_TabulatedHumanTissues.MaterialParameters.Density,...
    Data_TabulatedHumanTissues.wi,Data_Elements.Zi,Data_Elements.Ai,...
    Data_Elements.Ii,Data_water,true);

%% Perform fit to find energy spectrum parameters, needed for CT number estimation:

%Create struct to save data:
K_values=struct;

%Loop over the three different sets of CT numbers:
CTnumber_types={'Head','Body','Average'};
for i=1:length(CTnumber_types)
    K_values.(CTnumber_types{i})=fit_K_values(CTnumbers.Phantom...
        .(['CTnumbers_',CTnumber_types{i}]),Data_Phantom.wi,Data_Elements.Zi,...
        Data_Elements.Ai,Data_Phantom.MaterialParameters.Density,...
        Data_water);
end

%% Calculate the estimated CT numbers the tabulated human tissues:

%Create table to store the data:
CTnumbers.TabulatedHumanTissues=table;
CTnumbers.TabulatedHumanTissues.Tissue_names=Data_TabulatedHumanTissues...
    .MaterialParameters.Tissue_names;

%Loop over the CT number types, and estimate the CT numbers for the
%tabulated human tissues for each of the types:
for i=1:length(CTnumber_types)
    CTnumbers.TabulatedHumanTissues.(['CTnumbers_',CTnumber_types{i},...
        '_estimated'])=Calculate_estimated_CTnumbers(K_values.(CTnumber_types{i}),...
        Data_TabulatedHumanTissues,Data_Elements,Data_water);
end

%% Calibrate the stoichiometric method:

if isnan(SPR.Phantom.SPR_Measured)
    disp(['Calibration is based on theoretical SPR values, since no ',...
        'measured SPR values are provided'])
    SPR.SPR_type='SPR_Theoretical';
else
    disp('Calibration is based on measured SPR values')
    SPR.SPR_type='SPR_Measured';
end

%Create struct to save data for the generated HLUTs:
HLUTs=struct;
HLUTs.ConnectionPoints=struct;
HLUTs.Specification=struct;

%Create struct to save results:
Data_Results=struct;
Data_Results.Output_Folder_Name=Output_Folder_Name;
Data_Results.FileNames_HLUT_Figures=struct;

%Perform HLUT fitting:
for i=1:length(CTnumber_types)
    [HLUTs,Data_Results]=calibrate_HLUT(E_kin,CTnumber_types{i},CTnumbers,...
        SPR,Data_Phantom,Data_TabulatedHumanTissues,Data_water,HLUTs,...
        Data_Results);
end
clear i

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Perform evalution procedure:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Evaluation boxes to check the individual steps in the HLUT generation
%procedure:

%Evaluation box 1: CT number dependence on the phantom size:
Data_Results=Test_CTnumber_Size_Dependency(CTnumbers,Data_Results);

%Evaluation box 2: Tissue equivalency:
Data_Results=Test_phantom_tissue_equivalency(Data_Phantom,Data_Elements,...
    Data_TabulatedHumanTissues,Data_water,Data_Results);

%Evaluation box 3: Check of estimated CT numbers:
Data_Results=Test_CTnumber_estimation_accuracy(CTnumbers,K_values,...
    Data_Phantom,Data_Elements,Data_water,Data_Results);

%Evaluation box 4: Comparison of measured and theoretical SPR values:
if strcmp(SPR.SPR_type,'SPR_Measured')
    Data_Results=Test_SPR_measured_vs_theoretical(SPR,Data_Results);
end

%Evaluation box 5: Check if one or several HLUTs are needed:
Data_Results=Test_HLUT_averagecurve_vs_sizedependentcurves(SPR,CTnumbers,...
    CTnumber_types,HLUTs,Data_Results);

%End-to-end testing:

%Evaluation of the  HLUT accuracy:
[Data_Results,SPR]=Test_HLUT_accuracy(SPR,CTnumbers,Data_Phantom,...
    Data_TabulatedHumanTissues,HLUTs,Data_Results);

%Evaluation of the position dependency of the CT numbers:
Data_Results=Test_CTnumber_Position_Dependency(CTnumbers,Data_Results);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Create PDF report with the results:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if PDF_generator_exist
    try
        Create_PDF_report(Data_Results,CTnumber_types,File_name,SPR.SPR_type,...
            Output_Folder_Name,matlab_version)
    catch ME
        disp('No PDF report could be generated')
        %Print error statement:
        rethrow(ME)
    end
end

%% End of file
