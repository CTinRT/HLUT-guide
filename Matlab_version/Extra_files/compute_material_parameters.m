function varargout=compute_material_parameters(Density,wi,Zi,Ai,Ii,...
    Data_water,beta_Zeff,rho_e_yn,Z_eff_yn,lnI_yn)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function computes the theoretical material parameters of importance
% for proton therapy, the relative electron density, the effective atomic
% number, and the mean excitation energy. (A separate function  called 
% "Compute_theoretical_SPR.m" computes the theoretical SPR).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute material parameters:

%Relative electron density:
if rho_e_yn
    rho_e=Density.*(wi*(Zi./Ai))/(Data_water.Density*(Data_water.wi*...
        (Data_water.Zi./Data_water.Ai)));
else
    rho_e=[];
end

%Effective atomic number:
if Z_eff_yn
    Z_eff=(wi*(Zi.^(beta_Zeff+1)./Ai)./(wi*(Zi./Ai))).^(1/beta_Zeff);
else
    Z_eff=[];
end

%Mean excitation energy - Bragg rule:
if lnI_yn
    lnI=(wi*(Zi.*log(Ii)./Ai))./(wi*(Zi./Ai));
else
    lnI=[];
end

%% Define output from this function:

varargout={rho_e,Z_eff,lnI};

end