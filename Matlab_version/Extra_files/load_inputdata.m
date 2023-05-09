function varargout=load_inputdata(Input_Folder_Name,File_name,matlab_version)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function loads the data in the Excel input file.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load measured CT numbers for the calibration phantom:

%Load CT numbers:
try
    if str2double(matlab_version(1:4))<2021
        Data_CTnumbers=readtable([Input_Folder_Name,filesep,File_name],...
            'Sheet','CTnumbers','PreserveVariableNames',true);
    else
        Data_CTnumbers=readtable([Input_Folder_Name,filesep,File_name],...
            'Sheet','CTnumbers','VariableNamingRule','preserve');
    end
catch
    error('Excel file could not be read. Have you remembered to close the Excel file?')
end

%Create struct to save data:
CTnumbers=struct;
CTnumbers.Phantom=Data_CTnumbers;
%Slightly change table headings (for easier reference in the code):
CTnumbers.Phantom.Properties.VariableNames{1}='Insert_names';
CTnumbers.Phantom.Properties.VariableNames{2}='CTnumbers_Head';
CTnumbers.Phantom.Properties.VariableNames{3}='CTnumbers_Body';
CTnumbers.Phantom.Properties.VariableNames{4}='CTnumbers_Evaluation';

%Compute the average CT numbers over the Head and Body phantom:
CTnumbers_Average=(CTnumbers.Phantom.CTnumbers_Head+...
    CTnumbers.Phantom.CTnumbers_Body)/2;

%Add the averaged CT numbers to the table:
CTnumbers.Phantom.CTnumbers_Average=CTnumbers_Average;
%Change the order of the columns in the table:
CTnumbers.Phantom=[CTnumbers.Phantom(:,1:3),CTnumbers.Phantom(:,5),...
    CTnumbers.Phantom(:,4)];

%% Load atomic element data:

if str2double(matlab_version(1:4))<2021
    Data_Elements=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','ElementParameters','PreserveVariableNames',true);
else
    Data_Elements=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','ElementParameters','VariableNamingRule','preserve');
end

%% Data for the phantom inserts:

%Load data for phantom inserts:
if str2double(matlab_version(1:4))<2021
    Data_PhantomInserts=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','PhantomInserts','PreserveVariableNames',true);
else
    Data_PhantomInserts=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','PhantomInserts','VariableNamingRule','preserve');
end

%Create struct to save data:
Data_Phantom=struct;
Data_Phantom.MaterialParameters=table;
Data_Phantom.MaterialParameters.Insert_names=Data_PhantomInserts.('Insert name');
Data_Phantom.MaterialParameters.Density=Data_PhantomInserts.('Density (g/cm3)');
Data_Phantom.MaterialParameters.TissueGroupIndex=Data_PhantomInserts.('Tissue group');

%Check that the phantom inserts are sorted in the same way in the Excel 
%sheet containing the CT numbers and the sheet containing the elemental 
%composition etc:
if ~isempty(setdiff(CTnumbers.Phantom.Insert_names,...
        Data_Phantom.MaterialParameters.Insert_names))
    error(['This script expects the phantom inserts to be sorted in the ',...
        'same way in the Excel sheet containing the CT numbers and ',...
        'in the Excel sheet containing the phantom data! ',...
        'Note: This error may be caused by the names not being spelled ',...
        'the same way in the two Excel sheets.'])
end

%Create struct to save SPR data:
SPR=struct;
SPR.Phantom=table;
SPR.Phantom.Insert_names=Data_Phantom.MaterialParameters.Insert_names;
SPR.Phantom.SPR_Measured=Data_PhantomInserts.('SPR Measured');

%Check that the elemental weight fractions for each insert add up to 100%
%(a small margin around 100% is allowed). And ensure that the elemental 
%weight fractions are given as a fraction and not as a percentage:
wi_index=ismember(Data_PhantomInserts.Properties.VariableNames,...
    Data_Elements.Element);
wi_phantom=table2array(Data_PhantomInserts(:,wi_index));
if ~(all(sum(wi_phantom,2)>0.998) && all(sum(wi_phantom,2)<1.002)) && ...
        ~(all(sum(wi_phantom,2)>99.8) && all(sum(wi_phantom,2)<100.2))
    error(['The elemental weight fractions for some of the phantom inserts ',...
        'do not add up to 1 (or 100%)!'])
elseif all(sum(wi_phantom,2)>99.8) && all(sum(wi_phantom,2)<100.2)
    %The elemental weight fraction is given as percentages: Rescale:    
    wi_phantom=wi_phantom/100;
end

%Check that the same elements are listed for the phantom inserts as in the
%tab with the information on the elements, and that the elements come in 
%the same order:
if any(cellfun(@isequal,Data_PhantomInserts.Properties.VariableNames(wi_index)',...
        Data_Elements.Element)==0)
    error(['The elemental weight fractions of the phantom inserts must be ',...
        'stated for the same elements as listed in the Excel Tab ElementParameters!'])
end

Data_Phantom.wi=wi_phantom;

%% Data for the Tabulated Human Tissues:

if str2double(matlab_version(1:4))<2021
    Data_TabulatedHumanTissues_all=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','TabulatedHumanTissues','PreserveVariableNames',true);
else
    Data_TabulatedHumanTissues_all=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','TabulatedHumanTissues','VariableNamingRule','preserve');
end

%Create struct to save data:
Data_TabulatedHumanTissues=struct;
Data_TabulatedHumanTissues.MaterialParameters=table;
Data_TabulatedHumanTissues.MaterialParameters.Tissue_names=...
    Data_TabulatedHumanTissues_all.('Tissue name');
Data_TabulatedHumanTissues.MaterialParameters.Density=...
    Data_TabulatedHumanTissues_all.('Density (g/cm3)');
Data_TabulatedHumanTissues.MaterialParameters.TissueGroupIndex=...
    Data_TabulatedHumanTissues_all.('Tissue group');

%Check that the elemental weight fractions for each insert add up to 100%
%(a small margin around 100% is allowed). And ensure that the elemental 
%weight fractions are given as a fraction and not as a percentage:
wi_index=ismember(Data_TabulatedHumanTissues_all.Properties.VariableNames,...
    Data_Elements.Element);
wi_tissues=table2array(Data_TabulatedHumanTissues_all(:,wi_index));
if ~(all(sum(wi_tissues,2)>0.998) && all(sum(wi_tissues,2)<1.002)) && ...
        ~(all(sum(wi_tissues,2)>99.8) && all(sum(wi_tissues,2)<100.2))
    error(['The elemental weight fractions for some of the phantom inserts ',...
        'do not add up to 1 (or 100%)!'])
elseif all(sum(wi_tissues,2)>99.8) && all(sum(wi_tissues,2)<100.2)
    %The elemental weight fraction is given as percentages: Rescale:    
    wi_tissues=wi_tissues/100;
end

%Check that the same elements are listed for the phantom inserts as in the
%tab with the information on the elements, and that the elements come in 
%the same order:
if any(cellfun(@isequal,Data_TabulatedHumanTissues_all.Properties...
        .VariableNames(wi_index)',Data_Elements.Element)==0)
    error(['The elemental weight fractions of the phantom inserts must be ',...
        'stated for the same elements as listed in the Excel Tab ElementParameters!'])
end

Data_TabulatedHumanTissues.wi=wi_tissues;

%% Define data for water:

%Create struct to save data for water:
Data_water=struct;
Data_water.Density=1;
Data_water.wi=[0.111894,0.888106];
Data_water.Zi=[1;8];
[~,index_w]=ismember(Data_water.Zi,Data_Elements.Zi);
Data_water.Ai=Data_Elements.Ai(index_w);
Data_water.Ii=Data_Elements.Ii(index_w);

%% Define output from this function:

varargout={CTnumbers,SPR,Data_Phantom,Data_TabulatedHumanTissues,...
    Data_Elements,Data_water};

end