function Data_Results=Test_HLUT_averagecurve_vs_sizedependentcurves(SPR,...
    CTnumbers,CTnumber_types,HLUTs,Data_Results)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Evaluation box 5: Visual HLUT evaluation and assessment of 
% body-region-specific HLUTs
% In this function, figures will be created to compare the HLUT based on
% the average CT numbers (from the head- and body-sized phantom), with the
% HLUT made for the head and body separately.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot the comparison to the HLUT based on the averaged CT numbers:

%Define colors:
Colors_all=[0,0.447,0.741;0,0.61,0;0,0,0];

marker_size=15;

figure('Position',[680,558,860,440]),hold on

%Plot HLUTs:
for i=1:length(CTnumber_types)
    plot(HLUTs.ConnectionPoints.(CTnumber_types{i}).CTnumber,...
        HLUTs.ConnectionPoints.(CTnumber_types{i}).SPR,'Color',Colors_all(i,:))
end

%Plot data points:
for i=1:length(CTnumber_types)-1
    plot([CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i}]);...
        CTnumbers.TabulatedHumanTissues.(['CTnumbers_',CTnumber_types{i},'_estimated'])],...
        [SPR.Phantom.(SPR.SPR_type);SPR.TabulatedHumanTissues.SPR_Theoretical],...
        '.','Color',Colors_all(i,:),'MarkerSize',marker_size)
end

%Compute SPR at 1000 HU:
SPR_1000HU_Head=interp1(HLUTs.ConnectionPoints.Head.CTnumber,...
    HLUTs.ConnectionPoints.Head.SPR,1000);
SPR_1000HU_Body=interp1(HLUTs.ConnectionPoints.Body.CTnumber,...
    HLUTs.ConnectionPoints.Body.SPR,1000);
SPR_1000HU_Average=interp1(HLUTs.ConnectionPoints.Average.CTnumber,...
    HLUTs.ConnectionPoints.Average.SPR,1000);

%Plot box around the region shown in the insert:
lcolor=[0.75,0.75,0.75];
rectangle('Position',[950,SPR_1000HU_Average-0.04,100,0.08],...
    'EdgeColor',lcolor,'LineStyle','-.')
line([1000,1000],[SPR_1000HU_Average-0.04,1.15],'Color',lcolor,'LineStyle','-.')
line([1000,370],[1.15,0.83],'Color',lcolor,'LineStyle','-.')
line([1000,1600],[1.15,0.83],'Color',lcolor,'LineStyle','-.')

xlim([-1024,1700])
ylim([0,1.8])
set(gca,'FontSize',12,'YTick',0:0.2:2,'XTick',-2000:250:2000)
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.1f'))
box on

xlabel('CT numbers (HU)')
ylabel('Stopping-power ratio','FontSize',14)
title('Size-specific HLUT vs HLUT from averaged CT numbers')

%Legend - make fake lines to make more readable legend:
h1=plot([-5000,-6000],[-10,-10],'Color',Colors_all(1,:),'LineWidth',1.5);
h2=plot([-5000,-6000],[-10,-10],'Color',Colors_all(2,:),'LineWidth',1.5);
h3=plot([-5000,-6000],[-10,-10],'Color',Colors_all(3,:),'LineWidth',1.5);
hl=legend([h1,h2,h3],'HLUT for Head phantom','HLUT for Body phantom',...
    'HLUT for averaged CT numbers','Location','northwest');
hl.FontSize=12;

%Figure inset for the bone region:
axes('Position',[0.525,0.19,0.35,0.3])
hold on
box on
%Plot HLUTs:
for i=1:length(CTnumber_types)
    plot(HLUTs.ConnectionPoints.(CTnumber_types{i}).CTnumber,...
        HLUTs.ConnectionPoints.(CTnumber_types{i}).SPR,'Color',Colors_all(i,:))
end
%Plot vertical line at 1000 HU:
plot([1000,1000],[SPR_1000HU_Head,SPR_1000HU_Average],'Color',Colors_all(1,:),'LineWidth',1.5)
plot([1000,1000],[SPR_1000HU_Body,SPR_1000HU_Average],'Color',Colors_all(2,:),'LineWidth',1.5)
%Plot horizontal line at SPR at 1000 HU:
plot([995,1005],[SPR_1000HU_Head,SPR_1000HU_Head],'Color',Colors_all(1,:),'LineWidth',1.5)
plot([995,1005],[SPR_1000HU_Body,SPR_1000HU_Body],'Color',Colors_all(2,:),'LineWidth',1.5)
plot([995,1005],[SPR_1000HU_Average,SPR_1000HU_Average],'k','LineWidth',1.5)
deltaSPR_Head=(SPR_1000HU_Head-SPR_1000HU_Average)*100;
deltaSPR_Body=(SPR_1000HU_Body-SPR_1000HU_Average)*100;
if deltaSPR_Head<0 && deltaSPR_Body<0 || deltaSPR_Head<0 && deltaSPR_Body<0
    error(['This should not be able to happen, since this means that the HLUT ',...
        'for the averaged CT numbers is wrong'])
end
if deltaSPR_Head<0
    text(990,SPR_1000HU_Head-0.009,['\DeltaSPR = ',num2str(deltaSPR_Head,'%.1f'),'%'],...
        'Color',Colors_all(1,:),'FontSize',12)
else
    text(970,SPR_1000HU_Head+0.009,['\DeltaSPR = +',num2str(deltaSPR_Head,'%.1f'),'%'],...
        'Color',Colors_all(1,:),'FontSize',12)
end
if deltaSPR_Body<0
    text(990,SPR_1000HU_Body-0.009,['\DeltaSPR = ',num2str(deltaSPR_Body,'%.1f'),'%'],...
        'Color',Colors_all(2,:),'FontSize',12)
else
    text(970,SPR_1000HU_Body+0.009,['\DeltaSPR = +',num2str(deltaSPR_Body,'%.1f'),'%'],...
        'Color',Colors_all(2,:),'FontSize',12)
end
xlim([950,1050])
ylim([SPR_1000HU_Average-0.025,SPR_1000HU_Average+0.025])
set(gca,'FontSize',12,'XTick',960:20:1200)
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.2f'))
a=gca;
a.XRuler.TickLabelGapOffset=-1.5;
a.YRuler.TickLabelGapOffset=-1;
text(952,SPR_1000HU_Average+0.03,'Bone region','FontSize',14)

%Save figure:
Data_Results.FileNames_HLUT_Test_Average=struct;
Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency=...
    [Data_Results.Output_Folder_Name,filesep,'HLUT_size_dependency.png'];
saveas(gcf,Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency)

%% SPR deviations between body-size dependent HLUTs and HLUT for averaged CT numbers:

%Compute HLUT-based SPR, and the difference between the body-size dependent 
%HLUTs and HLUT for averaged CT numbers (in percentage):
CTnumbers_all=-1024:1700;
SPR_est_Head=interp1(HLUTs.ConnectionPoints.Head.CTnumber,...
    HLUTs.ConnectionPoints.Head.SPR,CTnumbers_all);
SPR_est_Body=interp1(HLUTs.ConnectionPoints.Body.CTnumber,...
    HLUTs.ConnectionPoints.Body.SPR,CTnumbers_all);
SPR_est_Average=interp1(HLUTs.ConnectionPoints.Average.CTnumber,...
    HLUTs.ConnectionPoints.Average.SPR,CTnumbers_all);
SPRdiff_Head_Average=(SPR_est_Head-SPR_est_Average)*100;
SPRdiff_Body_Average=(SPR_est_Body-SPR_est_Average)*100;

figure('Position',[680,558,860,300]), hold on
%Plot line at deviations of 0%:
plot([-2000,3000],[0,0],'k')
%Plot vertical line at 1000 HU:
plot([1000,1000],[-3,3],'Color',lcolor,'LineStyle','-.')
%Plot the SPR difference:
h1=plot(CTnumbers_all,SPRdiff_Head_Average,'Color',Colors_all(1,:),'LineWidth',1);
h2=plot(CTnumbers_all,SPRdiff_Body_Average,'Color',Colors_all(2,:),'LineWidth',1);

xlim([-1024,1700])
%Set y-axis limit:
ymin=floor(min([SPRdiff_Head_Average,SPRdiff_Body_Average])*10)/10;
ymax=ceil(max([SPRdiff_Head_Average,SPRdiff_Body_Average])*10)/10;
ylim([ymin,ymax])
box on
set(gca,'FontSize',12,'XTick',-2000:250:2000)
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.1f'))
xlabel('CT numbers (HU)')
ylabel('\DeltaSPR (%)')
title(['Difference of HLUTs: size-specific ',char(8210),' averaged CT numbers'])

legend([h1,h2],'HLUT Head - HLUT average','HLUT Body - HLUT average')

%Save figure:
Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency_deviations=...
    [Data_Results.Output_Folder_Name,filesep,'Eval_Box_5_HLUT_size_dependency_deviations.png'];
saveas(gcf,Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency_deviations)

end