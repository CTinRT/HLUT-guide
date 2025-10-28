function varargout=calibrate_HLUT(output_parameter,CTnumber_type,CTnumbers,...
    Output,Data_Phantom,Data_TabulatedHumanTissues,Data_water_air,...
    HLUTs,Data_Results,recon_type)

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

CTnumbers_phantom=CTnumbers.Phantom.(['CTnumbers_',CTnumber_type]);
CTnumbers_tiss=CTnumbers.TabulatedHumanTissues.(['CTnumbers_',...
    CTnumber_type,'_estimated']);
Output_phantom=Output.Phantom.Output;
Output_tiss=Output.TabulatedHumanTissues.Output;
TissueGroupIndex_phantom=Data_Phantom.MaterialParameters.TissueGroupIndex;
TissueGroupIndex_tiss=Data_TabulatedHumanTissues.MaterialParameters.TissueGroupIndex;

%Tissue grouping for the tabulated human tissues - to be used for setting
%the initial connection points (the CT number for the lung tissue is not
%used for this, and therefore not included here):
CTnumbers_tiss_Fat=CTnumbers_tiss(TissueGroupIndex_tiss==2);
CTnumbers_tiss_Soft=CTnumbers_tiss(TissueGroupIndex_tiss==3);
CTnumbers_tiss_Bone=CTnumbers_tiss(TissueGroupIndex_tiss==4);

%Combine the data for the phantom inserts and the tabulated human tissues
%for the fitting procedures (except for the MD fit, as this is only based
%on the tabulated human tissues):
if strcmp(output_parameter,'MD')
    %When creating a MD curve, only include the tabulated human tissues,
    %since the phantom inserts are not fully tissue equivalent in terms of
    %the mass density:
    CTnumbers_all=CTnumbers_tiss;
    Output_all=Output_tiss;
    TissueGroupIndex_all=TissueGroupIndex_tiss;
else
    CTnumbers_all=[CTnumbers_phantom;CTnumbers_tiss];
    Output_all=[Output_phantom;Output_tiss];
    TissueGroupIndex_all=[TissueGroupIndex_phantom;TissueGroupIndex_tiss];
end

%Tissue grouping for the combined data:
CTnumbers_Lung=CTnumbers_all(TissueGroupIndex_all==1);
CTnumbers_Fat=CTnumbers_all(TissueGroupIndex_all==2);
CTnumbers_Soft=CTnumbers_all(TissueGroupIndex_all==3);
CTnumbers_Bone=CTnumbers_all(TissueGroupIndex_all==4);

Output_Lung=Output_all(TissueGroupIndex_all==1);
Output_Fat=Output_all(TissueGroupIndex_all==2);
Output_Soft=Output_all(TissueGroupIndex_all==3);
Output_Bone=Output_all(TissueGroupIndex_all==4);

%% Make fits for each of the four tissue groups:

%Fit the lung and soft tissues together:
p_LungSoft=polyfit([CTnumbers_Lung;CTnumbers_Soft],[Output_Lung;Output_Soft],1);
if p_LungSoft(1)<=0
    error(['The slope for the lung+soft tissue curve is negative. This ',...
        'should not happen. Check the input files for the phantom inserts ',...
        'and tabulated human tissues.'])
end

p_Fat=polyfit(CTnumbers_Fat,Output_Fat,1);
if p_Fat(1)<=0
    error(['The slope for the adipose tissue curve is negative. This ',...
        'should not happen. Check the input files for the phantom inserts ',...
        'and tabulated human tissues.'])
end

p_Bone=polyfit(CTnumbers_Bone,Output_Bone,1);
if p_Bone(1)<=0
    error(['The slope for the bone tissue curve is negative. This ',...
        'should not happen. Check the input files for the phantom inserts ',...
        'and tabulated human tissues.'])
end

%% Define (preliminary) connection points, following Table S1.4:

%Following the updated procedures in the HLUT guide for photons (update
%also applicable for protons), the connection points are only defined based
%on the tabulated human tissues, to be robust towards different phantoms.

%Air to lung:
CTnumbers_kinks_AirToLung=[-999;-950];

%Lung to Fat:
CTnumbers_kinks_LungToFat=[round(min(CTnumbers_tiss_Fat)-60);...
    round(min(CTnumbers_tiss_Fat)-40)];

%Fat to Soft:
CTnumbers_kinks_FatToSoft=[-30;0];

%Soft to Bone:
CTnumbers_kinks_SoftToBone=[round(max(CTnumbers_tiss_Soft)+10);...
    round(min(CTnumbers_tiss_Bone)+50)];
%Check the CT numbers of the first connection points is lower than the
%second:
if CTnumbers_kinks_SoftToBone(2)<CTnumbers_kinks_SoftToBone(1)
    error(['This should not happen. Please check the input data. The connection ',...
        'points defined in this guide works for the data listed in Table S1.3. ',...
        'If other data is used, the definition of the connection points might ',...
        'need to be redefined.'])
end

%% Define data for air:

if strcmp(output_parameter,'MD')
    Output_air=Data_water_air.air.Density;
elseif strcmp(output_parameter,'RED')
    Output_air=Data_water_air.air.RED;
elseif strcmp(output_parameter,'SPR')
    Output_air=Data_water_air.air.SPR;
end

%% Calculate output value for the connection points, applying the fits:

%Air to lung:
Output_kinks_AirToLung=[Output_air;polyval(p_LungSoft,CTnumbers_kinks_AirToLung(2))];
%Lung to Fat:
Output_kinks_LungToFat=[polyval(p_LungSoft,CTnumbers_kinks_LungToFat(1));...
    polyval(p_Fat,CTnumbers_kinks_LungToFat(2))];
%Fat to Soft:
Output_kinks_FatToSoft=[polyval(p_Fat,CTnumbers_kinks_FatToSoft(1));...
    polyval(p_LungSoft,CTnumbers_kinks_FatToSoft(2))];
%Soft to Bone:
Output_kinks_SoftToBone=[polyval(p_LungSoft,CTnumbers_kinks_SoftToBone(1));...
    polyval(p_Bone,CTnumbers_kinks_SoftToBone(2))];

%% Fit connection lines and check that the slopes are non-negative:

%Define a minimum difference in the output parameter (MD, RED, SPR), to 
%ensure non-negative slopes:
Output_diff_min=1e-4;

%Air to lung:
if Output_kinks_AirToLung(2)-Output_kinks_AirToLung(1)<=Output_diff_min
    %Increase the CT number for the upper connection point to ensure a
    %non-negative slope:
    CTnumbers_kinks_AirToLung(2)=ceil((Output_kinks_AirToLung(1)+Output_diff_min-...
        p_LungSoft(2))/p_LungSoft(1));
    %Make sure that this CT number is not too high, since this could mean
    %that the lung curve is too steep:
    if CTnumbers_kinks_AirToLung(2)>-900
        error(['It seems that the lung curve is too steep and therefore have ',...
            'too many negative ',output_parameter,' values'])
        %Check this parameter: Output_Lung_est
    end
    %Find the corresponding Output value:
    Output_kinks_AirToLung(2)=p_LungSoft(1)*CTnumbers_kinks_AirToLung(2)+...
        p_LungSoft(2);
end
p_AirToLung=polyfit(CTnumbers_kinks_AirToLung,Output_kinks_AirToLung,1);

%Lung to Fat:
if Output_kinks_LungToFat(2)-Output_kinks_LungToFat(1)<=Output_diff_min
    %Increase the CT number for the upper connection point to ensure a
    %non-negative slope:
    tmp=CTnumbers_kinks_LungToFat(2);
    CTnumbers_kinks_LungToFat(2)=ceil((Output_kinks_LungToFat(1)+Output_diff_min-...
        p_Fat(2))/p_Fat(1));
    %Check that the CT number did not change too much, as this could mean
    %that the input data is not good:
    if abs(tmp-CTnumbers_kinks_LungToFat(2))>10
        error(['This should not happen. Please check the phantom inserts ',...
            'and tabulated human tissues.'])
    end
    %Find the corresponding Output value:
    Output_kinks_LungToFat(2)=p_Fat(1)*CTnumbers_kinks_LungToFat(2)+p_Fat(2);
end
p_LungToFat=polyfit(CTnumbers_kinks_LungToFat,Output_kinks_LungToFat,1);

%Fat to Soft:
if Output_kinks_FatToSoft(2)-Output_kinks_FatToSoft(1)<=Output_diff_min
    %Decrease the CT number for the lower connection point to ensure a
    %non-negative slope:
    CTnumbers_kinks_FatToSoft(1)=floor((Output_kinks_FatToSoft(2)-...
        Output_diff_min-p_Fat(2))/p_Fat(1));
    %Find the corresponding output value:
    Output_kinks_FatToSoft(1)=p_Fat(1)*CTnumbers_kinks_FatToSoft(1)+p_Fat(2);
end
p_FatToSoft=polyfit(CTnumbers_kinks_FatToSoft,Output_kinks_FatToSoft,1);

%Soft to Bone:
if Output_kinks_SoftToBone(2)-Output_kinks_SoftToBone(1)<=Output_diff_min
    %Increase the CT number for the upper connection point to ensure a
    %non-negative slope:
    CTnumbers_kinks_SoftToBone(2)=ceil((Output_kinks_SoftToBone(1)+...
        Output_diff_min-p_Bone(2))/p_Bone(1));
    %Find the corresponding Output value:
    Output_kinks_SoftToBone(2)=p_Bone(1)*CTnumbers_kinks_SoftToBone(2)+p_Bone(2);
end
p_SoftToBone=polyfit(CTnumbers_kinks_SoftToBone,Output_kinks_SoftToBone,1);

%% Find maximum CT number - only to have endpoint for bone curve, not real endpoint:

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
CTnumber_max=ceil(CTnumber_max/100)*100;
Output_max=polyval(p_Bone,CTnumber_max);

%% Estimate the output values for the different tissue regions for plotting:

CTnumbers_air_plot=[-1024,CTnumbers_kinks_AirToLung(1)];
CTnumbers_Lung_plot=[CTnumbers_kinks_AirToLung(2),CTnumbers_kinks_LungToFat(1)];
CTnumbers_Fat_plot=[CTnumbers_kinks_LungToFat(2),CTnumbers_kinks_FatToSoft(1)];
CTnumbers_Soft_plot=[CTnumbers_kinks_FatToSoft(2),CTnumbers_kinks_SoftToBone(1)];
CTnumbers_Bone_plot=[CTnumbers_kinks_SoftToBone(2),CTnumber_max];

Output_air_plot=[Output_air,Output_air];
Output_Lung_plot=polyval(p_LungSoft,CTnumbers_Lung_plot);
Output_Fat_plot=polyval(p_Fat,CTnumbers_Fat_plot);
Output_Soft_plot=polyval(p_LungSoft,CTnumbers_Soft_plot);
Output_Bone_plot=[polyval(p_Bone,CTnumbers_Bone_plot(1)),Output_max];

%% Define colors:

C_lung=[0.929,0.694,0.125];
C_fat=[0.85,0.5,0.098];
C_soft=[0.466,0.674,0.4];
C_bone=[0.3,0.55,0.9];

%% Plot:

x_length=780;
y_length=420;
figure('Position',[100,100,x_length,y_length],'Visible','off'); hold on

marker_symbol='.';
marker_size=15;

%Plot data points (phantom inserts and tabulated human tissues):
plot(CTnumbers_Lung,Output_Lung,marker_symbol,'Color',C_lung,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_lung)
plot(CTnumbers_Fat,Output_Fat,marker_symbol,'Color',C_fat,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_fat)
plot(CTnumbers_Soft,Output_Soft,marker_symbol,'Color',C_soft,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_soft)
plot(CTnumbers_Bone,Output_Bone,marker_symbol,'Color',C_bone,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_bone)

%Plot fitted lines:
plot(CTnumbers_Lung_plot,Output_Lung_plot,'Color',C_lung,'LineWidth',1.5)
plot(CTnumbers_Lung_plot,Output_Lung_plot,'--','Color',C_soft,'LineWidth',1.5)
plot(CTnumbers_Fat_plot,Output_Fat_plot,'Color',C_fat,'LineWidth',1.5)
plot(CTnumbers_Soft_plot,Output_Soft_plot,'Color',C_lung,'LineWidth',1.5)
plot(CTnumbers_Soft_plot,Output_Soft_plot,'--','Color',C_soft,'LineWidth',1.5)
plot(CTnumbers_Bone_plot,Output_Bone_plot,'Color',C_bone,'LineWidth',1.5)

%Flat line, fixed at the output parameter value for air:
plot(CTnumbers_air_plot,Output_air_plot,'-.k','LineWidth',0.5)

%Plot connection lines:
%Air to lung:
plot(CTnumbers_kinks_AirToLung,Output_kinks_AirToLung,'-.k','LineWidth',0.5)
%Lung to Fat:
plot(CTnumbers_kinks_LungToFat,Output_kinks_LungToFat,'-.k','LineWidth',0.5)
%Fat to Soft:
plot(CTnumbers_kinks_FatToSoft,Output_kinks_FatToSoft,'-.k','LineWidth',0.5)
%Soft to Bone:
plot(CTnumbers_kinks_SoftToBone,Output_kinks_SoftToBone,'-.k','LineWidth',0.5)

if strcmp(recon_type,'regular')
    xlabel('CT numbers (HU)','FontSize',14)
elseif strcmp(recon_type,'DD')
    xlabel('DD CT numbers (HU)','FontSize',14)
end
if strcmp(output_parameter,'MD')
    ylabel('Mass density (g/cm^3)','FontSize',14)
    txttmp='MD';
elseif strcmp(output_parameter,'RED')
    ylabel('Relative electron density','FontSize',14)
    txttmp='RED';
elseif strcmp(output_parameter,'SPR')
    ylabel('Stopping-power ratio','FontSize',14)
    txttmp='SPR';
end

if strcmp(recon_type,'regular')
    if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
        FigureTitle=[txttmp,' HLUT for ',CTnumber_type,' phantom'];
    elseif strcmp(CTnumber_type,'Average')
        FigureTitle=[txttmp,' HLUT for CT numbers averaged over Head and Body'];
    end
elseif strcmp(recon_type,'DD')
    if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
        FigureTitle=[txttmp,' HLUT for DirectDensity (DD) CT numbers for ',CTnumber_type,' phantom'];
    elseif strcmp(CTnumber_type,'Average')
        FigureTitle=[txttmp,' HLUT for DirectDensity (DD) CT numbers averaged over Head and Body'];
    end
end
title(FigureTitle)

xlim([-1024,CTnumber_max])
y_max=max([1.8,ceil(Output_max*10)/10]);
ylim([0,y_max])
set(gca,'FontSize',12,'YTick',0:0.2:10,'XTick',-2000:250:10000,...
    'XTickLabelRotation',0,'Position',[0.08,0.13,0.89,0.8],'YGrid','on')
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.1f'))
box on

%Legend:
%Box around the text:
annotation('rectangle',[0.105,0.69,0.29,0.205],'FaceColor','w')
%Lung + Soft:
annotation('ellipse',[0.115,0.856,0.015*y_length/x_length,0.015],'Color',...
    C_lung,'FaceColor',C_lung)
annotation('ellipse',[0.131,0.856,0.015*y_length/x_length,0.015],'Color',...
    C_soft,'FaceColor',C_soft)
annotation('line',[0.147,0.193],[0.863,0.863],'Color',C_lung,'LineWidth',1.75)
annotation('line',[0.147,0.193],[0.863,0.863],'Color',C_soft,'LineWidth',...
    1.75,'LineStyle','--')
annotation('textbox',[0.193,0.797,0.1,0.1],'String','Lung + Soft tissues',...
    'FontSize',12,'EdgeColor','none','FitBoxToText','on')
%Fat:
annotation('ellipse',[0.123,0.81,0.015*y_length/x_length,0.015],'Color',C_fat,...
    'FaceColor',C_fat)
annotation('line',[0.147,0.193],[0.816,0.816],'Color',C_fat,'LineWidth',1.75)
annotation('textbox',[0.193,0.75,0.1,0.1],'String','Adipose tissues',...
    'FontSize',12,'EdgeColor','none','FitBoxToText','on')
%Bone:
annotation('ellipse',[0.123,0.764,0.015*y_length/x_length,0.015],'Color',C_bone,...
    'FaceColor',C_bone)
annotation('line',[0.147,0.193],[0.77,0.77],'Color',C_bone,'LineWidth',1.75)
annotation('textbox',[0.193,0.704,0.1,0.1],'String','Bone tissues',...
    'FontSize',12,'EdgeColor','none','FitBoxToText','on')
%Connection lines:
annotation('line',[0.147,0.193],[0.722,0.722],'LineWidth',1.25,'LineStyle','-.')
annotation('textbox',[0.193,0.658,0.1,0.1],'String','Connection lines',...
    'FontSize',12,'EdgeColor','none','FitBoxToText','on')

%Figure inset for the fat and soft tissue region:
axes('Position',[0.535,0.2,0.43,0.32])
hold on
box on
%Plot data points (phantom inserts and tabulated human tissues):
plot(CTnumbers_Fat,Output_Fat,marker_symbol,'Color',C_fat,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_fat)
plot(CTnumbers_Soft,Output_Soft,marker_symbol,'Color',C_soft,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_soft)
plot(CTnumbers_Bone,Output_Bone,marker_symbol,'Color',C_bone,'MarkerSize',...
    marker_size,'MarkerFaceColor',C_bone)
%Plot fitted lines:
plot(CTnumbers_Lung_plot,Output_Lung_plot,'Color',C_lung,'LineWidth',1.5)
plot(CTnumbers_Lung_plot,Output_Lung_plot,'--','Color',C_soft,'LineWidth',1.5)
plot(CTnumbers_Fat_plot,Output_Fat_plot,'Color',C_fat,'LineWidth',1.5)
plot(CTnumbers_Soft_plot,Output_Soft_plot,'Color',C_lung,'LineWidth',1.5)
plot(CTnumbers_Soft_plot,Output_Soft_plot,'--','Color',C_soft,'LineWidth',1.5)
plot(CTnumbers_Bone_plot,Output_Bone_plot,'Color',C_bone,'LineWidth',1.5)
%Plot connection line:
plot(CTnumbers_kinks_LungToFat,Output_kinks_LungToFat,'-.k','LineWidth',0.5)
plot(CTnumbers_kinks_FatToSoft,Output_kinks_FatToSoft,'-.k','LineWidth',0.5)
plot(CTnumbers_kinks_SoftToBone,Output_kinks_SoftToBone,'-.k','LineWidth',0.5)
%Limits to the axes:
xlim([-170,170])
ymin=floor(polyval(p_LungSoft,-170)*50)/50;
ymax=ceil(polyval(p_Bone,170)*50)/50;
ylim([ymin,ymax])
%Text above the plot:
text(-55,ymax+0.025,'Adipose and soft tissue region','FontSize',12.5)
set(gca,'FontSize',12,'YGrid','on','YTick',0.7:0.05:1.3)
a=gca;
a.XRuler.TickLabelGapOffset=-2;
a.YRuler.TickLabelGapOffset=-2;
tix=get(gca,'ytick')';
set(gca,'yticklabel',num2str(tix,'%.2f'))

%% Save figure:

if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
    FileName=[txttmp,'_HLUT_',CTnumber_type,'_phantom.png'];
elseif strcmp(CTnumber_type,'Average')
    FileName=[txttmp,'_HLUT_Averaged_CTnumbers.png'];
end
Data_Results.FileNames_HLUT_Figures.(CTnumber_type)=[Data_Results.Output_Folder_Name,...
    filesep,FileName];

saveas(gcf,Data_Results.FileNames_HLUT_Figures.(CTnumber_type))

close(gcf)

%% Save kink points:

%Connection points for the HLUT:
CTnumber_kinks=[CTnumbers_air_plot(1);CTnumbers_kinks_AirToLung;...
    CTnumbers_kinks_LungToFat;CTnumbers_kinks_FatToSoft;...
    CTnumbers_kinks_SoftToBone;CTnumber_max];

Output_kinks=[Output_air;Output_kinks_AirToLung;Output_kinks_LungToFat;...
    Output_kinks_FatToSoft;Output_kinks_SoftToBone;Output_max];

connectionpoints=[CTnumber_kinks,Output_kinks];
HLUT_specification=[[0,Output_air;0,Output_air];p_AirToLung;p_LungSoft;...
    p_LungToFat;p_Fat;p_FatToSoft;p_LungSoft;p_SoftToBone;p_Bone];

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Save the calibration data:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Print the inter-connection points to a text file and a csv file:

%File names:
if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
    filename_csv=[Data_Results.Output_Folder_Name,filesep,...
        txttmp,'_HLUT_',CTnumber_type,'_phantom.csv'];
    filename_txt=[Data_Results.Output_Folder_Name,filesep,...
        txttmp,'_HLUT_',CTnumber_type,'_phantom.txt'];
elseif strcmp(CTnumber_type,'Average')
    filename_csv=[Data_Results.Output_Folder_Name,filesep,...
        txttmp,'_HLUT_Averaged_CTnumbers.csv'];
    filename_txt=[Data_Results.Output_Folder_Name,filesep,...
        txttmp,'_HLUT_Averaged_CTnumbers.txt']; 
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
if strcmp(output_parameter,'MD')
    if strcmp(recon_type,'regular')
        fprintf(fileID_output,'#CT number (HU)   MD (g/cm3)\r\n');
    elseif strcmp(recon_type,'DD')
        fprintf(fileID_output,'#DD CT number (HU)   MD (g/cm3)\r\n');
    end
elseif strcmp(output_parameter,'RED')
    if strcmp(recon_type,'regular')
        fprintf(fileID_output,'#CT number (HU)   RED\r\n');
    elseif strcmp(recon_type,'DD')
        fprintf(fileID_output,'#DD CT number (HU)   RED\r\n');
    end
elseif strcmp(output_parameter,'SPR')
    fprintf(fileID_output,'#CT number (HU)   SPR\r\n');
end
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

% %Output the connection points to command window (Remove % in front of the following five lines, if output is wanted):
% if strcmp(CTnumber_type,'Head') || strcmp(CTnumber_type,'Body')
%     disp(' '),disp([txttmp,' HLUT calibration for <strong>',CTnumber_type,' phantom</strong>:'])
% elseif strcmp(CTnumber_type,'Average')
%     disp(' '),disp([txttmp,' HLUT calibration based on <strong>averaged CT numbers</strong>:'])
% end

%Insert table headings:
if strcmp(txttmp,'MD')
    if strcmp(recon_type,'regular')
        HLUT_connectionpoints.Properties.VariableNames={'CT number (HU)','MD (g/cm3)'};
    elseif strcmp(recon_type,'DD')
        HLUT_connectionpoints.Properties.VariableNames={'DD CT number (HU)','MD (g/cm3)'};
    end
else
    if strcmp(recon_type,'regular')
        HLUT_connectionpoints.Properties.VariableNames={'CT number (HU)',txttmp};
    elseif strcmp(recon_type,'DD')
        HLUT_connectionpoints.Properties.VariableNames={'DD CT number (HU)',txttmp};
    end
end

% %Output the connection points to command window (Remove % in front of the following line, if output is wanted):
% disp(HLUT_connectionpoints)

%% Save the data:

%Connection points:
HLUTs.ConnectionPoints.(CTnumber_type)=array2table(connectionpoints);
%Insert table headings:
HLUTs.ConnectionPoints.(CTnumber_type).Properties.VariableNames=...
    {'CTnumber',txttmp};

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