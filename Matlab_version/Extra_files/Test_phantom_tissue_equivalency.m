function Data_Results=Test_phantom_tissue_equivalency(Data_Phantom,Data_Elements,...
    Data_TabulatedHumanTissues,Data_water,Data_Results)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Evaluation box 2: Tissue equivalency:
% In this function the relative electron density (RED), the effective 
% atomic number (Z_eff), and the mean excitation energy (I) is computed for
% the tabulated human tissues and the phantom inserts, and they are then
% plotted to assess if the phantom inserts follow the trend seen by the 
% tabulated human tissues, to judge if the phantom inserts are tissue
% equivalent.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define parameters:

%Exponent for computation of effective atomic number (Zeff):
beta_Zeff=3.1;

%% Compute quantities to plot (and save the data to the structs):

%Tabulated human tissues:
[Data_TabulatedHumanTissues.MaterialParameters.RED,...
    Data_TabulatedHumanTissues.MaterialParameters.Z_eff,...
    lnI_TabulatedHumanTissues]=compute_material_parameters(...
    Data_TabulatedHumanTissues.MaterialParameters.Density,...
    Data_TabulatedHumanTissues.wi,Data_Elements.Zi,Data_Elements.Ai,...
    Data_Elements.Ii,Data_water,beta_Zeff,true,true,true);
Data_TabulatedHumanTissues.MaterialParameters.I=exp(lnI_TabulatedHumanTissues);

%Phantom inserts:
[Data_Phantom.MaterialParameters.RED,Data_Phantom.MaterialParameters.Z_eff,...
    lnI_phantom]=compute_material_parameters(Data_Phantom.MaterialParameters.Density,...
    Data_Phantom.wi,Data_Elements.Zi,Data_Elements.Ai,Data_Elements.Ii,...
    Data_water,beta_Zeff,true,true,true);
Data_Phantom.MaterialParameters.I=exp(lnI_phantom);

%% Plot figures to test the tissue equivalency of the phantom inserts:

%Define file names to save figures:
Data_Results.FileNames_Tissueequivalency=struct;
Data_Results.FileNames_Tissueequivalency.Figure_RED_Zeff=[Data_Results.Output_Folder_Name,...
    filesep,'Eval_Box_2_Tissue_equivalency_RED_Zeff.png'];
Data_Results.FileNames_Tissueequivalency.Figure_Zeff_I=[Data_Results.Output_Folder_Name,...
    filesep,'Eval_Box_2_Tissue_equivalency_Zeff_I.png'];
Data_Results.FileNames_Tissueequivalency.Figure_RED_I=[Data_Results.Output_Folder_Name,...
    filesep,'Eval_Box_2_Tissue_equivalency_RED_I.png'];

%Define colors:
C_ref_tissues=[0,0.447,0.741];
C_phantom=[0.85,0.325,0.098];

%Plot figure for relative electron density vs effective atomic number:
figure, hold on
plot(Data_TabulatedHumanTissues.MaterialParameters.RED,...
    Data_TabulatedHumanTissues.MaterialParameters.Z_eff,...
    'o','Color',C_ref_tissues,'MarkerFaceColor',C_ref_tissues)
plot(Data_Phantom.MaterialParameters.RED,Data_Phantom.MaterialParameters.Z_eff,...
    'o','Color',C_phantom,...
    'MarkerFaceColor',C_phantom)
set(gca,'FontSize',12)
xlabel('Relative electron density')
ylabel('Effective atomic number')
title('X-ray attenuation')
hl=legend('Tabulated human tissues','Phantom inserts',...
    'Location','northwest');
hl.FontSize=12;
box on
%Save figure:
saveas(gcf,Data_Results.FileNames_Tissueequivalency.Figure_RED_Zeff)

%Plot figure for effective atomic number vs mean excitation energy
%(I-value):
figure, hold on
plot(Data_TabulatedHumanTissues.MaterialParameters.Z_eff,...
    Data_TabulatedHumanTissues.MaterialParameters.I,'o','Color',C_ref_tissues,...
    'MarkerFaceColor',C_ref_tissues)
plot(Data_Phantom.MaterialParameters.Z_eff,Data_Phantom.MaterialParameters.I,...
    'o','Color',C_phantom,'MarkerFaceColor',C_phantom)
set(gca,'FontSize',12)
xlabel('Effective atomic number')
ylabel('Mean excitation energy (eV)')
title('X-ray attenuation vs proton stopping power')
hl=legend('Tabulated human tissues','Phantom inserts',...
    'Location','northwest');
hl.FontSize=12;
box on
%Save figure:
saveas(gcf,Data_Results.FileNames_Tissueequivalency.Figure_Zeff_I)

%Plot figure for relative electron density vs mean excitation energy
%(I-value):
figure, hold on
plot(Data_TabulatedHumanTissues.MaterialParameters.RED,Data_TabulatedHumanTissues.MaterialParameters.I,...
    'o','Color',C_ref_tissues,'MarkerFaceColor',C_ref_tissues)
plot(Data_Phantom.MaterialParameters.RED,Data_Phantom.MaterialParameters.I,...
    'o','Color',C_phantom,'MarkerFaceColor',C_phantom)
set(gca,'FontSize',12)
xlabel('Relative electron density')
ylabel('Mean excitation energy (eV)')
title('Proton stopping power')
hl=legend('Tabulated human tissues','Phantom inserts',...
    'Location','northwest');
hl.FontSize=12;
box on
%Save figure:
saveas(gcf,Data_Results.FileNames_Tissueequivalency.Figure_RED_I)

end
%% End of file