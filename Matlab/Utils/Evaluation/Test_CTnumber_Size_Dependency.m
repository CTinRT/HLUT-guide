function Data_Results=Test_CTnumber_Size_Dependency(CTnumbers,Data_Results)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Evaluation box 1: Size-dependent impact of beam hardening on CT numbers:
% This function evaluates the CT number dependence on the phantom size.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute the phantom size dependency:

%Compute the differences between the CT numbers for the Head and the Body
%phantom:
diff_CTnumbers=CTnumbers.Phantom.CTnumbers_Head-CTnumbers.Phantom.CTnumbers_Body;

%% Create tables with the results:

%Format the table:
Data_Results.CTnumber_SizeDependency=table(CTnumbers.Phantom.Insert_names,...
    int16(CTnumbers.Phantom.CTnumbers_Head),int16(CTnumbers.Phantom.CTnumbers_Body),...
    int16(diff_CTnumbers));

%Insert table headings:
Data_Results.CTnumber_SizeDependency.Properties.VariableNames={'Insert name',...
    'CTN Head (HU)','CTN Body (HU)','Diff=Head-Body (HU)'};

% %Output results to command window (Remove % in front of the two following lines, if output is wanted):
% disp(' '),disp('CT number size dependency:')
% disp(Data_Results.CTnumber_SizeDependency)

end