function Data_Results=Test_CTnumber_estimation_accuracy(CTnumbers,K_values,...
    Data_Phantom,Data_Elements,Data_water,Data_Results)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Evaluation box 3: Check of estimated CT numbers:
% This function evaluates the accuracy of the CT estimation method, by
% computing the estimated CT numbers for the phantom inserts (which was
% also used to fit the estimation method), and compare these to the actual
% measured CT numbers for the phantom inserts.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimate the CT numbers for the phantom inserts and compute the accuracy:

CTnumber_types={'Head','Body'};
Data_Results.CTnumber_estimation_accuracy=struct;

for i=1:length(CTnumber_types)
    %Estimate the CT numbers for the phantom inserts:
    CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i},'_estimated'])=...
        Calculate_estimated_CTnumbers(K_values.(CTnumber_types{i}),...
        Data_Phantom,Data_Elements,Data_water);
    
    %Compute the deviations to the measured CT numbers:
    Diff_CTnumbers=CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i}])-...
        CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i},'_estimated']);
    
    %Save data for plotting:
    if i==1
        Dev_head=Diff_CTnumbers;
    elseif i==2
        Dev_body=Diff_CTnumbers;
    end

    %% Create tables with the results:
    
    %Table 1: CT number deviations - formatted table:
    Data_Results.CTnumber_estimation_accuracy.([CTnumber_types{i},'_phantom'])=struct;
    Deviations=table(CTnumbers.Phantom.Insert_names,...
        int16(CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i}])),...
        int16(CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i},'_estimated'])),...
        int16(Diff_CTnumbers));
    %Insert table headings:
    Deviations.Properties.VariableNames={'Insert name','Meas CTN (HU)',...
        'Est CTN (HU)','Diff=Meas-Est (HU)'};
    Data_Results.CTnumber_estimation_accuracy.([CTnumber_types{i},'_phantom'])...
        .Deviations=Deviations;
    
    %Output results:
    disp(' '),disp(['Results for the accuracy of the estimated CT numbers for <strong>',...
        CTnumber_types{i},' phantom</strong>:'])
    disp(Deviations)
    
end

%% Create figure with barplots for the results:

%Define colors:
C_head=[0,0.447,0.741];
C_body=[0,0.61,0];

figure('Position',[680,558,860,420]), hold on
bar(1-0.2:length(Dev_head)-0.2,Dev_head,0.35,'FaceColor',C_head)
bar(1+0.2:length(Dev_body)+0.2,Dev_body,0.35,'FaceColor',C_body)

box on
ylabel(['\DeltaH = H_m_e_a_s ',char(8210),' H_e_s_t (HU)'],'FontSize',14)
title('Check of estimated CT numbers')
hl=legend('Head phantom','Body phantom','Location','eastoutside');
hl.FontSize=12;
set(gca,'FontSize',12,'xtick',1:length(Dev_head),'XTickLabel',...
    CTnumbers.Phantom.Insert_names,'XTickLabelRotation',45)
xlim([0.3,length(Dev_head)+0.7])

a=gca;
a.XRuler.TickLabelGapOffset=-2;


%% Save the figure:

FileName='Eval_Box_3_CTnumber_estimation_accuracy.png';

Data_Results.CTnumber_estimation_accuracy.FileName=...
    [Data_Results.Output_Folder_Name,filesep,FileName];

saveas(gcf,Data_Results.CTnumber_estimation_accuracy.FileName)

end