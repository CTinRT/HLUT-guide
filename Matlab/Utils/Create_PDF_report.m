function Create_PDF_report(Data_Results,CTnumber_types,File_name,Output,...
    Output_Folder_Name,matlab_version,recon_type)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This file creates a PDF file with the results of the HLUT calibration and
% evaluation,
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create the PDF:

import mlreportgen.dom.*
import mlreportgen.report.*

%Create report (to create a Word report, change the output type from "pdf"
%to "docx"):
rpt=Report([Output_Folder_Name,filesep,'HLUT generation and evaluation Report'],'pdf');

%% Create title page:

if strcmp(Output.Variable,'MD')
   txt_output='mass density';
elseif strcmp(Output.Variable,'RED')
   txt_output='relative electron density';
elseif strcmp(Output.Variable,'SPR')
    txt_output='stopping-power ratio';
end

tp=TitlePage();
if strcmp(recon_type,'regular')
    tp.Title=['Hounsfield Look-Up Table (HLUT) generation and evaluation ',...
        'for CT number to ',txt_output,' (',Output.Variable,') conversion'];
elseif strcmp(recon_type,'DD')
    tp.Title=['Hounsfield Look-Up Table (HLUT) generation and evaluation ',...
        'for DirectDensity (DD) CT number to ',txt_output,...
        ' (',Output.Variable,') conversion'];
end

subtitle_tp=Text('The user is responsible for confirming the results prior to use');
subtitle_tp.Style={Color('red')};
tp.Subtitle=subtitle_tp;

tp.Image=Data_Results.FileNames_HLUT_Figures.Body;
report_explanation=Text(['HLUT generation and evaluation tool, following ',...
    'the HLUT generation guide. DOI: https://doi.org/10.1016/j.radonc.2023.109675']);
report_explanation.Style={FontSize('18pt')};
report_explanation.Bold=false;
tp.Author=report_explanation;
data_location_statement=Text(['The results are generated based on the data ',...
    'in the Excel file ',File_name]);
data_location_statement.Style={FontSize('15pt')};
tp.Publisher=data_location_statement;

%Add to report:
add(rpt,tp)

%% Create chapter 1 - generated HLUTs:

warning('off','all')

%Chapter 1 - HLUT calibration results:
ch1=Chapter;
t1=Text('Generated HLUT');
t1.Bold=true;
t1.FontSize='32px';
add(ch1,t1)

if strcmp(recon_type,'regular')
    t1=Text(['In this report a Hounsfield Look-Up Table (HLUT) is generated ',...
        'for CT number to ',txt_output,' (',Output.Variable,') conversion.']);
elseif strcmp(recon_type,'DD')
    t1=Text(['In this report a Hounsfield Look-Up Table (HLUT) is generated ',...
        'for DD CT number to ',txt_output,' (',Output.Variable,') conversion.']);
end
add(ch1,t1)
t1=Text('');
add(ch1,t1)
t1=Text(['The HLUT is to be visually evaluated regarding the proximity of ',...
    'the datapoints to the curve and the need for a body size specific ',...
    'HLUT, see Supplementary Material Evaluation Box 5.']);
add(ch1,t1)
t1=Text('');
add(ch1,t1)

for i=1:length(CTnumber_types)
    if strcmp(CTnumber_types{i},'Head') || strcmp(CTnumber_types{i},'Body')
        t1=Text(['HLUT for ',CTnumber_types{i},' phantom:']);
    elseif strcmp(CTnumber_types{i},'Average')
        t1=Text('HLUT for average CT numbers:');
    end
    t1.Bold=true;
    t1.FontSize='18px';
    add(ch1,t1)
    %Table:
    if str2double(matlab_version(1:4))<2021
        tab1=mlreportgen.dom.MATLABTable(Data_Results.ConnectionPoints.(CTnumber_types{i}));
        add(ch1,tab1)
    else
        tab1=Table(Data_Results.ConnectionPoints.(CTnumber_types{i})(:,1));
        tab1.Style=[tab1.Style,{NumberFormat('%.0f')}];
        r1=row(tab1,1);
        re=r1.Entries;
        re1=re(1);
        re1.Style=[re1.Style,{Bold(true)}];
        tab2=Table(Data_Results.ConnectionPoints.(CTnumber_types{i})(:,2));
        tab2.Style=[tab2.Style,{NumberFormat('%.4f')}];
        r1=row(tab2,1);
        re=r1.Entries;
        re1=re(1);
        re1.Style=[re1.Style,{Bold(true)}];
        table1=Table({tab1,' ',tab2});
        add(ch1,table1)
    end
    %Text - end of curve not specified:
    t1=Text(['Please note: The last datapoint is not based on recommendations. ',...
        'Please check the guide for the different suggestions to extend the ',...
        'HLUT beyond this point.']);
    add(ch1,t1)
    
    %Figure:
    f1=Image(Data_Results.FileNames_HLUT_Figures.(CTnumber_types{i}));
    f1.Style=[f1.Style,{ScaleToFit}];
    add(ch1,f1)
    %Page break:
    br=PageBreak();
    add(ch1,br)
end

%Add to report:
add(rpt,ch1)

%% Create chapter 2 - HLUT evaluation results:

%Chapter 2 - HLUT evaluation results:
ch2=Chapter;
t1=Text('HLUT evaluation results');
t1.Bold=true;
t1.FontSize='32px';
add(ch2,t1)
t1=Text('');
add(ch2,t1)

%Evaluation box 1: Size-dependent impact of beam hardening on CT numbers:
t1=Text('Evaluation box 1: Size-dependent impact of beam hardening on CT numbers');
t1.Bold=true;
t1.FontSize='22px';
t1.Style=[t1.Style,{LineSpacing(1.2)}];
add(ch2,t1)
t1=Text('');
add(ch2,t1)
MLTableObj=mlreportgen.dom.MATLABTable(Data_Results.CTnumber_SizeDependency);
if str2double(matlab_version(1:4))>2020
    MLTableObj.Style=[MLTableObj.Style,{NumberFormat('%.0f')}];
end
add(ch2,MLTableObj)
t1=Text('');
add(ch2,t1)
%Page break:
add(ch2,br)

%Evaluation box 2: Tissue equivalency of phantom inserts:
t1=Text('Evaluation box 2: Tissue equivalency of phantom inserts');
t1.Bold=true;
t1.FontSize='22px';
add(ch2,t1)
if strcmp(Output.Variable,'MD')
   t1=Text('Tissue equivalency for photon therapy and mass density.');
elseif strcmp(Output.Variable,'RED')
   t1=Text('Tissue equivalency for photon therapy and relative electron density.');
elseif strcmp(Output.Variable,'SPR')
    t1=Text('Tissue equivalency for proton therapy and stopping power ratio.');
end 
add(ch2,t1)
%Figures:
FileNames=fieldnames(Data_Results.FileNames_Tissueequivalency);
for i=1:length(FileNames)
    f1=Image(Data_Results.FileNames_Tissueequivalency.(FileNames{i}));
    f1.Height='6.4cm';
    f1.Width=[];        %Scale width to fit
    halign=mlreportgen.dom.HAlign('center');
    f1.Style=[f1.Style(:)',{halign}];
    add(ch2,f1)
end
%Page break:
add(ch2,br)

%Evaluation box 3: Check of estimated CT numbers:
t1=Text('Evaluation box 3: Check of estimated CT numbers');
t1.Bold=true;
t1.FontSize='22px';
add(ch2,t1)
t1=Text('Measured vs estimated CT numbers for the phantom inserts.');
add(ch2,t1)
for i=1:length(CTnumber_types)-1
    t1=Text([CTnumber_types{i},' phantom:']);
    t1.Bold=true;
    add(ch2,t1)
    MLTableObj=mlreportgen.dom.MATLABTable(Data_Results.CTnumber_estimation_accuracy...
        .([CTnumber_types{i},'_phantom']).Deviations);
    if str2double(matlab_version(1:4))>2020
        MLTableObj.Style=[MLTableObj.Style,{NumberFormat('%.0f')}];
    end
    add(ch2,MLTableObj)
    if i==1
        %Add empty line:
        t1=Text('');
        add(ch2,t1)
    end
end
%Figure with results:
f1=Image(Data_Results.CTnumber_estimation_accuracy.FileName);
f1.Style=[f1.Style,{ScaleToFit}];
add(ch2,f1)
%Page break:
add(ch2,br)

%For SPR HLUTs based on measured SPR values:
%Evaluation box 4: Consistency check of SPR determined experimentally:
if isfield(Output,'SPR_type') && strcmp(Output.SPR_type,'SPR_Measured')
    t1=Text('Evaluation box 4: Consistency check of SPR determined experimentally');
    t1.Bold=true;
    t1.FontSize='22px';
    add(ch2,t1)
    %Add empty line:
    t1=Text('');
    add(ch2,t1)
    %Add the results:
    tabledata=Data_Results.SPR_measured_vs_theoretical.Deviations;
    tabledata(:,2:4)=round(tabledata(:,2:4),3);
    tabledata(:,5)=round(tabledata(:,5),2);
    MLTableObj=mlreportgen.dom.MATLABTable(tabledata);
    add(ch2,MLTableObj)
    %Add empty line:
    t1=Text('');
    add(ch2,t1)
    %Add the ME and RMSE:
    MLTableObj=mlreportgen.dom.MATLABTable(Data_Results...
        .SPR_measured_vs_theoretical.Accuracy);
    if str2double(matlab_version(1:4))>2020
        MLTableObj.Style=[MLTableObj.Style,{NumberFormat('%.1f')}];
    end
    add(ch2,MLTableObj)
    %Add figure with the results:
    f1=Image(Data_Results.SPR_measured_vs_theoretical.FileName);
    f1.Style=[f1.Style,{ScaleToFit}];
    add(ch2,f1)
    %Page break:
    add(ch2,br)
elseif isfield(Output,'SPR_type') && strcmp(Output.SPR_type,'SPR_Theoretical')
    t1=Text(['Evaluation box 4: No measured SPR values have been provided, ',...
        'this evaluation is therefore skipped.']);
    t1.Bold=true;
    t1.FontSize='22px';
    t1.Style=[t1.Style,{LineSpacing(1.2)}];
    add(ch2,t1)
    %Page break:
    add(ch2,br)
else
    t1=Text(['Evaluation box 4: This evaluation is only relevant for ',...
        'SPR HLUTs. Therefore, this evaluation is skipped here.']);
    t1.Bold=true;
    t1.FontSize='22px';
    t1.Style=[t1.Style,{LineSpacing(1.2)}];
    add(ch2,t1)
    %Page break:
    add(ch2,br)
end

%Evaluation box 5: Visual HLUT evaluation and assessment of body-region-specific HLUTs
t1=Text(['Evaluation box 5: Visual HLUT evaluation and assessment of ',...
    'body-region-specific HLUTs']);
t1.Bold=true;
t1.FontSize='22px';
t1.Style=[t1.Style,{LineSpacing(1.2)}];
add(ch2,t1)
t1=Text(['The visual inspection can be performed based on the curves shown ',...
    'in the first part of this report, "Generated HLUT". And potentially ',...
    'by zooming in on different regions of the figures for the HLUTs.']);
add(ch2,t1)
t1=Text('Assessment of body-region-specific HLUTs');
t1.Bold=true;
t1.FontSize='18px';
add(ch2,t1)
t1=Text(['Comparisons of the HLUTs generarated for the Head or Body size ',...
    'phantom with the HLUT generated on the averaged CT numbers.']);
add(ch2,t1)
f1=Image(Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency);
f1.Style=[f1.Style,{ScaleToFit}];
add(ch2,f1)
f1=Image(Data_Results.FileNames_HLUT_Test_Average.Figure_size_dependency_deviations);
f1.Style=[f1.Style,{ScaleToFit}];
add(ch2,f1)
%Page break:
add(ch2,br)

%End-to-end testing: Evaluation of the generated HLUT
t1=Text('End-to-end testing: Evaluation of the generated HLUT');
t1.Bold=true;
t1.FontSize='22px';
add(ch2,t1)
t1=Text('');
add(ch2,t1)

%Evaluation of the  HLUT accuracy:
t1=Text('Evaluation of the  HLUT accuracy');
t1.Bold=true;
t1.FontSize='20px';
add(ch2,t1)
t1=Text(['Difference between the reference ',txt_output,' (',Output.Variable,...
    ') and the ',Output.Variable,' predicted using the HLUTs ',...
    'generated for the head, body and averaged CT numbers:']);
add(ch2,t1)
%Figure with results:
f1=Image(Data_Results.HLUT_fitting_accuracy.FileName_HLUT_accuracy_figure);
f1.Style=[f1.Style,{ScaleToFit}];
add(ch2,f1)
t1=Text(['HLUT fitting accuracy for head and body with respective HLUT ',...
    '(fit vs individual datapoints):']);
add(ch2,t1)
for i=1:length(CTnumber_types)
    if strcmp(CTnumber_types{i},'Head') || strcmp(CTnumber_types{i},'Body')
        t1=Text([CTnumber_types{i},' phantom:']);
    elseif strcmp(CTnumber_types{i},'Average')
        continue
    end
    t1.Bold=true;
    t1.FontSize='18px';
    add(ch2,t1)
    MLTableObj=mlreportgen.dom.MATLABTable(Data_Results.HLUT_fitting_accuracy...
        .([CTnumber_types{i},'_vs_',CTnumber_types{i}]));
    if str2double(matlab_version(1:4))>2020
        MLTableObj.Style=[MLTableObj.Style,{NumberFormat('%.2f')}];
    end
    add(ch2,MLTableObj)
end
%Page break:
add(ch2,br)

%Evaluation of the position dependency of the CT numbers:
t1=Text('Influence of insert location on CT number for bone phantom inserts');
t1.Bold=true;
t1.FontSize='20px';
t1.Style=[t1.Style,{LineSpacing(1.1)}];
add(ch2,t1)
t1=Text(['CT number for the insert placed in the middle of the phantom ',...
    '(CTN Middle; position used for calibration) vs CT number for the ',...
    'insert placed in the outer ring of the phantom (CTN Outer):']);
add(ch2,t1)
%Add empty line:
t1=Text('');
add(ch2,t1)
MLTableObj=mlreportgen.dom.MATLABTable(Data_Results.CTnumber_PositionDependency);
if str2double(matlab_version(1:4))>2020
    MLTableObj.Style=[MLTableObj.Style,{NumberFormat('%.0f')}];
end
add(ch2,MLTableObj)
%Add empty line:
t1=Text('');
add(ch2,t1)
t1=Text(['Estimation accuracy for bone insert placed in the middle of the phantom ',...
    'and placed in the outer ring of the phantom:']);
add(ch2,t1)
%Add empty line:
t1=Text('');
add(ch2,t1)
MLTableObj=mlreportgen.dom.MATLABTable(Data_Results.Parameter_PositionDependency);
% if str2double(matlab_version(1:4))>2020
%     MLTableObj.Style=[MLTableObj.Style,{NumberFormat('%.0f')}];
% end
add(ch2,MLTableObj)

%Add to report:
add(rpt,ch2)

%% Close and view the report:

close(rpt);
% rptview(rpt, 'pdf', false);

%Close figures (these are shown in the PDF file, and saved to the Results
%folder):
close all

end