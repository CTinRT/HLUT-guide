function varargout=compute_CTspectrum_characterization_parameters(wi,Zi,Ai)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function computes the CT energy spectrum characterization parameters
% following the equations presented in Schneider et al. (1996); 
% DOI: 10.1088/0031-9155/41/1/009
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Computes  CT energy spectrum characterization parameters:

Z_tilde_3_62=(wi*(Zi.^(3.62+1)./Ai)./(wi*(Zi./Ai)));
Z_hat_1_86=(wi*(Zi.^(1.86+1)./Ai)./(wi*(Zi./Ai)));
Ng=wi*(Zi./Ai);

%% Define output from this function:

varargout={Z_tilde_3_62,Z_hat_1_86,Ng};

end