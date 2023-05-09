function F=Fitting_function_K_values(K_values,CTnumber,rho,Ng,Z_tilde_3_62,...
    Z_hat_1_86,rho_w,Ng_w,Z_tilde_3_62_w,Z_hat_1_86_w)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function will compute the objective function for the fitting
% procedure to determine the K-values used to estimate the CT numbers.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fitting function:

mu=compute_mu(rho,Ng,Z_tilde_3_62,Z_hat_1_86,K_values);
mu_w=compute_mu(rho_w,Ng_w,Z_tilde_3_62_w,Z_hat_1_86_w,K_values);

F=CTnumber-1000*(mu/mu_w-1);

end