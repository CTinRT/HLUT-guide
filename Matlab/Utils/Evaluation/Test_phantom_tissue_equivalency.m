function Data_Results=Test_phantom_tissue_equivalency(Data_Phantom,...
    Data_TabulatedHumanTissues,Data_Results,output_parameter)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Evaluation box 2: Tissue equivalency:
% This function plots the materials parameters (RED, Z_eff, I, MD) for
% the tabulated human tissues and the phantom inserts to assess if the
% phantom inserts follow the trend seen by the tabulated human tissues,
% to judge if the phantom inserts are tissue-equivalent.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Define figure file names:

%Define file names to save figures:
Data_Results.FileNames_Tissueequivalency=struct;
Data_Results.FileNames_Tissueequivalency.Figure_RED_Zeff=...
    [Data_Results.Output_Folder_Name,filesep,...
    'Eval_Box_2_Tissue_equivalency_RED_Zeff.png'];
if strcmp(output_parameter,'MD')
    Data_Results.FileNames_Tissueequivalency.Figure_MD_RED=...
        [Data_Results.Output_Folder_Name,filesep,...
        'Eval_Box_2_Tissue_equivalency_MD_RED.png'];
elseif strcmp(output_parameter,'SPR')
    Data_Results.FileNames_Tissueequivalency.Figure_Zeff_I=...
        [Data_Results.Output_Folder_Name,filesep,...
        'Eval_Box_2_Tissue_equivalency_Zeff_I.png'];
    Data_Results.FileNames_Tissueequivalency.Figure_RED_I=...
        [Data_Results.Output_Folder_Name,filesep,...
        'Eval_Box_2_Tissue_equivalency_RED_I.png'];
end

%Define colors:
C_ref_tissues=[0,0.447,0.741];
C_phantom=[0.85,0.325,0.098];

%% Figure RED vs Z_eff:

%Plot figure for relative electron density vs effective atomic number:
figure('Position',[100,100,560,420],'Visible','off'), hold on
plot(Data_TabulatedHumanTissues.MaterialParameters.RED,...
    Data_TabulatedHumanTissues.MaterialParameters.Z_eff,...
    'o','Color',C_ref_tissues,'MarkerFaceColor',C_ref_tissues)
plot(Data_Phantom.MaterialParameters.RED,Data_Phantom.MaterialParameters.Z_eff,...
    'o','Color',C_phantom,'MarkerFaceColor',C_phantom)
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

close(gcf)

%% Figure MD vs RED (for MD curves only):

if strcmp(output_parameter,'MD')
    %Plot figure for mass density vs relative electron density:
    figure('Position',[100,100,560,420],'Visible','off'), hold on
    plot(Data_TabulatedHumanTissues.MaterialParameters.Density,...
        Data_TabulatedHumanTissues.MaterialParameters.RED,'o','Color',...
        C_ref_tissues,'MarkerFaceColor',C_ref_tissues)
    plot(Data_Phantom.MaterialParameters.Density,Data_Phantom.MaterialParameters.RED,...
        'o','Color',C_phantom,'MarkerFaceColor',C_phantom)
    set(gca,'FontSize',12)
    xlabel('Mass density (g/cm^3)')
    ylabel('Relative electron density')
    title('X-ray attenuation')
    hl=legend('Tabulated human tissues','Phantom inserts',...
        'Location','northwest');
    hl.FontSize=12;
    box on

    %Figure inset for soft tissue region:
    axes('Position',[0.58,0.2,0.3,0.3])
    hold on
    box on
    plot(Data_TabulatedHumanTissues.MaterialParameters.Density,...
        Data_TabulatedHumanTissues.MaterialParameters.RED,'o','Color',...
        C_ref_tissues,'MarkerFaceColor',C_ref_tissues)
    plot(Data_Phantom.MaterialParameters.Density,Data_Phantom.MaterialParameters.RED,...
        'o','Color',C_phantom,'MarkerFaceColor',C_phantom)
    text(0.91,1.22,'Soft tissue region','FontSize',12.5)
    xlim([0.88,1.25])
    ylim([0.9,1.2])
    set(gca,'FontSize',11)
    a=gca;
    a.XRuler.TickLabelGapOffset=-2;
    a.YRuler.TickLabelGapOffset=-2;

    %Save figure:
    saveas(gcf,Data_Results.FileNames_Tissueequivalency.Figure_MD_RED)

    close(gcf)
end

%% Figure Z_eff vs I-value (SPR curve only):

if strcmp(output_parameter,'SPR')
    %Plot figure for effective atomic number vs mean excitation energy
    %(I-value):
    figure('Position',[100,100,560,420],'Visible','off'), hold on
    plot(Data_TabulatedHumanTissues.MaterialParameters.Z_eff,...
        Data_TabulatedHumanTissues.MaterialParameters.I,'o','Color',...
        C_ref_tissues,'MarkerFaceColor',C_ref_tissues)
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

    close(gcf)

    %Plot figure for relative electron density vs mean excitation energy
    %(I-value):
    figure('Position',[100,100,560,420],'Visible','off'), hold on
    plot(Data_TabulatedHumanTissues.MaterialParameters.RED,...
        Data_TabulatedHumanTissues.MaterialParameters.I,...
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

    close(gcf)
end

end
%% End of file