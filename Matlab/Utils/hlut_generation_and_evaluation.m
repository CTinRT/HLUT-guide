function Results=hlut_generation_and_evaluation(input_parameters)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function runs the main part of the code to generate and evaluate the 
% HLUT.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Start the HLUT code:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results=struct();

%Loop over the input parameters (potentially only one):
for i=1:input_parameters.N_loop
    
    disp(['Running HLUT number ',num2str(i),'/',num2str(input_parameters.N_loop),':'])

    Results.(['HLUT_',num2str(i)])=struct;
    Input_Folder_Name=input_parameters.Input_Folder_Name_all{i};
    File_name=input_parameters.File_name_all{i}; 
    output_parameter=input_parameters.output_parameter_all{i};
    recon_type=input_parameters.recon_type_all{i};
    Output_Folder_Name=input_parameters.Output_Folder_Name_all{i};
    E_kin=input_parameters.E_kin_all{i};

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %      Initialize the data:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Load data from input Excel file:
    [Output_Folder_Name,CTnumbers,Output,Data_Phantom,...
        Data_TabulatedHumanTissues,Data_Elements,Data_water_air]=...
        initialize_data(Output_Folder_Name,output_parameter,...
        input_parameters.matlab_version,Input_Folder_Name,...
        File_name,E_kin);

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %       Fit and estimate CT numbers:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Perform fit for CT number estimation, and calculate estimated CT numbers:

    CTnumber_types={'Head','Body','Average'};

    CTnumbers=fit_and_estimate_CTnumbers(CTnumbers,Data_Phantom,Data_Elements,...
        Data_water_air,recon_type,Data_TabulatedHumanTissues,CTnumber_types);

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %      Fit and plot the HLUTs:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Calibrate the HLUTs:

    %Create struct to save data for the generated HLUTs:
    HLUTs=struct;
    HLUTs.ConnectionPoints=struct;
    HLUTs.Specification=struct;

    %Create struct to save results:
    Data_Results=struct;
    Data_Results.Output_Folder_Name=Output_Folder_Name;
    Data_Results.FileNames_HLUT_Figures=struct;

    %Perform HLUT fitting:
    for j=1:length(CTnumber_types)
        [HLUTs,Data_Results]=calibrate_HLUT(output_parameter,CTnumber_types{j},...
            CTnumbers,Output,Data_Phantom,Data_TabulatedHumanTissues,...
            Data_water_air,HLUTs,Data_Results,recon_type);
    end
    clear j

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %       Perform evalution procedure:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Evaluation boxes to check the individual steps in the HLUT generation
    %procedure:

    %Evaluation box 1: CT number dependence on the phantom size:
    Data_Results=Test_CTnumber_Size_Dependency(CTnumbers,Data_Results);

    %Evaluation box 2: Tissue equivalency:
    Data_Results=Test_phantom_tissue_equivalency(Data_Phantom,...
        Data_TabulatedHumanTissues,Data_Results,output_parameter);

    %Evaluation box 3: Check of estimated CT numbers:
    Data_Results=Test_CTnumber_estimation_accuracy(CTnumbers,Data_Results);

    %Evaluation box 4: Comparison of measured and theoretical SPR values:
    if strcmp(output_parameter,'SPR') && strcmp(Output.SPR_type,'SPR_Measured')
        Data_Results=Test_SPR_measured_vs_theoretical(Output,Data_Results);
    end

    %Evaluation box 5: Check if one or several HLUTs are needed:
    Data_Results=Test_HLUT_averagecurve_vs_sizedependentcurves(Output,CTnumbers,...
        CTnumber_types,HLUTs,Data_Results,recon_type);

    %End-to-end testing:

    %Evaluation of the  HLUT accuracy:
    [Data_Results,Output]=Test_HLUT_accuracy(Output,CTnumbers,Data_Phantom,...
        Data_TabulatedHumanTissues,HLUTs,Data_Results);

    %Evaluation of the position dependency of the CT numbers:
    Data_Results=Test_CTnumber_Position_Dependency(CTnumbers,HLUTs,...
        Data_Results,Output);

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %       Create PDF report with the results:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if input_parameters.PDF_generator_exist
        try
            Create_PDF_report(Data_Results,CTnumber_types,File_name,Output,...
                Output_Folder_Name,input_parameters.matlab_version,recon_type)
        catch ME
            disp('No PDF report could be generated')
            %Print error statement:
            rethrow(ME)
        end
    end
    
    %% Define output:

    Results.(['HLUT_',num2str(i)]).File_name=File_name;
    Results.(['HLUT_',num2str(i)]).output_parameter=output_parameter;
    Results.(['HLUT_',num2str(i)]).HLUTs=HLUTs;
    Results.(['HLUT_',num2str(i)]).Data_Results=Data_Results;

    %Intermediate data:
    Results.(['HLUT_',num2str(i)]).CTnumbers=CTnumbers;
    if strcmp(output_parameter,'MD')
        Output.Phantom.Properties.VariableNames{'Output'}='Reference MD';
        Output.TabulatedHumanTissues.Properties.VariableNames{'Output'}='Reference MD';
        MD_Data=Output;
        Results.(['HLUT_',num2str(i)]).MD_Data=MD_Data;
    elseif strcmp(output_parameter,'RED')
        Output.Phantom.Properties.VariableNames{'Output'}='Reference RED';
        Output.TabulatedHumanTissues.Properties.VariableNames{'Output'}='Reference RED';
        RED_Data=Output;
        Results.(['HLUT_',num2str(i)]).RED_Data=RED_Data;
    elseif strcmp(output_parameter,'SPR')
        Output.Phantom.Properties.VariableNames{'Output'}='Reference SPR';
        Output.TabulatedHumanTissues.Properties.VariableNames{'Output'}='Reference SPR';
        SPR_Data=Output;
        Results.(['HLUT_',num2str(i)]).SPR_Data=SPR_Data;
    end

end



%% End of file