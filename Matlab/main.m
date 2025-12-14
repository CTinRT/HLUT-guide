clear; close all; clc;
format compact; format shortG;

%{ 
HLUT calibration and evaluation code, Copyright (c) 2025, CT-in-RT working group.

This software (any code and/or associated documentation: the "Software")
is distributed under the terms of the MIT license (the "License").
Refer to the License for more details. You should have received a copy of
the License along with the code. If not, see
https://choosealicense.com/licenses/mit/.
SPDX-License-Identifier: MIT

PLEASE NOTE THAT THIS SOFTWARE IS NOT PUBLISHED AS (AN ACCESSORY TO) A MEDICAL DEVICE!
Read the README file for more details.
%}
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Welcome:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
This is the main file for the HLUT calibration and evalaution. This code
follows the guide described in DOI:
https://doi.org/10.1016/j.radonc.2023.109675

The code imports the measured CT numbers, as specified in the input Excel
file (note, the Excel should be closed before running this Matlab code).
Then the code calibrates the HLUT and plots the results, followed by an 
evaluation of the generated HLUTs. Lastly, a PDF file containing all the
results is generated.
%}
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Define parameters:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define Excel file with CT numbers:
% Input folder name:
% EXAMPLE:
%   Option 1 - one input: Input_Folder_Name='Input_folder';
%   Option 2 - multiple inputs: Input_Folder_Name={'Input_folder','Input_folder'};
Input_Folder_Name='Input_folder';

% File name of Excel file with CT numbers and phantom data:
% EXAMPLE:
%   Option 1 - one input: File_name='DataForCTCalibration_GammexAEDphantom_Siemens_goOpenPro_120kVp.xlsx';
%   Option 2 - multiple inputs: File_name={'DataForCTCalibration_GammexAEDphantom_Siemens_goOpenPro_120kVp.xlsx',...
%                                           'DataForCTCalibration_GammexAEDphantom_GE_Revolution_120kVp.xlsx'};
File_name='DataForCTCalibration_GammexAEDphantom_Siemens_goOpenPro_120kVp.xlsx';

% Define the wanted output:
% OPTIONS: 
% 1) 'MD' (photons only)
% 2) 'RED' (photons only)
% 3) 'SPR' (protons only)
% NOTE: 
% If MD is chosen, a direct MD-HLUT is obtained - this is NOT recommended 
% for protons (see explaination in the guide).
% EXAMPLE:
%   Option 1 - one input: output_parameter='SPR';
%   Option 2 - multiple inputs: output_parameter={'MD','RED'};
output_parameter='SPR';

% recon_type - reconstruction type:
% Indicate which type of HLUTs should be created. 
% OPTIONS: 
% 1) 'regular' - HLUTs for regular CT number reconstructions
% 2) 'DD'      - HLUTs for DirectDensity reconstructions
% EXAMPLE:
%   Option 1 - one input: recon_type='regular';
%   Option 2 - multiple inputs: recon_type={'regular','regular'};
recon_type='regular';

% Folder name to save the results to:
% EXAMPLE:
%   Option 1 - one input: Output_Folder_Name='Results';
%   Option 2 - multiple inputs: Output_Folder_Name={'Results','Results'};
Output_Folder_Name='Results';

% Initial energy of proton beam (MeV) - can be list.
% This value is only is only needed for SPR, but for the code to run smooth,
% don't delete this even if a MD or RED HLUT is needed, then this parameter
% is just ignored.
% EXAMPLE:
%   Option 1 - one input: E_kin=100;
%   Option 2 - multiple inputs: E_kin={100,100};
E_kin=100;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Run script:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Starting the HLUT code')

% Define folder where additional Matlab files are stored, and add folder to
% search path:
Folder_additional_scripts='Utils';
addpath(Folder_additional_scripts)

%Check input parameters:
input_parameters=check_parameters(Input_Folder_Name,File_name,...
    output_parameter,recon_type,Output_Folder_Name,Folder_additional_scripts,...
    E_kin);

clear Folder_additional_scripts Input_Folder_Name

%Generate and evaluate the HLUTs:
Results=hlut_generation_and_evaluation(input_parameters);

disp('HLUT code has succesfully finished')

%% End of file