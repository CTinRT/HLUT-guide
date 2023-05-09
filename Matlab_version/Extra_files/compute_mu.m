function mu=compute_mu(rho,Ng,Z_tilde_3_62,Z_hat_1_86,K_values)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function will compute linear attenuation coefficient.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute linear attenuation coefficient:

mu=rho.*Ng.*(K_values(1)*Z_tilde_3_62+K_values(2)*Z_hat_1_86+K_values(3));

end