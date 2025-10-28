function varargout=Test_HLUT_accuracy(Output,CTnumbers,Data_Phantom,...
    Data_TabulatedHumanTissues,HLUTs,Data_Results)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Step 6: Evaluation of HLUT specification - End-to-end test
%   This function computes the accuracy of the generated HLUTs - for the
%   body-site specific HLUTs as well as for the average HLUT. The results
%   are expressed both numerically and visualized with a figure.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute the estimated Output values for the data used to generate the HLUT:

test_types={'Head_vs_Head','Head_vs_Average','Body_vs_Body',...
    'Body_vs_Average'};

%Create empty matrix to save the results for the deviations for the
%individual datapoints (reference value compared to value estimated using
%the HLUT). For the MD HLUTs, the datapoints only include the tabulated
%human tissues, and not the phantom inserts, as these are also not included
%in the HLUT fitting process.
if strcmp(Output.Variable,'MD')
    Output_estimation=zeros(length(Output.TabulatedHumanTissues.Tissue_names),...
        length(test_types));
else
    Output_estimation=zeros(length(Output.Phantom.Insert_names)+...
        length(Output.TabulatedHumanTissues.Tissue_names),length(test_types));
end
Output_deviation=zeros(size(Output_estimation));

for i=1:length(test_types)
    tmp=strsplit(test_types{i},'_');
    CTnumber_type=tmp{1};
    HLUT_type=tmp{end};
    
    %Estimate the Output values based on the HLUT:
    %Phantom:
    Output.Phantom.([Output.Variable,'_',HLUT_type,'_HLUT_for_',...
        CTnumber_type,'_CTN'])=interp1(...
        HLUTs.ConnectionPoints.(HLUT_type).CTnumber,...
        HLUTs.ConnectionPoints.(HLUT_type).(Output.Variable),...
        CTnumbers.Phantom.(['CTnumbers_',CTnumber_type]));
    %Tabulated human tissues:
    Output.TabulatedHumanTissues.([Output.Variable,'_',HLUT_type,...
        '_HLUT_for_',CTnumber_type,'_CTN'])=...
        interp1(HLUTs.ConnectionPoints.(HLUT_type).CTnumber,...
        HLUTs.ConnectionPoints.(HLUT_type).(Output.Variable),...
        CTnumbers.TabulatedHumanTissues.(['CTnumbers_',CTnumber_type,...
        '_estimated']));
    
    %Create the full list of HLUT estimations, based on the datapoints used
    %for fitting the curve (only tabulated human tissues for MD HLUTs, and
    %both phantom inserts and tabulated human tissues for RED and SPR
    %HLUTs). And compute the deviation from the ground truth relative to water
    %(MD_water/RED_water/SPR_water = 1), given as: 
    %       dev=(Output_HLUT-Output_true)*100%:
    if strcmp(Output.Variable,'MD')
        Output_estimation(:,i)=Output.TabulatedHumanTissues.([Output.Variable,...
            '_',HLUT_type,'_HLUT_for_',CTnumber_type,'_CTN']);
        Output_deviation(:,i)=(Output_estimation(:,i)-...
            Output.TabulatedHumanTissues.Output)*100;
    else
        Output_estimation(:,i)=[Output.Phantom.([Output.Variable,'_',HLUT_type,...
            '_HLUT_for_',CTnumber_type,'_CTN']);...
            Output.TabulatedHumanTissues.([Output.Variable,'_',HLUT_type,...
            '_HLUT_for_',CTnumber_type,'_CTN'])];
        Output_deviation(:,i)=(Output_estimation(:,i)-[Output.Phantom.Output;...
            Output.TabulatedHumanTissues.Output])*100;
    end
end
 
%% Divide the errors into the four separate tissue types, and compute HLUT accuracy:

Data_Results.HLUT_fitting_accuracy=struct;

tissue_types={'All','Lung','Adipose','Soft','Bone'};

Metrics={'Mean error (%)';'Mean absolute error (%)';'RMSE (%)'};

for i=1:length(test_types)
    Output_accuracy=cell(length(Metrics),length(tissue_types)+1);
    for j=1:length(Metrics), Output_accuracy{j,1}=Metrics{j}; end
    
    for j=1:length(tissue_types)
        if strcmp(tissue_types{j},'All')
            Output_dev_j=Output_deviation(:,i);
        else
            if strcmp(Output.Variable,'MD')
                index_tissuegroup=Data_TabulatedHumanTissues...
                    .MaterialParameters.TissueGroupIndex==j-1;
            else
                index_tissuegroup=[Data_Phantom.MaterialParameters.TissueGroupIndex;...
                    Data_TabulatedHumanTissues.MaterialParameters.TissueGroupIndex]==j-1;
            end
            Output_dev_j=Output_deviation(index_tissuegroup,i);
        end
        
        %Mean error (%):
        Output_acc=mean(Output_dev_j);
        Output_accuracy{1,j+1}=str2double(num2str(Output_acc,'%.2f'));
        
        %Mean absolute error (%):
        Output_acc=mean(abs(Output_dev_j));
        Output_accuracy{2,j+1}=str2double(num2str(Output_acc,'%.2f'));
        
        %RMSE (%):
        Output_acc=sqrt(sum(Output_dev_j.^2)/length(Output_dev_j));
        Output_accuracy{3,j+1}=str2double(num2str(Output_acc,'%.2f'));
    end  
    
    %Save the results:
    Data_Results.HLUT_fitting_accuracy.(test_types{i})=cell2table(Output_accuracy);
    
    %Insert table headings:
    Data_Results.HLUT_fitting_accuracy.(test_types{i}).Properties.VariableNames=...
        {'Metric','All tissues','Lung','Adipose','Soft tissue','Bone'};
    
    % %Output results to command window (Remove % in front of the seven following lines, if output is wanted):
    % %Write out the HLUT fitting accuracy:
    % tmp=strsplit(test_types{i},'_');
    % CTnumber_type=tmp{1};
    % HLUT_type=tmp{end};
    % disp(' '),disp(['HLUT fitting accuracy for <strong>',HLUT_type,' HLUT on ',...
    %     CTnumber_type,' CT numbers</strong>:'])
    % disp(Data_Results.HLUT_fitting_accuracy.(test_types{i}))
end

%% Plot box plots for HLUT accuracy per tissue group:

%Define colors:
Colors_all=[0,0.447,0.741;0.301,0.745,0.933;0,0.5,0;0.466,0.674,0.188];

marker_size=15;

figure('Position',[100,100,960,420],'Visible','off'), hold on

%Plot boxplots for HLUT accuracy each tissue group:
for i=1:length(test_types)
    for j=1:length(tissue_types)-1
        if strcmp(Output.Variable,'MD')
            index_tissuegroup=Data_TabulatedHumanTissues...
                .MaterialParameters.TissueGroupIndex==j;
        else
            index_tissuegroup=[Data_Phantom.MaterialParameters.TissueGroupIndex;...
                Data_TabulatedHumanTissues.MaterialParameters.TissueGroupIndex]==j;
        end
        Output_dev_j=Output_deviation(index_tissuegroup,i);
        if length(Output_dev_j)<=5
            %If less than 5 data points, plot the deviations individually:
            
            %Plot horisontal line at zero deviation:
            plot([j-0.5,j+0.5],[0,0],'k')

            %Define x-coordinate for datapoints:
            if i==1, x_i=j-0.21; elseif i==2, x_i=j-0.07; 
            elseif i==3, x_i=j+0.07; elseif i==4, x_i=j+0.21; end
            
            plot(x_i*ones(1,length(Output_dev_j)),Output_dev_j,'.','Color',Colors_all(i,:),...
                'MarkerSize',marker_size,'MarkerFaceColor',Colors_all(i,:))
            
        else
            %If more than 5 datapoints, plot boxplots for the deviations:
            
            %Plot horisontal line at zero deviation, but not behind the
            %boxplots:
            plot([j-0.5,j-0.375],[0,0],'k')
            plot([j-0.225,j-0.175],[0,0],'k')
            plot([j-0.025,j+0.025],[0,0],'k')
            plot([j+0.175,j+0.225],[0,0],'k')
            plot([j+0.375,j+0.5],[0,0],'k')
            
            %Define x-coordinate:
            if i==1, x_i=j-0.3; elseif i==2, x_i=j-0.1; 
            elseif i==3, x_i=j+0.1; elseif i==4, x_i=j+0.3; end
            
            boxplot(Output_dev_j,'Positions',x_i)
            
            %Plot marker to show the mean deviation on top of the boxplot:
            plot(x_i,mean(Output_dev_j),'s','Color',Colors_all(i,:),...
                'MarkerFaceColor',Colors_all(i,:))

        end
    end
end

set(gca,'FontSize',12,'xtick',1:4,'XTickLabel',{'Lung','Adipose',...
    'Soft tissue','Bone'},'Position',[0.08,0.1,0.9,0.83])

if strcmp(Output.Variable,'MD')
    ylabel(['\DeltaMD = MD_H_L_U_T ',char(8210),' MD_r_e_f  (%)'])
elseif strcmp(Output.Variable,'RED')
    ylabel(['\DeltaRED = RED_H_L_U_T ',char(8210),' RED_r_e_f  (%)'])
elseif strcmp(Output.Variable,'SPR')
    ylabel(['\DeltaSPR = SPR_H_L_U_T ',char(8210),' SPR_r_e_f  (%)'])
end
title([Output.Variable,' accuracy with size-specific or average HLUT'],'FontSize',16)

xlim([0.5,4.5])

%Set y-limits:
all_dev=Output_deviation(:,1:4);
YLim_i=[floor(min(all_dev(:))*10)/10;ceil(max(all_dev(:))*10)/10];
ylim(YLim_i)

%Prettify the boxplots: 
gg=get(gca);
gc=gg.Children;
for i=1:length(gc)
    if strcmp(gc(i).Tag,'boxplot')        
        %Find color:
        if ismember(gc(i).Children(6).XData(1),[0.7,1.7,2.7,3.7])
            cc=Colors_all(1,:);
        elseif ismember(gc(i).Children(6).XData(1),[0.9,1.9,2.9,3.9])
            cc=Colors_all(2,:);
        elseif ismember(gc(i).Children(6).XData(1),[1.1,2.1,3.1,4.1])
            cc=Colors_all(3,:);
        elseif ismember(gc(i).Children(6).XData(1),[1.3,2.3,3.3,4.3])
            cc=Colors_all(4,:);
        else
            error('???')
        end
        
        %Box:
        gc(i).Children(3).Color=cc;
        gc(i).Children(3).LineWidth=1.5;
        %Median:
        gc(i).Children(2).LineWidth=1.5;
        gc(i).Children(2).Color=cc;
        %Whiskers:
        gc(i).Children(6).LineStyle='-';
        gc(i).Children(7).LineStyle='-';
        gc(i).Children(4).Color=cc;
        gc(i).Children(5).Color=cc;
        gc(i).Children(6).Color=cc;
        gc(i).Children(7).Color=cc;
        gc(i).Children(4).LineWidth=1.5;
        gc(i).Children(5).LineWidth=1.5;
        gc(i).Children(6).LineWidth=1.5;
        gc(i).Children(7).LineWidth=1.5;
        %Outliers:
        gc(i).Children(1).MarkerEdgeColor=cc;
        
        %Background color:
        patch('XData',gc(i).Children(3).XData(1:end-1),'YData',...
            gc(i).Children(3).YData(1:end-1),'FaceColor',cc,...
            'FaceAlpha',0.3,'EdgeColor','none');
        
        %Add black line at y=0, if box does not cross y=0:
        if gc(i).Children(3).YData(1)<0 && gc(i).Children(3).YData(2)<0 || ...
                gc(i).Children(3).YData(1)>0 && gc(i).Children(3).YData(2)>0
            plot([gc(i).Children(3).XData(1),gc(i).Children(3).XData(3)],[0,0],'k')
        end
        
    end
end

%Create legend:
h=gobjects(1,length(test_types));
legendtext=string.empty;
for i=1:length(test_types)
    h(i)=plot(-10,-10,'o','Color',Colors_all(i,:),'MarkerFaceColor',...
        Colors_all(i,:),'MarkerSize',5);
    
    tmp=strsplit(test_types{i},'_');
    CTnumber_type=tmp{1};
    HLUT_type=tmp{end};
    legendtext{i}=['CTN ',CTnumber_type,', HLUT ',HLUT_type];
end
legend(h,legendtext,'Location','northwest','FontSize',11)

%% Save figure:

Data_Results.HLUT_fitting_accuracy.FileName_HLUT_accuracy_figure=...
    [Data_Results.Output_Folder_Name,filesep,'Eval_Step_6_HLUT_',...
    Output.Variable,'_accuracy.png'];
saveas(gcf,Data_Results.HLUT_fitting_accuracy.FileName_HLUT_accuracy_figure)

close(gcf)

%% Define output from this function:

varargout={Data_Results,Output};

end