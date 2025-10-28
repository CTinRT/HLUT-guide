function varargout=initialize_data(Output_Folder_Name,output_parameter,...
    matlab_version,Input_Folder_Name,File_name,E_kin)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function intialize the data to be used in the code, and loads the 
% data in the Excel input file.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Check if needed folders exist:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Check if the Output folder exists, else make it:
if ~exist(Output_Folder_Name,'dir')
    mkdir(Output_Folder_Name)
end

%Make dedicated subfolder for this sepcific run of the code:
date_and_time=datetime('now');
Output_Folder_Name_subfolder=['Results_',output_parameter,'_',...
    sprintf('%04d%02d%02d',year(date_and_time),month(date_and_time),...
    day(date_and_time)),'_',sprintf('%02d%02d%02d',hour(date_and_time),...
    minute(date_and_time),floor(second(date_and_time)))];

%Create the subfolder:
mkdir([Output_Folder_Name,filesep,Output_Folder_Name_subfolder])
Output_Folder_Name=[Output_Folder_Name,filesep,Output_Folder_Name_subfolder];

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Load CT numbers from Excel file:
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

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Load element data from Excel file, and calculate data for water and air:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load atomic element data:

if str2double(matlab_version(1:4))<2021
    Data_Elements=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','ElementParameters','PreserveVariableNames',true);
else
    Data_Elements=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','ElementParameters','VariableNamingRule','preserve');
end

%% Define data for water:

%Create struct to save data for water:
Data_water_air=struct;
Data_water_air.water=struct;
Data_water_air.water.Density=1;
Data_water_air.water.wi=[0.1119,0.8881];
Data_water_air.water.Zi=[1;8];
[~,index_w]=ismember(Data_water_air.water.Zi,Data_Elements.Zi);
Data_water_air.water.Ai=Data_Elements.Ai(index_w);
Data_water_air.water.Ii=Data_Elements.Ii(index_w);

%% Define data for air:

%Create struct to save data for air:
Data_water_air.air=struct;

%Data for air from NIST: https://physics.nist.gov/cgi-bin/Star/compos.pl?matno=104
Data_water_air.air.Density=1.20479E-03;
Data_water_air.air.wi=[0.000124,0.755267,0.231781,0.012827];
Data_water_air.air.Zi=[6;7;8;18];
Data_water_air.air.Ai=[12.011;14.007;15.999;39.948];
Data_water_air.air.I=85.7;

if strcmp(output_parameter,'RED')
    Data_water_air.air.RED=compute_material_parameters(...
        Data_water_air.air.Density,Data_water_air.air.wi,...
        Data_water_air.air.Zi,Data_water_air.air.Ai,[],Data_water_air,...
        [],[],true,false,false,false,[]);
elseif strcmp(output_parameter,'SPR')
    [~,~,~,Data_water_air.air.SPR]=compute_material_parameters(...
        Data_water_air.air.Density,Data_water_air.air.wi,...
        Data_water_air.air.Zi,Data_water_air.air.Ai,Data_water_air.air.I,...
        Data_water_air,[],E_kin,false,false,false,true,true);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Load phantom data from Excel file, and calculate parameter data:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%% Calculate parameter data for the phantom inserts:

%Define parameter value for the exponent for computation of effective 
%atomic number (Zeff):
beta_Zeff=3.1;

[Data_Phantom.MaterialParameters.RED,Data_Phantom.MaterialParameters.Z_eff]=...
    compute_material_parameters(Data_Phantom.MaterialParameters.Density,...
    Data_Phantom.wi,Data_Elements.Zi,Data_Elements.Ai,[],Data_water_air,...
    beta_Zeff,[],true,true,false,false,[]);

%% Create struct to save the data for the output parameter (MD, RED, SPR):

Output=struct;
if strcmp(output_parameter,'MD')
    Output.Variable='MD';
elseif strcmp(output_parameter,'RED')
    Output.Variable='RED';
elseif strcmp(output_parameter,'SPR')
    Output.Variable='SPR';
end

Output.Phantom=table;
Output.Phantom.Insert_names=Data_Phantom.MaterialParameters.Insert_names;

if strcmp(output_parameter,'MD')
    Output.Phantom.Output=Data_Phantom.MaterialParameters.Density;
elseif strcmp(output_parameter,'RED')
    Output.Phantom.Output=Data_Phantom.MaterialParameters.RED;
elseif strcmp(output_parameter,'SPR')
    %Calculate the theoretical SPR values:
    [~,~,Data_Phantom.MaterialParameters.I,Data_Phantom.MaterialParameters.SPR]=...
        compute_material_parameters(...
        Data_Phantom.MaterialParameters.Density,Data_Phantom.wi,Data_Elements.Zi,...
        Data_Elements.Ai,Data_Elements.Ii,Data_water_air,[],E_kin,false,...
        false,false,true,true);

    %Check if measured SPR values have been provided for all the phantom
    %inserts:
    if all(~isnan(Data_PhantomInserts.('SPR Measured')))
        % disp('Calibration is based on measured SPR values')
        Output.Phantom.Output=Data_PhantomInserts.('SPR Measured');
        Output.SPR_type='SPR_Measured';
        Output.Phantom.SPR_Measured=Data_PhantomInserts.('SPR Measured');
        Output.Phantom.SPR_Theoretical=Data_Phantom.MaterialParameters.SPR;
    else
        % disp(['Calibration is based on theoretical SPR values, since no ',...
        %     'measured SPR values are provided.'])
        Output.SPR_type='SPR_Theoretical';
        Output.Phantom.Output=Data_Phantom.MaterialParameters.SPR;
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Load tabulated human tissue data from Excel file, and calculate parameter data:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Data for the tabulated human tissues:

if str2double(matlab_version(1:4))<2021
    Data_TabulatedHumanTissues_all=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','TabulatedHumanTissues','PreserveVariableNames',true);
else
    Data_TabulatedHumanTissues_all=readtable([Input_Folder_Name,filesep,File_name],...
        'Sheet','TabulatedHumanTissues','VariableNamingRule','preserve');
end

clear Input_Folder_Name

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

%% Calculate parameter data for the tabulated human tissues:

[Data_TabulatedHumanTissues.MaterialParameters.RED,...
    Data_TabulatedHumanTissues.MaterialParameters.Z_eff]=...
    compute_material_parameters(Data_TabulatedHumanTissues.MaterialParameters.Density,...
    Data_TabulatedHumanTissues.wi,Data_Elements.Zi,Data_Elements.Ai,[],...
    Data_water_air,beta_Zeff,[],true,true,false,false,[]);

%% Create struct to save the data for the output parameter (MD, RED, SPR):

%Tabulated Human Tissues:
Output.TabulatedHumanTissues=table;
Output.TabulatedHumanTissues.Tissue_names=Data_TabulatedHumanTissues...
    .MaterialParameters.Tissue_names;

if strcmp(output_parameter,'MD')
    Output.TabulatedHumanTissues.Output=Data_TabulatedHumanTissues...
        .MaterialParameters.Density;
elseif strcmp(output_parameter,'RED')
    Output.TabulatedHumanTissues.Output=Data_TabulatedHumanTissues...
        .MaterialParameters.RED;
elseif strcmp(output_parameter,'SPR')
    %Calculate the theoretical SPR values:
    [~,~,Data_TabulatedHumanTissues.MaterialParameters.I,...
        Data_TabulatedHumanTissues.MaterialParameters.SPR]=...
        compute_material_parameters(...
        Data_TabulatedHumanTissues.MaterialParameters.Density,...
        Data_TabulatedHumanTissues.wi,Data_Elements.Zi,...
        Data_Elements.Ai,Data_Elements.Ii,Data_water_air,[],E_kin,false,...
        false,false,true,true);
    Output.TabulatedHumanTissues.Output=...
        Data_TabulatedHumanTissues.MaterialParameters.SPR;
end

%% Define output from this function:

varargout={Output_Folder_Name,CTnumbers,Output,...
    Data_Phantom,Data_TabulatedHumanTissues,Data_Elements,...
    Data_water_air};

end


function varargout=compute_material_parameters(Density,wi,Zi,Ai,Ii,...
    Data_water_air,beta_Zeff,E_kin,rho_e_yn,Z_eff_yn,lnI_yn,SPR_yn,Bragg_yn)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function computes the theoretical material parameters of importance
% for radiotherapy, the relative electron density, the effective atomic
% number, the mean excitation energy, and the theoretical stopping-power 
% ratio. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Calculate the relative electron density:

if rho_e_yn || SPR_yn
    rho_e=Density.*(wi*(Zi./Ai))/(Data_water_air.water.Density*...
        (Data_water_air.water.wi*(Data_water_air.water.Zi./...
        Data_water_air.water.Ai)));
else
    rho_e=[];
end

%% Calculate the effective atomic number:

if Z_eff_yn
    Z_eff=(wi*(Zi.^(beta_Zeff+1)./Ai)./(wi*(Zi./Ai))).^(1/beta_Zeff);
else
    Z_eff=[];
end

%% Calculate the mean excitation energy:

if lnI_yn || SPR_yn && Bragg_yn
    %Use the Bragg rule to calculate the logaritm of the I-value for compounds:
    lnI=(wi*(Zi.*log(Ii)./Ai))./(wi*(Zi./Ai));
else
    lnI=[];
end

%% Calculate the theoretical SPR:

if SPR_yn
    %Logarithm of predefined I-value:
    if ~Bragg_yn
        lnI=log(Ii);
    end

    %Stopping power parameters:
    E_0=938;                                %Rest mass of proton (MeV)
    m_e=511*10^3;                           %Rest mass of electron (eV)
    %Relativistic beta squared:
    beta2=1-(E_kin/E_0+1)^(-2);
    %Use the Bragg rule to calculate the logaritm of the I-value for water:
    lnI_water=(Data_water_air.water.wi*(Data_water_air.water.Zi.*...
        log(Data_water_air.water.Ii)./Data_water_air.water.Ai))./...
        (Data_water_air.water.wi*(Data_water_air.water.Zi./Data_water_air.water.Ai));
    %Stopping power ratio relative to water:
    %Constant in numerator:
    SPR_num=log(2*m_e)+log(beta2/(1-beta2))-beta2;
    %Denominator:
    SPR_den=(log(2*m_e)+log(beta2/(1-beta2))-lnI_water-beta2);

    %SPR:
    SPR_theo=rho_e.*(SPR_num-lnI)/SPR_den;
else
    SPR_theo=[];
end

%% Define output from this function:

varargout={rho_e,Z_eff,lnI,SPR_theo};

end