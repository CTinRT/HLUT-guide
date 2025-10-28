function input_parameters=check_parameters(Input_Folder_Name,File_name,...
    output_parameter,recon_type,Output_Folder_Name,...
    Folder_additional_scripts,E_kin)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function checks the input data.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Check the lengths of the input parameters:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%All input parameters should either be single-valued or be a list (cell) of
%the same length.

%Make lists out of all input parameters:
if ischar(Input_Folder_Name), Input_Folder_Name_all={Input_Folder_Name}; 
elseif iscell(Input_Folder_Name), Input_Folder_Name_all=Input_Folder_Name; 
else, error('Input parameter ''Input_Folder_Name'' should be a single string or a cell {} of strings') 
end
if ischar(File_name), File_name_all={File_name}; 
elseif iscell(File_name), File_name_all=File_name; 
else, error('Input parameter ''File_name'' should be a single string or a cell {} of strings') 
end
if ischar(output_parameter), output_parameter_all={output_parameter}; 
elseif iscell(output_parameter), output_parameter_all=output_parameter; 
else, error('Input parameter ''output_parameter'' should be a single string or a cell {} of strings') 
end
if ischar(recon_type), recon_type_all={recon_type}; 
elseif iscell(recon_type), recon_type_all=recon_type; 
else, error('Input parameter ''recon_type'' should be a single string or a cell {} of strings') 
end
if ischar(Output_Folder_Name), Output_Folder_Name_all={Output_Folder_Name}; 
elseif iscell(Output_Folder_Name), Output_Folder_Name_all=Output_Folder_Name; 
else, error('Input parameter ''Output_Folder_Name'' should be a single string or a cell {} of strings') 
end
if isnumeric(E_kin), E_kin_all={E_kin}; 
elseif iscell(E_kin), E_kin_all=E_kin; 
else, error('Input parameter ''E_kin'' should be a single numerical value or a cell {} of numerical values') 
end

%Count the number of values for each input parameter:
N_Input_Folders=length(Input_Folder_Name_all);
N_filename=length(File_name_all);
N_output_parameter=length(output_parameter_all);
N_recon_type=length(recon_type_all);
N_Output_Folders=length(Output_Folder_Name_all);
N_E_kin=length(E_kin_all);
input_param_numbers=[N_Input_Folders,N_filename,N_output_parameter,...
    N_recon_type,N_Output_Folders,N_E_kin];

%Check that input parameters which can take sevaral values are either
%single-valued or all have the same length:
if all(input_param_numbers==1)
    N_loop=1;
elseif any(input_param_numbers>1)
    more_values=input_param_numbers>1;
    N_values=input_param_numbers(more_values);
    Uniq_values=unique(N_values);
    if length(Uniq_values)==1
        N_loop=Uniq_values;
        %Extend the lists which only have one value by replicating the value:
        for i=1:length(input_param_numbers)
            if ~more_values(i)
                if i==1, Input_Folder_Name_all=repmat(Input_Folder_Name_all,1,N_loop);
                elseif i==2, File_name_all=repmat(File_name_all,1,N_loop);
                elseif i==3, output_parameter_all=repmat(output_parameter_all,1,N_loop);
                elseif i==4, recon_type_all=repmat(recon_type_all,1,N_loop);
                elseif i==5, Output_Folder_Name_all=repmat(Output_Folder_Name_all,1,N_loop);
                elseif i==6, E_kin_all=repmat(E_kin_all,1,N_loop);
                else, error('Some code change has been incorrectly implemented?!')
                end
            end
        end
    else
        error(['The input parameters ''File_name'', ''output_parameter'', ',...
        '''recon_type'', and  ''Ekin'' need all to be either one value, or ',...
        'only one of them be a list with more values, or all be lists with ',...
        'the same length! Please check these input parameters.'])
    end
    
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Check if valid parameters have been chosen:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Check if a valid output parameter has been chosen:
for i=1:N_loop
    if ~any(strcmp(output_parameter_all{i},{'MD','RED','SPR'}))
        error(['The chosen output parameter is not valid! The three options',...
            ' are MD, RED, or SPR.'])
    end
end

%Check if a recon_type parameter has been chosen:
for i=1:N_loop
    if ~any(strcmp(recon_type_all{i},{'regular', 'DD'}))
        error(['The chosen recon_type parameter is not valid! The two options',...
            ' are regular, or DD.'])
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Add subfolders:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Check that only one folder is stated with additional scripts:
if ~ischar(Folder_additional_scripts) && length(Folder_additional_scripts)~=1
    error('Only one folder with additional code functions can be stated!')
end

%Add subfolders with additional scripts:
dir_list=dir(Folder_additional_scripts);
Additional_folders={dir_list([dir_list.isdir]).name};
Additional_folders=Additional_folders(~ismember(Additional_folders,{'.','..'}));
for i=1:length(Additional_folders)
    addpath([Folder_additional_scripts,filesep,Additional_folders{i}])
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Check Matlab version:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Matlab version:
matlab_version=version('-release');

if str2double(matlab_version(1:4))<2019
    error(['We are sorry, but the script is not guaranteed to run on ',...
        'older versions than 2019. Some functionality might still work, ',...
        'but some code changes will be most likely be needed.'])
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

%% Define output from this function:

input_parameters=struct;
input_parameters.N_loop=N_loop;
input_parameters.Input_Folder_Name_all=Input_Folder_Name_all;
input_parameters.File_name_all=File_name_all;
input_parameters.output_parameter_all=output_parameter_all;
input_parameters.recon_type_all=recon_type_all;
input_parameters.Output_Folder_Name_all=Output_Folder_Name_all;
input_parameters.E_kin_all=E_kin_all;
input_parameters.matlab_version=matlab_version;
input_parameters.PDF_generator_exist=PDF_generator_exist;

end