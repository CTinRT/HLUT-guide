function varargout=calibrate_HLUT(E_kin,CTnumber_type,CTnumbers,SPR,Data_Phantom,...
        Data_TabulatedHumanTissues,Data_water,HLUTs,Data_Results)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% In this file, the Hounsfield look-up table (HLUT) is calibrated. The HLUT
% is also plotted and the connection points are written to a txt file and 
% and a csv file (which can be directly loaded into newer versions of 
% RayStation).
% Both the figure and the files are saved to the Results folder. 
% Both the connection points between the individual line segments and the 
% slopes of the individual line segments are saved to the struct HLUTs,
% which is the output of this function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Divide the data points into the four tissue groups:

CTnumbers_all=[CTnumbers.Phantom.(['CTnumbers_',CTnumber_type]);...
    CTnumbers.TabulatedHumanTissues.(['CTnumbers_',CTnumber_type,'_estimated'])];
SPR_all=[SPR.Phantom.(SPR.SPR_type);SPR.TabulatedHumanTissues.SPR_Theoretical];
TissueGroupIndex_all=[Data_Phantom.MaterialParameters.TissueGroupIndex;...
    Data_TabulatedHumanTissues.MaterialParameters.TissueGroupIndex];

CTnumbers_Lung=CTnumbers_all(TissueGroupIndex_all==1);
CTnumbers_Fat=CTnumbers_all(TissueGroupIndex_all==2);
CTnumbers_Soft=CTnumbers_all(TissueGroupIndex_all==3);
CTnumbers_Bone=CTnumbers_all(TissueGroupIndex_all==4);

SPR_Lung=SPR_all(TissueGroupIndex_all==1);
SPR_Fat=SPR_all(TissueGroupIndex_all==2);
SPR_Soft=SPR_all(TissueGroupIndex_all==3);
SPR_Bone=SPR_all(TissueGroupIndex_all==4);

%% Make fits for each of the four tissue groups:

%Fit the lung and soft tissues together:
p_LungSoft=polyfit([CTnumbers_Lung;CTnumbers_Soft],[SPR_Lung;SPR_Soft],1);
if p_LungSoft(1)<=0
    error(['The slope for the lung+soft tissue curve is negative. This ',...
        'should not happen. Check the input files for the phantom inserts ',...
        'and tabulated human tissues.'])
end

p_Fat=polyfit(CTnumbers_Fat,SPR_Fat,1);
if p_Fat(1)<=0
    error(['The slope for the adipose tissue curve is negative. This ',...
        'should not happen. Check the input files for the phantom inserts ',...
        'and tabulated human tissues.'])
end

p_Bone=polyfit(CTnumbers_Bone,SPR_Bone,1);
if p_Bone(1)<=0
    error(['The slope for the bone tissue curve is negative. This ',...
        'should not happen. Check the input files for the phantom inserts ',...
        'and tabulated human tissues.'])
end

%% Define (preliminary) connection points, following Table S1.4:

%Air to lung:
CTnumbers_kinks_AirToLung=[-999;-950];

%Lung to Fat:
CTnumbers_kinks_LungToFat=[round(min(CTnumbers_Fat)-60);round(min(CTnumbers_Fat)-40)];

%Fat to Soft:
CTnumbers_kinks_FatToSoft=[-30;0];

%Soft to Bone:
CTnumbers_kinks_SoftToBone=[round(max(CTnumbers_Soft)+10);round(min(CTnumbers_Bone)+50)];
%Check the CT numbers of the first connection points is lower than the
%second:
if CTnumbers_kinks_SoftToBone(2)<CTnumbers_kinks_SoftToBone(1)
    error(['This should not happen. Please check the input data. The connection ',...
        'points defined in this guide works for the data listed in Table S1.3. ',...
        'If other data is used, the definition of the connection points might ',...
        'need to be redefined.'])
end

%% Calculate SPR for air:

%Data for air from NIST: https://physics.nist.gov/cgi-bin/Star/compos.pl?matno=104
Density_air=1.20479E-03;
I_air=85.7;
Zi_air=[6;7;8;18];
Ai_air=[12.011;14.007;15.999;39.948];
wi_air=[0.000124,0.755267,0.231781,0.012827];

SPR_air=Compute_theoretical_SPR(E_kin,Density_air,wi_air,Zi_air,Ai_air,...
    I_air,Data_water,false);

%% Calculate SPR for the connection points, applying the fits:

%Air to lung:
SPR_kinks_AirToLung=[SPR_air;polyval(p_LungSoft,CTnumbers_kinks_AirToLung(2))];
%Lung to Fat:
SPR_kinks_LungToFat=[polyval(p_LungSoft,CTnumbers_kinks_LungToFat(1));...
    polyval(p_Fat,CTnumbers_kinks_LungToFat(2))];
%Fat to Soft:
SPR_kinks_FatToSoft=[polyval(p_Fat,CTnumbers_kinks_FatToSoft(1));...
    polyval(p_LungSoft,CTnumbers_kinks_FatToSoft(2))];
%Soft to Bone:
SPR_kinks_SoftToBone=[polyval(p_LungSoft,CTnumbers_kinks_SoftToBone(1));...
    polyval(p_Bone,CTnumbers_kinks_SoftToBone(2))];

%% Fit connection lines and check that the slopes are non-negative:

%Define a minimum SPR difference, to ensure non-negative slopes:
SPR_diff_min=1e-4;

%Air to lung:
if SPR_kinks_AirToLung(2)-SPR_kinks_AirToLung(1)<=SPR_diff_min
    %Increase the CT number for the upper connection point to ensure a
    %non-negative slope:
    CTnumbers_kinks_AirToLung(2)=ceil((SPR_kinks_AirToLung(1)+SPR_diff_min-...
        p_LungSoft(2))/p_LungSoft(1));
    %Make sure that this CT number is not too high, since this could mean
    %that the lung curve is too steep:
    if CTnumbers_kinks_AirToLung(2)>-900
        error(['It seems that the lung curve is too steep and therefore have ',...
            'too many negative SPR values'])
        %Check this parameter: SPR_Lung_est
    end
    %Find the corresponding SPR:
    SPR_kinks_AirToLung(2)=p_LungSoft(1)*CTnumbers_kinks_AirToLung(2)+...
        p_LungSoft(2);
end
p_AirToLung=polyfit(CTnumbers_kinks_AirToLung,SPR_kinks_AirToLung,1);

%Lung to Fat:
if SPR_kinks_LungToFat(2)-SPR_kinks_LungToFat(1)<=SPR_diff_min
    %Increase the CT number for the upper connection point to ensure a
    %non-negative slope:
    tmp=CTnumbers_kinks_LungToFat(2);
    CTnumbers_kinks_LungToFat(2)=ceil((SPR_kinks_LungToFat(1)+SPR_diff_min-...
        p_Fat(2))/p_Fat(1));
    %Check that the CT number did not change too much, as this could mean
    %that the input data is not good:
    if abs(tmp-CTnumbers_kinks_LungToFat(2))>10
        error(['This should not happen. Please check the phantom inserts ',...
            'and tabulated human tissues.'])
    end
    %Find the corresponding SPR:
    SPR_kinks_LungToFat(2)=p_Fat(1)*CTnumbers_kinks_LungToFat(2)+p_Fat(2);
end
p_LungToFat=polyfit(CTnumbers_kinks_LungToFat,SPR_kinks_LungToFat,1);

%Fat to Soft:
if SPR_kinks_FatToSoft(2)-SPR_kinks_FatToSoft(1)<=SPR_diff_min
    %Decrease the CT number for the lower connection point to ensure a
    %non-negative slope:
    CTnumbers_kinks_FatToSoft(1)=floor((SPR_kinks_FatToSoft(2)-SPR_diff_min-...
        p_Fat(2))/p_Fat(1));
    %Find the corresponding SPR:
    SPR_kinks_FatToSoft(1)=p_Fat(1)*CTnumbers_kinks_FatToSoft(1)+p_Fat(2);
end
p_FatToSoft=polyfit(CTnumbers_kinks_FatToSoft,SPR_kinks_FatToSoft,1);

%Soft to Bone:
if SPR_kinks_SoftToBone(2)-SPR_kinks_SoftToBone(1)<=SPR_diff_min
    %Increase the CT number for the upper connection point to ensure a
    %non-negative slope:
    CTnumbers_kinks_SoftToBone(2)=ceil((SPR_kinks_SoftToBone(1)+SPR_diff_min-...
        p_Bone(2))/p_Bone(1));
end
p_SoftToBone=polyfit(CTnumbers_kinks_SoftToBone,SPR_kinks_SoftToBone,1);

%% Estimate the SPR values for the different tissue regions for plotting:

CTnumbers_air_plot=[-1024,CTnumbers_kinks_AirToLung(1)];
CTnumbers_Lung_plot=[CTnumbers_kinks_AirToLung(2),CTnumbers_kinks_LungToFat(1)];
CTnumbers_Fat_plot=[CTnumbers_kinks_LungToFat(2),CTnumbers_kinks_FatToSoft(1)];
CTnumbers_Soft_plot=[CTnumbers_kinks_FatToSoft(2),CTnumbers_kinks_SoftToBone(1)];
CTnumbers_Bone_plot=[CTnumbers_kinks_SoftToBone(2),2000];

SPR_air_plot=[SPR_air,SPR_air];
SPR_Lung_plot=polyval(p_LungSoft,CTnumbers_Lung_plot);
SPR_Fat_plot=polyval(p_Fat,CTnumbers_Fat_plot);
SPR_Soft_plot=polyval(p_LungSoft,CTnumbers_Soft_plot);
SPR_Bone_plot=polyval(p_Bone,CTnumbers_Bone_plot);

%% Define colors:

C_lung=[0.929,0.694,0.125];
C_fat=[0.85,0.5,0.098];
C_soft=[0.466,0.674,0.4];
C_bone=[0.3,0.55,0.9];

%% Plot:

x_length=780;
y_length=420;
figure('Position',[680,558,x_length,y_length]); hold on

marker_symbol='.';
marker_size=15;

%Plot data points (phantom inserts and tabulated human tissues):
plot(CTnumbers_Lung,SPR_Lung,marker_symbol,'Color',C_lung,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_lung)
plot(CTnumbers_Fat,SPR_Fat,marker_symbol,'Color',C_fat,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_fat)
plot(CTnumbers_Soft,SPR_Soft,marker_symbol,'Color',C_soft,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_soft)
plot(CTnumbers_Bone,SPR_Bone,marker_symbol,'Color',C_bone,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_bone)

%Plot fitted lines:
plot(CTnumbers_Lung_plot,SPR_Lung_plot,'Color',C_lung,'LineWidth',1.5)
plot(CTnumbers_Lung_plot,SPR_Lung_plot,'--','Color',C_soft,'LineWidth',1.5)
plot(CTnumbers_Fat_plot,SPR_Fat_plot,'Color',C_fat,'LineWidth',1.5)
plot(CTnumbers_Soft_plot,SPR_Soft_plot,'Color',C_lung,'LineWidth',1.5)
plot(CTnumbers_Soft_plot,SPR_Soft_plot,'--','Color',C_soft,'LineWidth',1.5)
plot(CTnumbers_Bone_plot,SPR_Bone_plot,'Color',C_bone,'LineWidth',1.5)

%Flat line, fixed at the SPR for air:
plot(CTnumbers_air_plot,SPR_air_plot,'-.k','LineWidth',0.5)

%Plot connection lines:
%Air to lung:
plot(CTnumbers_kinks_AirToLung,SPR_kinks_AirToLung,'-.k','LineWidth',0.5)
%Lung to Fat:
plot(CTnumbers_kinks_LungToFat,SPR_kinks_LungToFat,'-.k','LineWidth',0.5)
%Fat to Soft:
plot(CTnumbers_kinks_FatToSoft,SPR_kinks_FatToSoft,'-.k','LineWidth',0.5)
%Soft to Bone:
plot(CTnumbers_kinks_SoftToBone,SPR_kinks_SoftToBone,'-.k','LineWidth',0.5)

xlabel('CT numbers (HU)','FontSize',14)
ylabel('Stopping-power ratio','FontSize',14)

if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
    FigureTitle=['HLUT for ',CTnumber_type,' phantom'];
elseif strcmp(CTnumber_type,'Average')
    FigureTitle='HLUT for average CT numbers';
end
title(FigureTitle)

x_max=max([1600,ceil(max(CTnumbers_all)/100)*100]);
xlim([-1024,x_max])
y_max=max([1.8,ceil(max(SPR_all)*10)/10]);
ylim([0,y_max])
set(gca,'FontSize',12,'YTick',0:0.2:2,'XTick',-1000:250:3500,...
    'Position',[0.08,0.13,0.91,0.8],'YGrid','on')
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.1f'))
box on

%Legend:
%Box around the text:
annotation('rectangle',[0.105,0.69,0.29,0.205],'FaceColor','w')
%Lung + Soft:
annotation('ellipse',[0.115,0.856,0.015*y_length/x_length,0.015],'Color',C_lung,'FaceColor',C_lung)
annotation('ellipse',[0.131,0.856,0.015*y_length/x_length,0.015],'Color',C_soft,'FaceColor',C_soft)
annotation('line',[0.147,0.193],[0.863,0.863],'Color',C_lung,'LineWidth',1.75)
annotation('line',[0.147,0.193],[0.863,0.863],'Color',C_soft,'LineWidth',1.75,'LineStyle','--')
annotation('textbox',[0.193,0.797,0.1,0.1],'String','Lung + Soft tissues',...
    'FontSize',12,'EdgeColor','none','FitBoxToText','on')
%Fat:
annotation('ellipse',[0.123,0.81,0.015*y_length/x_length,0.015],'Color',C_fat,'FaceColor',C_fat)
annotation('line',[0.147,0.193],[0.816,0.816],'Color',C_fat,'LineWidth',1.75)
annotation('textbox',[0.193,0.75,0.1,0.1],'String','Adipose tissues',...
    'FontSize',12,'EdgeColor','none','FitBoxToText','on')
%Bone:
annotation('ellipse',[0.123,0.764,0.015*y_length/x_length,0.015],'Color',C_bone,'FaceColor',C_bone)
annotation('line',[0.147,0.193],[0.77,0.77],'Color',C_bone,'LineWidth',1.75)
annotation('textbox',[0.193,0.704,0.1,0.1],'String','Bone tissues',...
    'FontSize',12,'EdgeColor','none','FitBoxToText','on')
%Connection lines:
annotation('line',[0.147,0.193],[0.722,0.722],'LineWidth',1.25,'LineStyle','-.')
annotation('textbox',[0.193,0.658,0.1,0.1],'String','Connection lines',...
    'FontSize',12,'EdgeColor','none','FitBoxToText','on')

%Figure insert for the fat and soft tissue region:
axes('Position',[0.52,0.2,0.44,0.32])
hold on
box on
%Plot data points (phantom inserts and tabulated human tissues):
plot(CTnumbers_Fat,SPR_Fat,marker_symbol,'Color',C_fat,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_fat)
plot(CTnumbers_Soft,SPR_Soft,marker_symbol,'Color',C_soft,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_soft)
plot(CTnumbers_Bone,SPR_Bone,marker_symbol,'Color',C_bone,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_bone)
%Plot fitted lines:
plot(CTnumbers_Fat_plot,SPR_Fat_plot,'Color',C_fat,'LineWidth',1.5);
plot(CTnumbers_Soft_plot,SPR_Soft_plot,'Color',C_lung,'LineWidth',1.5);
plot(CTnumbers_Soft_plot,SPR_Soft_plot,'--','Color',C_soft,'LineWidth',1.5);
%Plot connection line:
plot(CTnumbers_kinks_LungToFat,SPR_kinks_LungToFat,'-.k','LineWidth',0.5)
plot(CTnumbers_kinks_FatToSoft,SPR_kinks_FatToSoft,'-.k','LineWidth',0.5)
plot(CTnumbers_kinks_SoftToBone,SPR_kinks_SoftToBone,'-.k','LineWidth',0.5)
text(-115,1.11,'Adipose and soft tissue region','FontSize',12.5)
xlim([-120,130])
ylim([0.925,1.1])
set(gca,'FontSize',12,'YGrid','on')
a=gca;
a.XRuler.TickLabelGapOffset=-2;
a.YRuler.TickLabelGapOffset=-2;
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.2f'))

%% Save figure:

if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
    FileName=['HLUT_',CTnumber_type,'_phantom.png'];
elseif strcmp(CTnumber_type,'Average')
    FileName='HLUT_Averaged_CTnumbers.png';
end
Data_Results.FileNames_HLUT_Figures.(CTnumber_type)=[Data_Results.Output_Folder_Name,...
    filesep,FileName];

saveas(gcf,Data_Results.FileNames_HLUT_Figures.(CTnumber_type))

%% Save kink points:

%Set the endpoint of the curve. As discuss in the Supplementary material,
%several suggestions exist for how to extend the HLUT beyond the highest
%datapoint. Here a simple extrapolation will be used, and the endpoint will
%arbitrarily be set to 2000 HU. Note, this is NOT the end of the curve, and
%the curve needs to be continued beyond this point.
CTnumber_max=2000;
%Ensure that this CT number is higher than the highest datapoint used to
%fit the curve:
if max(CTnumbers_all)>CTnumber_max
    CTnumber_max=max(CTnumbers_all)+100;
end
SPR_max=polyval(p_Bone,CTnumber_max);

CTnumber_kinks=[CTnumbers_air_plot(1);CTnumbers_kinks_AirToLung;CTnumbers_kinks_LungToFat;...
    CTnumbers_kinks_FatToSoft;CTnumbers_kinks_SoftToBone;CTnumber_max];

SPR_kinks=[SPR_air;SPR_kinks_AirToLung;SPR_kinks_LungToFat;...
    SPR_kinks_FatToSoft;SPR_kinks_SoftToBone;SPR_max];

connectionpoints=[CTnumber_kinks,SPR_kinks];
HLUT_specification=[[0,SPR_air;0,SPR_air];p_AirToLung;p_LungSoft;...
    p_LungToFat;p_Fat;p_FatToSoft;p_LungSoft;p_SoftToBone;p_Bone];

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Save the calibration data:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Print the inter-connection points to a text file and a csv file:

%File names:
if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
    filename_csv=[Data_Results.Output_Folder_Name,filesep,...
        'HLUT_',CTnumber_type,'_phantom.csv'];
    filename_txt=[Data_Results.Output_Folder_Name,filesep,...
        'HLUT_',CTnumber_type,'_phantom.txt'];
elseif strcmp(CTnumber_type,'Average')
    filename_csv=[Data_Results.Output_Folder_Name,filesep,...
        'HLUT_Averaged_CTnumbers.csv'];
    filename_txt=[Data_Results.Output_Folder_Name,filesep,...
        'HLUT_Averaged_CTnumbers.txt']; 
end

%Write to csv file, without table headings:
%RayStation cannot handle CT numbers below -1000 HU, so change the first
%connect point:
connectionpoints_RS=connectionpoints;
connectionpoints_RS(1,1)=-1000;
writematrix([connectionpoints_RS(:,1),round(connectionpoints_RS(:,2),4)],...
    filename_csv,'Delimiter','comma')

%Write to txt file, with table headings:
fileID_output=fopen(filename_txt,'w');
fprintf(fileID_output,'#HLUT inter-connection points:\r\n\r\n');
fprintf(fileID_output,'#CT number (HU)   SPR\r\n');
for i=1:length(connectionpoints)
    fprintf(fileID_output,'%9.f %13.4f\r\n',connectionpoints(i,1),...
        connectionpoints(i,2));
end
fclose(fileID_output);

%% Write data to Command Window as a table (to have headings):

%Format the table:
t1=cell(size(connectionpoints));
for i=1:length(connectionpoints)
    t1{i,1}=str2double(num2str(connectionpoints(i,1),'%.0f'));
    t1{i,2}=str2double(num2str(connectionpoints(i,2),'%.4f'));
end
HLUT_connectionpoints=cell2table(t1);


if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
    disp(' '),disp(['HLUT calibration for <strong>',CTnumber_type,' phantom</strong>:'])
elseif strcmp(CTnumber_type,'Average')
    disp(' '),disp('HLUT calibration based on <strong>averaged CT numbers</strong>:')
end

%Insert table headings:
HLUT_connectionpoints.Properties.VariableNames={'CT number (HU)','SPR'};

%Write out the connection points:
disp(HLUT_connectionpoints)

%% Save the data:

%Connection points:
HLUTs.ConnectionPoints.(CTnumber_type)=array2table(connectionpoints);
%Insert table headings:
HLUTs.ConnectionPoints.(CTnumber_type).Properties.VariableNames=...
    {'CTnumber','SPR'};

%Slopes and intercepts of each line segment:
HLUTs.Specification.(CTnumber_type)=array2table(HLUT_specification);
%Insert table headings:
HLUTs.Specification.(CTnumber_type).Properties.VariableNames=...
    {'Slope','Intercept'};

%Connection points (fewer decimal points):
Data_Results.ConnectionPoints.(CTnumber_type)=HLUT_connectionpoints;

%% Define output from this function:

varargout={HLUTs,Data_Results};

%% End of file
end