function Data_Results=Test_SPR_measured_vs_theoretical(SPR,Data_Results)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Evaluation box 4: Consistency check of SPR determined experimentally:
% This function compare the measured SPR and the theoretical SPR for the
% phantom inserts. These ought to be similar.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compare the measured and the theoretical SPR for the phantom inserts:

%Compute the deviations between the measured and theoretical SPR values:
Diff_SPR=SPR.Phantom.SPR_Measured-SPR.Phantom.SPR_Theoretical;

%Mean absolute error (in percentage relative to SPR of water):
MAE=mean(abs(Diff_SPR*100));

%RMSE (in percentage relative to SPR of water):
RMSE=sqrt(sum((Diff_SPR*100).^2/length(Diff_SPR)));

%% Create tables with the results:

%Table 1: SPR deviations - formatted table:
t1=cell(length(Diff_SPR),5);
for i=1:length(Diff_SPR)
    t1{i,1}=SPR.Phantom.Insert_names{i};
    t1{i,2}=str2double(num2str(SPR.Phantom.SPR_Measured(i),'%.3f'));
    t1{i,3}=str2double(num2str(SPR.Phantom.SPR_Theoretical(i),'%.3f'));
    t1{i,4}=str2double(num2str(Diff_SPR(i),'%.3f'));
    t1{i,5}=str2double(num2str(Diff_SPR(i)*100,'%.3f'));
end
Data_Results.SPR_measured_vs_theoretical=struct;
Data_Results.SPR_measured_vs_theoretical.Deviations=cell2table(t1);
%Insert table headings:
Data_Results.SPR_measured_vs_theoretical.Deviations.Properties.VariableNames=...
    {'Insert name','Meas SPR','Theo SPR','Meas - Theo','Meas - Theo (%)'};

%Table 2: Accuracy - formatted table:
MAE_formatted=str2double(num2str(MAE,'%.2f'));
RMSE_formatted=str2double(num2str(RMSE,'%.2f'));
Data_Results.SPR_measured_vs_theoretical.Accuracy=table(MAE_formatted,RMSE_formatted);
%Insert table headings:
Data_Results.SPR_measured_vs_theoretical.Accuracy.Properties.VariableNames=...
        {'Mean absolute error (%)','RMSE (%)'};

% %Output results to command window (Remove % in front of the three following lines, if output is wanted):
% disp(' '),disp('Comparison of the measured and the theoretical SPRs for the phantom inserts:')
% disp(Data_Results.SPR_measured_vs_theoretical.Deviations)
% disp(Data_Results.SPR_measured_vs_theoretical.Accuracy)

%% Create figure with barplots for the results:

%Define colors:
C=[0,0.447,0.741];

figure('Position',[100,100,860,520],'Visible','off'), hold on
bar(1:length(Diff_SPR),Diff_SPR*100,0.35,'FaceColor',C)

box on
ylabel(['\DeltaSPR = SPR_m_e_a_s ',char(8210),' SPR_t_h_e_o (%)'],'FontSize',14)
title('Comparison measured vs theoretical SPR')

set(gca,'FontSize',12,'xtick',1:length(Diff_SPR),'XTickLabel',...
    SPR.Phantom.Insert_names)
xlim([0.3,length(Diff_SPR)+0.7])

a=gca;
a.XRuler.TickLabelGapOffset=-2;

%% Save the figure:

FileName='Eval_Box_4_SPR_measured_vs_theoretical.png';

Data_Results.SPR_measured_vs_theoretical.FileName=[Data_Results.Output_Folder_Name,...
    filesep,FileName];

saveas(gcf,Data_Results.SPR_measured_vs_theoretical.FileName)

close(gcf)

end