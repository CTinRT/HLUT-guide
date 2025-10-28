function Data_Results=Test_HLUT_averagecurve_vs_sizedependentcurves(Output,...
    CTnumbers,CTnumber_types,HLUTs,Data_Results,recon_type)

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

figure('Position',[100,100,860,420],'Visible','off'), hold on

%Plot HLUTs:
for i=1:length(CTnumber_types)
    plot(HLUTs.ConnectionPoints.(CTnumber_types{i}).CTnumber,...
        HLUTs.ConnectionPoints.(CTnumber_types{i}).(Output.Variable),...
        'Color',Colors_all(i,:))
end

%Plot data points:
for i=1:length(CTnumber_types)-1
    if strcmp(Output.Variable,'MD')
        plot(CTnumbers.TabulatedHumanTissues.(['CTnumbers_',CTnumber_types{i},'_estimated']),...
            Output.TabulatedHumanTissues.Output,...
            '.','Color',Colors_all(i,:),'MarkerSize',marker_size)
    else
        plot([CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i}]);...
            CTnumbers.TabulatedHumanTissues.(['CTnumbers_',CTnumber_types{i},'_estimated'])],...
            [Output.Phantom.Output;Output.TabulatedHumanTissues.Output],...
            '.','Color',Colors_all(i,:),'MarkerSize',marker_size)
    end
end

%Find the CT number for the second most dense phantom insert, and round it up:
sortHead=sort(CTnumbers.Phantom.CTnumbers_Head);
sortBody=sort(CTnumbers.Phantom.CTnumbers_Body);
CTN_bone=ceil(max([sortHead(end-1);sortBody(end-1)])/100)*100;
if CTN_bone-50<=max([sortHead(end-1);sortBody(end-1)])
    CTN_bone=CTN_bone+100;
end

%Compute Output values at CTN_bone:
Output_CTNbone_Head=interp1(HLUTs.ConnectionPoints.Head.CTnumber,...
    HLUTs.ConnectionPoints.Head.(Output.Variable),CTN_bone);
Output_CTNbone_Body=interp1(HLUTs.ConnectionPoints.Body.CTnumber,...
    HLUTs.ConnectionPoints.Body.(Output.Variable),CTN_bone);
Output_CTNbone_Average=interp1(HLUTs.ConnectionPoints.Average.CTnumber,...
    HLUTs.ConnectionPoints.Average.(Output.Variable),CTN_bone);
Output_CTNbone_min=min([interp1(HLUTs.ConnectionPoints.Head.CTnumber,...
    HLUTs.ConnectionPoints.Head.(Output.Variable),CTN_bone-50);...
    interp1(HLUTs.ConnectionPoints.Body.CTnumber,...
    HLUTs.ConnectionPoints.Body.(Output.Variable),CTN_bone-50)]);
Output_CTNbone_max=max([interp1(HLUTs.ConnectionPoints.Head.CTnumber,...
    HLUTs.ConnectionPoints.Head.(Output.Variable),CTN_bone+50);...
    interp1(HLUTs.ConnectionPoints.Body.CTnumber,...
    HLUTs.ConnectionPoints.Body.(Output.Variable),CTN_bone+50)]);

%Plot box around the region shown in the insert:
lcolor=[0.75,0.75,0.75];
rectangle('Position',[CTN_bone-50,Output_CTNbone_min,100,...
    Output_CTNbone_max-Output_CTNbone_min],'EdgeColor',lcolor,'LineStyle','-.')
line([CTN_bone,CTN_bone],[Output_CTNbone_min,0.5],'Color',lcolor,'LineStyle','-.')

%x-axis limits - max CT number:
max_CTnumber=ceil(max([CTnumbers.Phantom.CTnumbers_Head;CTnumbers.Phantom.CTnumbers_Body;...
    CTnumbers.TabulatedHumanTissues.CTnumbers_Head_estimated;...
    CTnumbers.TabulatedHumanTissues.CTnumbers_Body_estimated])/100)*100;
xlim([-1024,max_CTnumber])

%y-axis limits:
max_output_Head=interp1(HLUTs.ConnectionPoints.Head.CTnumber,...
    HLUTs.ConnectionPoints.Head.(Output.Variable),max_CTnumber);
max_output_Body=interp1(HLUTs.ConnectionPoints.Body.CTnumber,...
    HLUTs.ConnectionPoints.Body.(Output.Variable),max_CTnumber);
max_output=ceil(max(max_output_Body,max_output_Head)*10)/10;
ylim([0,max_output])

set(gca,'FontSize',12,'YTick',0:0.2:max_output,'XTick',-2000:250:max_CTnumber,...
    'XTickLabelRotation',0)
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.1f'))
box on

if strcmp(recon_type,'regular')
    xlabel('CT numbers (HU)')
elseif strcmp(recon_type,'DD')
    xlabel('DD CT numbers (HU)')
end
if strcmp(Output.Variable,'MD')
    ylabel('Mass density (g/cm^3)','FontSize',14)
elseif strcmp(Output.Variable,'RED')
    ylabel('Relative electron density','FontSize',14)
elseif strcmp(Output.Variable,'SPR')
    ylabel('Stopping-power ratio','FontSize',14)
end
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
        HLUTs.ConnectionPoints.(CTnumber_types{i}).(Output.Variable),...
        'Color',Colors_all(i,:))
end

xlim([CTN_bone-50,CTN_bone+50])
if abs(Output_CTNbone_Body-Output_CTNbone_Head)<0.05
    ylim([Output_CTNbone_Average-0.025,Output_CTNbone_Average+0.025])
end
set(gca,'FontSize',12,'XTick',CTN_bone-40:20:CTN_bone+40,...
    'XTickLabelRotation',0)
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.2f'))
a=gca;
a.XRuler.TickLabelGapOffset=-2;
a.YRuler.TickLabelGapOffset=-1;
Ylim=get(gca,'YLim');
text(CTN_bone+15,Ylim(2)+diff(Ylim)*0.1,'Bone region','FontSize',14)

%Plot vertical line at CTN_bone:
plot([CTN_bone,CTN_bone],[Output_CTNbone_Head,Output_CTNbone_Average],...
    'Color',Colors_all(1,:),'LineWidth',1.5)
plot([CTN_bone,CTN_bone],[Output_CTNbone_Body,Output_CTNbone_Average],...
    'Color',Colors_all(2,:),'LineWidth',1.5)
%Plot horizontal line at the output value at CTN_bone:
plot([CTN_bone-5,CTN_bone+5],[Output_CTNbone_Head,Output_CTNbone_Head],...
    'Color',Colors_all(1,:),'LineWidth',1.5)
plot([CTN_bone-5,CTN_bone+5],[Output_CTNbone_Body,Output_CTNbone_Body],...
    'Color',Colors_all(2,:),'LineWidth',1.5)
plot([CTN_bone-5,CTN_bone+5],[Output_CTNbone_Average,Output_CTNbone_Average],...
    'k','LineWidth',1.5)
%Deviations:
deltaY_Head=(Output_CTNbone_Head-Output_CTNbone_Average);
deltaY_Body=(Output_CTNbone_Body-Output_CTNbone_Average);
if deltaY_Head<-1e-1 && deltaY_Body<-1e-1 || deltaY_Head>1e-1 && deltaY_Body>1e-1
    error(['This should not be able to happen, since this means that the HLUT ',...
        'for the averaged CT numbers is wrong'])
end
deltaH_opt=0;
if deltaY_Head<0 && abs(deltaY_Head)>Output_CTNbone_Head-Ylim(1)
    text(CTN_bone+3,Output_CTNbone_Head+abs(deltaY_Head)/2,...
        ['\Delta',Output.Variable,' = ',num2str(deltaY_Head*100,'%.1f'),'%'],...
        'Color',Colors_all(1,:),'FontSize',12)
    deltaH_opt=1;
elseif deltaY_Head<0 && abs(deltaY_Head)<Output_CTNbone_Head-Ylim(1)
    text(CTN_bone+3,Output_CTNbone_Head-(Output_CTNbone_Head-Ylim(1))/2,...
        ['\Delta',Output.Variable,' = ',num2str(deltaY_Head*100,'%.1f'),'%'],...
        'Color',Colors_all(1,:),'FontSize',12)
    deltaH_opt=1;
elseif deltaY_Head>0 && deltaY_Head>Ylim(2)-Output_CTNbone_Head
    text(CTN_bone+3,Output_CTNbone_Average+deltaY_Head/2,...
        ['\Delta',Output.Variable,' = +',num2str(deltaY_Head*100,'%.1f'),'%'],...
        'Color',Colors_all(1,:),'FontSize',12)
    deltaH_opt=2;
elseif deltaY_Head>0 && deltaY_Head<Ylim(2)-Output_CTNbone_Head
    text(CTN_bone+3,Output_CTNbone_Head+(Ylim(2)-Output_CTNbone_Head)/2,...
        ['\Delta',Output.Variable,' = +',num2str(deltaY_Head*100,'%.1f'),'%'],...
        'Color',Colors_all(1,:),'FontSize',12)
    deltaH_opt=2;
end
deltaB_opt=0;
if deltaY_Body<0 && abs(deltaY_Body)>Output_CTNbone_Body-Ylim(1)
    text(CTN_bone+3,Output_CTNbone_Body+abs(deltaY_Body)/2,...
        ['\Delta',Output.Variable,' = ',num2str(deltaY_Body*100,'%.1f'),'%'],...
        'Color',Colors_all(2,:),'FontSize',12)
    deltaB_opt=1;
elseif deltaY_Body<0 && abs(deltaY_Body)<Output_CTNbone_Body-Ylim(1)
    text(CTN_bone+3,Output_CTNbone_Body-(Output_CTNbone_Body-Ylim(1))/2,...
        ['\Delta',Output.Variable,' = ',num2str(deltaY_Body*100,'%.1f'),'%'],...
        'Color',Colors_all(2,:),'FontSize',12)
    deltaB_opt=1;
elseif deltaY_Body>0 && deltaY_Body>Ylim(2)-Output_CTNbone_Body
    text(CTN_bone+3,Output_CTNbone_Average+deltaY_Body/2,...
        ['\Delta',Output.Variable,' = +',num2str(deltaY_Body*100,'%.1f'),'%'],...
        'Color',Colors_all(2,:),'FontSize',12)
    deltaB_opt=2;
elseif deltaY_Body>0 && deltaY_Body<Ylim(2)-Output_CTNbone_Body
    text(CTN_bone-13,Output_CTNbone_Body+(Ylim(2)-Output_CTNbone_Body)/2,...
        ['\Delta',Output.Variable,' = +',num2str(deltaY_Body*100,'%.1f'),'%'],...
        'Color',Colors_all(2,:),'FontSize',12)
    deltaB_opt=2;
end
if deltaY_Head==0 && deltaY_Body==0
    text(CTN_bone+3,Output_CTNbone_Head+0.009,['\Delta',Output.Variable,' = 0.0%'],...
        'Color',Colors_all(1,:),'FontSize',12)
    text(CTN_bone+3,Output_CTNbone_Body-0.009,['\Delta',Output.Variable,' = 0.0%'],...
        'Color',Colors_all(2,:),'FontSize',12)
elseif deltaY_Head==0 && deltaB_opt==1
     text(CTN_bone+3,Output_CTNbone_Head+(Ylim(2)-Output_CTNbone_Head)/2,...
        ['\Delta',Output.Variable,' = 0.0%'],'Color',Colors_all(1,:),'FontSize',12)
elseif deltaY_Head==0 && deltaB_opt==2
     text(CTN_bone+3,Output_CTNbone_Head-(Output_CTNbone_Head-Ylim(1))/2,...
        ['\Delta',Output.Variable,' = 0.0%'],'Color',Colors_all(1,:),'FontSize',12)
elseif deltaY_Body==0 && deltaH_opt==1
    text(CTN_bone+3,Output_CTNbone_Body+(Ylim(2)-Output_CTNbone_Body)/2,...
        ['\Delta',Output.Variable,' = 0.0%'],'Color',Colors_all(2,:),'FontSize',12)
elseif deltaY_Body==0 && deltaH_opt==2
     text(CTN_bone-13,Output_CTNbone_Body-(Output_CTNbone_Body-Ylim(1))/2,...
        ['\Delta',Output.Variable,' = 0.0%'],'Color',Colors_all(2,:),'FontSize',12)
end

%Save figure:
Data_Results.FileNames_HLUT_Test_Average=struct;
Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency=...
    [Data_Results.Output_Folder_Name,filesep,'HLUT_size_dependency.png'];
saveas(gcf,Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency)

close(gcf)

%% Deviations between body-size dependent HLUTs and HLUT for averaged CT numbers:

%Compute HLUT-based Output value, and the difference between the body-size  
%dependent HLUTs and HLUT for averaged CT numbers (in percentage):
CTnumbers_all=-1024:max_CTnumber;
Output_est_Head=interp1(HLUTs.ConnectionPoints.Head.CTnumber,...
    HLUTs.ConnectionPoints.Head.(Output.Variable),CTnumbers_all);
Output_est_Body=interp1(HLUTs.ConnectionPoints.Body.CTnumber,...
    HLUTs.ConnectionPoints.Body.(Output.Variable),CTnumbers_all);
Output_est_Average=interp1(HLUTs.ConnectionPoints.Average.CTnumber,...
    HLUTs.ConnectionPoints.Average.(Output.Variable),CTnumbers_all);
diff_Head_Average=(Output_est_Head-Output_est_Average)*100;
diff_Body_Average=(Output_est_Body-Output_est_Average)*100;

figure('Position',[100,100,860,400],'Visible','off'), hold on
%Plot line at deviations of 0%:
plot([-1024,max_CTnumber],[0,0],'k')
%Set y-axis limit:
ymin=floor(min([diff_Head_Average,diff_Body_Average])*10)/10;
ymax=ceil(max([diff_Head_Average,diff_Body_Average])*10)/10;
ylim([ymin,ymax])
%Plot vertical line at CTN_bone:
plot([CTN_bone,CTN_bone],[ymin,ymax],'Color',lcolor,'LineStyle','-.')
%Plot the difference:
h1=plot(CTnumbers_all,diff_Head_Average,'Color',Colors_all(1,:),'LineWidth',1);
h2=plot(CTnumbers_all,diff_Body_Average,'Color',Colors_all(2,:),'LineWidth',1);

xlim([-1024,max_CTnumber])

box on
set(gca,'FontSize',12,'XTick',-2000:250:max_CTnumber)
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.1f'))
if strcmp(recon_type,'regular')
    xlabel('CT numbers (HU)')
elseif strcmp(recon_type,'DD')
    xlabel('DD CT numbers (HU)')
end
ylabel(['\Delta',Output.Variable,' (%)'])
title(['Difference of HLUTs: size-specific ',char(8210),' averaged CT numbers'])

legend([h1,h2],'HLUT Head - HLUT average','HLUT Body - HLUT average')

%Save figure:
Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency_deviations=...
    [Data_Results.Output_Folder_Name,filesep,'Eval_Box_5_HLUT_size_dependency_deviations.png'];
saveas(gcf,Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency_deviations)

close(gcf)

end