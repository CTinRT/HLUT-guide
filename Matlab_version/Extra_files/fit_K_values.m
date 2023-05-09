function K_values=fit_K_values(CTnumbers_phantom,wi_phantom,Zi_phantom,...
    Ai_phantom,Density_phantom,Data_water)

% SPDX-License-Identifier: MIT

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
    compute_CTspectrum_characterization_parameters(Data_water.wi,...
    Data_water.Zi,Data_water.Ai);

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
    Data_water.Density,Ng_w,Z_tilde_3_62_w,Z_hat_1_86_w),K_0,lb_K,ub_K,opts);

%% End of file
end