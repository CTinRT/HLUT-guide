function CTnumbers_estimated=Calculate_estimated_CTnumbers(K_values,...
    Data_mat,Data_Elements,Data_water)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% In this file, the estimated CT numbers are computed based on the fitted
% K-values, found as described in Schneider et al. (1996).
% DOI: 10.1088/0031-9155/41/1/009
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculate estimated CT numbers based on 3 K parameters:

%Calculate parameters for material:
[Z_tilde_3_62_mat,Z_hat_1_86_mat,Ng_mat]=...
    compute_CTspectrum_characterization_parameters(Data_mat.wi,...
    Data_Elements.Zi,Data_Elements.Ai);
%Calculate parameters for water:
[Z_tilde_3_62_w,Z_hat_1_86_w,Ng_w]=...
    compute_CTspectrum_characterization_parameters(Data_water.wi,...
    Data_water.Zi,Data_water.Ai);

%Compute the linear attenuation coefficients for the energy spectrum
%described by the K-values:
mu_mat=compute_mu(Data_mat.MaterialParameters.Density,Ng_mat,...
    Z_tilde_3_62_mat,Z_hat_1_86_mat,K_values);
mu_w=compute_mu(Data_water.Density,Ng_w,Z_tilde_3_62_w,Z_hat_1_86_w,K_values);

CTnumbers_estimated=1000*(mu_mat/mu_w-1);

end