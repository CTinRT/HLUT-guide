function SPR_theo=Compute_theoretical_SPR(E_kin,Density,wi,...
    Zi,Ai,Ii,Data_water,Bragg_yn)

% SPDX-License-Identifier: MIT

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function computes the theoretical SPR based on the Bethe equation.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute theoretical SPR:

%Relative electron density:
rho_e=compute_material_parameters(Density,wi,Zi,Ai,[],Data_water,[],true,...
    false,false);

if Bragg_yn
    %Use the Bragg rule to calculate the logaritm of the I-value for compounds:
    [~,~,lnI]=compute_material_parameters([],wi,Zi,Ai,Ii,Data_water,[],...
        false,false,true);
else
    lnI=log(Ii);
end

%Stopping power:
%Parameters:
E_0=938;                                %Rest mass of proton (MeV)
m_e=511*10^3;                           %Rest mass of electron (eV)
%Relativistic beta squared:
beta2=1-(E_kin/E_0+1)^(-2);
%Use the Bragg rule to calculate the logaritm of the I-value for water:
lnI_water=(Data_water.wi*(Data_water.Zi.*log(Data_water.Ii)./Data_water.Ai))./...
    (Data_water.wi*(Data_water.Zi./Data_water.Ai));
%Stopping power ratio relative to water:
%Constant in numerator:
SPR_num=log(2*m_e)+log(beta2/(1-beta2))-beta2;
%Denominator:
SPR_den=(log(2*m_e)+log(beta2/(1-beta2))-lnI_water-beta2);

%SPR:
SPR_theo=rho_e.*(SPR_num-lnI)/SPR_den;

end