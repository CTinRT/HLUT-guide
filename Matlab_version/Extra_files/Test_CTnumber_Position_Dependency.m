function Data_Results=Test_CTnumber_Position_Dependency(CTnumbers,Data_Results)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Table S1.5: Influence of insert location on CT number for bone phantom
% inserts:
% This function evaluates the CT number dependence on the insert position.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute the insert position dependency:

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

disp(' '),disp('CT number position dependency:')
disp(Data_Results.CTnumber_SizeDependency)

end