function Data_Results=Test_CTnumber_Position_Dependency(CTnumbers,HLUTs,...
    Data_Results,Output)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Table S1.5: Influence of insert location on CT number for bone phantom
% inserts:
% This function evaluates the CT number dependence on the insert position.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute the CT number dependency on insert position:

%Find the inserts for which the CT numbers were measured at more positions
%in the Body phantom:
index_eval=~isnan(CTnumbers.Phantom.CTnumbers_Evaluation);

%Compute the differences between the CT numbers for the insert placed in
%the middle of the Bodt=y phantom (as used for calibration) and the insert 
%placed in the periphery of the Body phantom:
diff_CTnumbers=CTnumbers.Phantom.CTnumbers_Body(index_eval)-...
    CTnumbers.Phantom.CTnumbers_Evaluation(index_eval);

%% Create tables with the results:

%Format the table:
Data_Results.CTnumber_PositionDependency=table(CTnumbers.Phantom.Insert_names(index_eval),...
    int16(CTnumbers.Phantom.CTnumbers_Body(index_eval)),...
    int16(CTnumbers.Phantom.CTnumbers_Evaluation(index_eval)),...
    int16(diff_CTnumbers));

%Insert table headings:
Data_Results.CTnumber_PositionDependency.Properties.VariableNames={'Insert name',...
    'CTN Middle (HU)','CTN Outer (HU)','Diff=Middle-Outer (HU)'};

% %Output results to command window (Remove % in front of the two following lines, if output is wanted):
% disp(' '),disp('CT number position dependency:')
% disp(Data_Results.CTnumber_PositionDependency)

%% Compute the parameter estimation accuracy for insert in center and periphery:

ref_value=Output.Phantom.Output(index_eval);
par_bone_center=interp1(HLUTs.ConnectionPoints.('Body').CTnumber,...
        HLUTs.ConnectionPoints.('Body').(Output.Variable),...
        CTnumbers.Phantom.('CTnumbers_Body')(index_eval));
par_bone_peri=interp1(HLUTs.ConnectionPoints.('Body').CTnumber,...
        HLUTs.ConnectionPoints.('Body').(Output.Variable),...
        CTnumbers.Phantom.('CTnumbers_Evaluation')(index_eval));

%% Create tables with the results:

%Format the table:
Data_Results.Parameter_PositionDependency=table(CTnumbers.Phantom.Insert_names(index_eval),...
    round(ref_value,3),...
    round(par_bone_center, 3),...
    round((par_bone_center-ref_value)*100, 2),...
    round(par_bone_peri, 3),...
    round((par_bone_peri-ref_value)*100, 2));

%Insert table headings:
Data_Results.Parameter_PositionDependency.Properties.VariableNames={'Insert name',...
    ['Reference ',Output.Variable],['Est. ',Output.Variable,' middle'],...
    'Dev. middle (%)',['Est. ',Output.Variable,' outer'],'Dev. outer (%)'};

% %Output results to command window (Remove % in front of the two following lines, if output is wanted):
% disp(' '),disp('Parameter estimation accuracy position dependency:')
% disp(Data_Results.Parameter_PositionDependency)

end