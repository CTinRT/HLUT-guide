function CTnumbers=fit_and_estimate_CTnumbers(CTnumbers,Data_Phantom,...
    Data_Elements,Data_water_air,recon_type,Data_TabulatedHumanTissues,...
    CTnumber_types)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function will fit the K-values for CT number estimation, following
% Schneider et al. (1996); DOI: 10.1088/0031-9155/41/1/009
% And calculate the estimated CT numbers for the tabulated human tissues
% and the phantom inserts (the latter only for accuracy evaluation.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Fit the K-values:

%Check that there are enough phantom inserts to perform the fits:
if strcmp(recon_type,'regular')
    if height(CTnumbers.Phantom)<4
        error('At least 4 phantom inserts are needed to perform the needed fitting procedures.')
    end
elseif strcmp(recon_type,'DD')
    if length(find(Data_Phantom.MaterialParameters.TissueGroupIndex<4))<4
        error(['At least 4 non-bone (i.e. lung, adipose, and soft tissue) ',...
            'phantom inserts are needed to perform the needed fitting procedures.'])
    elseif length(find(Data_Phantom.MaterialParameters.TissueGroupIndex==4))<4
        error(['At least 4 bone phantom inserts are needed to perform the ',...
            'needed fitting procedures.'])
    end
end

%Create struct to save data:
K_values=struct;

%Loop over the three different sets of CT numbers:
for i=1:length(CTnumber_types)
    if strcmp(recon_type,'regular')
        K_values.(CTnumber_types{i})=fit_K_values(CTnumbers.Phantom...
            .(['CTnumbers_',CTnumber_types{i}]),Data_Phantom.wi,Data_Elements.Zi,...
            Data_Elements.Ai,Data_Phantom.MaterialParameters.Density,...
            Data_water_air);
    elseif strcmp(recon_type,'DD')
        soft_tissue=Data_Phantom.MaterialParameters.TissueGroupIndex<4;
        CTnumbers_phantom_soft=CTnumbers.Phantom...
            .(['CTnumbers_',CTnumber_types{i}])(soft_tissue);
        K_values.(CTnumber_types{i}).soft=fit_K_values(CTnumbers_phantom_soft,...
            Data_Phantom.wi(soft_tissue,:),Data_Elements.Zi,Data_Elements.Ai,...
            Data_Phantom.MaterialParameters.Density(soft_tissue),Data_water_air);

        bone_tissue=Data_Phantom.MaterialParameters.TissueGroupIndex==4;
        CTnumbers_phantom_bone=CTnumbers.Phantom...
            .(['CTnumbers_',CTnumber_types{i}])(bone_tissue);
        K_values.(CTnumber_types{i}).bone=fit_K_values(CTnumbers_phantom_bone,...
            Data_Phantom.wi(bone_tissue,:),Data_Elements.Zi,Data_Elements.Ai,...
            Data_Phantom.MaterialParameters.Density(bone_tissue),Data_water_air);
    end
end

%% Calculate the estimated CT numbers for the tabulated human tissues:

%Create table to store the data:
CTnumbers.TabulatedHumanTissues=table;
CTnumbers.TabulatedHumanTissues.Tissue_names=Data_TabulatedHumanTissues...
    .MaterialParameters.Tissue_names;

%Loop over the CT number types, and estimate the CT numbers for the
%tabulated human tissues for each of the types:
for i=1:length(CTnumber_types)
    if strcmp(recon_type,'regular')
        all_tissues=true(height(Data_TabulatedHumanTissues.MaterialParameters),1);
        CTnumbers.TabulatedHumanTissues.(['CTnumbers_',CTnumber_types{i},...
            '_estimated'])=Calculate_estimated_CTnumbers(K_values.(CTnumber_types{i}),...
            Data_TabulatedHumanTissues,Data_Elements,Data_water_air,all_tissues);
    elseif strcmp(recon_type,'DD')
        soft_tissue=Data_TabulatedHumanTissues.MaterialParameters.TissueGroupIndex<4;
        CTnumbers_soft=Calculate_estimated_CTnumbers(K_values.(CTnumber_types{i}).soft,...
            Data_TabulatedHumanTissues,Data_Elements,Data_water_air,soft_tissue);
        bone_tissue=Data_TabulatedHumanTissues.MaterialParameters.TissueGroupIndex==4;
        CTnumbers_bone=Calculate_estimated_CTnumbers(K_values.(CTnumber_types{i}).bone,...
            Data_TabulatedHumanTissues,Data_Elements,Data_water_air,bone_tissue);
        CTnumbers.TabulatedHumanTissues.(['CTnumbers_',CTnumber_types{i},...
            '_estimated'])=[CTnumbers_soft;CTnumbers_bone];
    end
end

%% Calculate the estimated CT numbers for the phantom inserts - for accuracy check:

for i=1:length(CTnumber_types)
    if strcmp(recon_type,'regular')
        all_tissues=true(height(Data_Phantom.MaterialParameters),1);
        CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i},'_estimated'])=...
            Calculate_estimated_CTnumbers(K_values.(CTnumber_types{i}),...
            Data_Phantom,Data_Elements,Data_water_air,all_tissues);
    elseif strcmp(recon_type,'DD')
        soft_tissue=Data_Phantom.MaterialParameters.TissueGroupIndex<4;
        CTnumbers_soft=Calculate_estimated_CTnumbers(K_values.(CTnumber_types{i}).soft,...
            Data_Phantom,Data_Elements,Data_water_air,soft_tissue);
        bone_tissue=Data_Phantom.MaterialParameters.TissueGroupIndex==4;
        CTnumbers_bone=Calculate_estimated_CTnumbers(K_values.(CTnumber_types{i}).bone,...
            Data_Phantom,Data_Elements,Data_water_air,bone_tissue);
        CTnumbers.Phantom.(['CTnumbers_',CTnumber_types{i},...
            '_estimated'])=[CTnumbers_soft;CTnumbers_bone];
    end
end

end


function K_values=fit_K_values(CTnumbers_phantom,wi_phantom,Zi_phantom,...
    Ai_phantom,Density_phantom,Data_water_air)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The fitting procedure in this file follows the equations presented in 
% Schneider et al. (1996); DOI: 10.1088/0031-9155/41/1/009
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Make fit to find the 3 K parameters:

%Calculate parameters for the calibration materials and for water, to be 
%used for the calibration:
[Z_tilde_3_62_phantom,Z_hat_1_86_phantom,Ng_phantom]=...
    compute_CTspectrum_characterization_parameters(wi_phantom,Zi_phantom,...
    Ai_phantom);
[Z_tilde_3_62_w,Z_hat_1_86_w,Ng_w]=...
    compute_CTspectrum_characterization_parameters(Data_water_air.water.wi,...
    Data_water_air.water.Zi,Data_water_air.water.Ai);

%Initial K-value guesses for the linear least square:
K_0=[10^(-5);10^(-4);0.5];

%Upper and lower bound on the K-values:
lb_K=zeros(3,1);
ub_K=10*ones(3,1);

%Optimization settings:
opts=optimoptions(@lsqnonlin,'Display','off','FunctionTolerance',1e-8,...
    'StepTolerance',1e-8);

%Perform non-linear least square fitting to find the K-values:
K_values=lsqnonlin(@(K)Fitting_function_K_values(K,CTnumbers_phantom,...
    Density_phantom,Ng_phantom,Z_tilde_3_62_phantom,Z_hat_1_86_phantom,...
    Data_water_air.water.Density,Ng_w,Z_tilde_3_62_w,Z_hat_1_86_w),...
    K_0,lb_K,ub_K,opts);

end


function varargout=compute_CTspectrum_characterization_parameters(wi,Zi,Ai)

% This function computes the CT energy spectrum characterization parameters
% following the equations presented in Schneider et al. (1996); 
% DOI: 10.1088/0031-9155/41/1/009

%% Computes  CT energy spectrum characterization parameters:

Z_tilde_3_62=(wi*(Zi.^(3.62+1)./Ai)./(wi*(Zi./Ai)));
Z_hat_1_86=(wi*(Zi.^(1.86+1)./Ai)./(wi*(Zi./Ai)));
Ng=wi*(Zi./Ai);

%% Define output from this function:

varargout={Z_tilde_3_62,Z_hat_1_86,Ng};

end


function F=Fitting_function_K_values(K_values,CTnumber,rho,Ng,Z_tilde_3_62,...
    Z_hat_1_86,rho_w,Ng_w,Z_tilde_3_62_w,Z_hat_1_86_w)

% This function will compute the objective function for the fitting
% procedure to determine the K-values used to estimate the CT numbers.

%% Fitting function:

mu=compute_mu(rho,Ng,Z_tilde_3_62,Z_hat_1_86,K_values);
mu_w=compute_mu(rho_w,Ng_w,Z_tilde_3_62_w,Z_hat_1_86_w,K_values);

F=CTnumber-1000*(mu/mu_w-1);

end


function mu=compute_mu(rho,Ng,Z_tilde_3_62,Z_hat_1_86,K_values)

% This function will compute linear attenuation coefficient.

%% Compute linear attenuation coefficient:

mu=rho.*Ng.*(K_values(1)*Z_tilde_3_62+K_values(2)*Z_hat_1_86+K_values(3));

end


function CTnumbers_estimated=Calculate_estimated_CTnumbers(K_values,...
    Data_mat,Data_Elements,Data_water_air,inserts)

% In this function, the estimated CT numbers are calculated based on the 
% fitted K-values, found as described in Schneider et al. (1996).
% DOI: 10.1088/0031-9155/41/1/009

%% Calculate estimated CT numbers based on 3 K parameters:

%Calculate parameters for material:
[Z_tilde_3_62_mat,Z_hat_1_86_mat,Ng_mat]=...
    compute_CTspectrum_characterization_parameters(Data_mat.wi(inserts,:),...
    Data_Elements.Zi,Data_Elements.Ai);
%Calculate parameters for water:
[Z_tilde_3_62_w,Z_hat_1_86_w,Ng_w]=...
    compute_CTspectrum_characterization_parameters(Data_water_air.water.wi,...
    Data_water_air.water.Zi,Data_water_air.water.Ai);

%Compute the linear attenuation coefficients for the energy spectrum
%described by the K-values:
mu_mat=compute_mu(Data_mat.MaterialParameters.Density(inserts),Ng_mat,...
    Z_tilde_3_62_mat,Z_hat_1_86_mat,K_values);
mu_w=compute_mu(Data_water_air.water.Density,Ng_w,Z_tilde_3_62_w,...
    Z_hat_1_86_w,K_values);

CTnumbers_estimated=1000*(mu_mat/mu_w-1);

end