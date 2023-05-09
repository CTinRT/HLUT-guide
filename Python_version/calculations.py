# -*- coding: utf-8 -*-
"""
Calculation functions for the HLUT definition, to be used in main.py
Python implementation: Nils Peters
Matlab implementation: Vicki Taasti
Version 1.0, 05/08/2023

% SPDX-License-Identifier: MIT
"""

import pandas as pd
import numpy as np
from scipy.optimize import least_squares
import math


def import_initialdata():
    """
    Initialize phantom-independent parameters and load elements
    Input:  datasheet  - Dictionary containing data from excel sheets
    Output: rho_w, zi_w, ai_w, wi_w, ii_w, e_0, m_e, elements - parameters for the respective elements
    """

    global rho_w, zi_w, ai_w, wi_w, ii_w, elements, e_0, m_e
    
    # Input data for water:
    rho_w = 1                                # mass density
    zi_w = np.array([1, 8])                  # Atomic number of components
    ai_w = np.array([1.008, 15.999])         # Atomic mass of components
    wi_w = np.array([0.111894, 0.888106])    # Weight fraction of components
    ii_w = np.array([19.2, 106])             # mean excitation energy of comp.

    e_0 = 938                             # Rest mass of protons in MeV
    m_e = 511*10**3                       # Rest mass of electron in eV

    elements = ['H', 'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Na', 'Mg', 'Al', 'Si', 'P', 'S', 'Cl', 'K', 'Ca',
                'Ti', 'Fe', 'Zn', 'I', 'Ba']  # Elements to be considered from excel sheet
        
    return rho_w, zi_w, ai_w, wi_w, ii_w, e_0, m_e, elements


def spr_calculation(datasheet, e_kin, dataset):
    """
    Calculate the SPR, RED and EAN for materials in the excel sheet
    Input:  datasheet  - Dictionary containing data from excel sheets
            e_kin - Initial energy of protons in MeV, guide: 100 MeV
            dataset - either PhantomInserts or TabulatedHumanTissues
    Output: spr_theor, rho_e_mat, zeff_mat, i_mat array - parameters for the respective materials
    """
    global spr_num, spr_den

    # Load relevant data from datasheet
    density_mat = np.array(datasheet[dataset]['Density (g/cm3)'])  # mass density
    zi = np.array(datasheet['ElementParameters']['Zi'])  # atomic numbers
    ai = np.array(datasheet['ElementParameters']['Ai'])  # atomic mass
    ii = np.array(datasheet['ElementParameters']['Ii'])  # mean excitation energy

    wi_mat = np.array(pd.DataFrame(datasheet[dataset], columns=elements))  # weight fraction
    
    # Calculate relative electron density for materials    
    rho_e_mat = (density_mat * np.matmul(wi_mat, (zi/ai)) / (rho_w * np.matmul(wi_w, zi_w/ai_w)))
    
    # Calculate effective atomic number
    beta_zeff = 3.1  # Parameter for the power equation
    zeff_mat = (np.matmul(wi_mat, zi**(beta_zeff+1)/ai) / np.matmul(wi_mat, zi/ai))**(1/beta_zeff)

    # Calculate ln(I) for materials and for water
    ln_i_mat = (np.matmul(wi_mat, ((zi/ai)*np.log(ii))) / np.matmul(wi_mat, (zi/ai)))
    ln_i_w = (np.matmul(wi_w, ((zi_w/ai_w)*np.log(ii_w))) / np.matmul(wi_w, (zi_w/ai_w)))

    # Calculate mean excitation energy I following Bragg rule
    i_mat = np.exp(ln_i_mat)
    
    # Calculate relativistic beta squared
    beta_sq = 1 - (e_kin/e_0 + 1)**(-2)
    
    # Calculate SPR values
    spr_num = np.log(2*m_e) + np.log(beta_sq/(1-beta_sq)) - beta_sq
    spr_den = np.log(2*m_e) + np.log(beta_sq/(1-beta_sq)) - ln_i_w - beta_sq
    spr_theor = rho_e_mat * (spr_num - ln_i_mat) / spr_den

    return spr_theor, rho_e_mat, zeff_mat, i_mat


def k_value_formulas(wi_mat, zi, ai):
    """
    Formulas used in k_value_fit and ctn_calculation
    Input:  wi_mat, zi, ai, wi_w, zi_w, ai_w - elemental composition parameters of the respective materials
    Output: z_tilde, z_tilde_w, z_hat, z_hat_w, ng, ng_w - material parameters
    """

    # Calculate values of Eq. 9 and Eq 10 in source for tissues
    z_tilde = np.matmul(wi_mat, zi**(3.62+1)/ai) / np.matmul(wi_mat, (zi/ai))
    z_hat = np.matmul(wi_mat, zi**(1.86+1)/ai) / np.matmul(wi_mat, (zi/ai))
    ng = np.matmul(wi_mat, (zi/ai))

    # Calculate values of Eq. 9 and Eq 10 in source for water
    z_tilde_w = (np.matmul(wi_w, zi_w**(3.62+1)/ai_w) / np.matmul(wi_w, (zi_w/ai_w)))
    z_hat_w = (np.matmul(wi_w, zi_w**(1.86+1)/ai_w) / np.matmul(wi_w, (zi_w/ai_w)))
    ng_w = np.matmul(wi_w, (zi_w/ai_w))
    
    return z_tilde, z_tilde_w, z_hat, z_hat_w, ng, ng_w


def k_value_fit(datasheet, phantom):
    """
    Performs the K value fit, following Schneider et al. 1996 (DOI: 10.1088/0031-9155/41/1/009)
    Input:  datasheet - Dictionary containing data from excel sheets
            phantom - Selection from which phantom CT numbers to be used        
    Output: k_values - fitted k values
    """
    
    # Load relevant data from datasheet
    density_mat = np.array(datasheet['PhantomInserts']['Density (g/cm3)'])
    zi = np.array(datasheet['ElementParameters']['Zi'])
    ai = np.array(datasheet['ElementParameters']['Ai'])
    ctn = np.array(datasheet['CTnumbers'][phantom])
    wi_mat = np.array(pd.DataFrame(datasheet['PhantomInserts'], columns=elements))
    
    # Calculate values for K fit from fit formulas
    z_tilde, z_tilde_w, z_hat, z_hat_w, ng, ng_w = (k_value_formulas(wi_mat, zi, ai))
    
    # Initiate K-value guesses for the linear least square approach
    k_0 = [10**(-5), 10**(-4), 0.5]

    # Set Upper and lower bound on the K-values
    lb_k = np.zeros(3)
    ub_k = 10*np.ones(3)
    
    k_values = least_squares(k_fit_function, k_0, bounds=[lb_k, ub_k],
                             args=[density_mat, ng, z_tilde, z_hat, ng_w, z_tilde_w, z_hat_w, ctn],
                             ftol=1e-8, xtol=1e-8, gtol=1e-8)
    return k_values


def k_fit_function(k, density_mat, ng, z_tilde, z_hat, ng_w, z_tilde_w, z_hat_w, ctn):
    """
    Function for the k fit, to be used in k_value_fit
    Input:  k - value to be fitted
            Rest: material parameters from k_value_formulas
    Output: F - fit function
    """
    
    mu = density_mat * ng * (k[0]*z_tilde + k[1]*z_hat + k[2])
    mu_w = rho_w * ng_w * (k[0]*z_tilde_w + k[1]*z_hat_w + k[2])

    return ctn-1000*(mu/mu_w - 1)


def ctn_calculation(datasheet, dataset, k_set):
    """
    Calculate CT numbers for tabulated human tissues
    Input:  datasheet - Dictionary containing data from excel sheets
            dataset - Either TabulatedHumanTissues or phantom data  
            k_set - fitted k values for head/body/avg from main script
    Returns ctn_calc - calculated CT number for the material
    """

    # Load relevant data from datasheet
    density_mat = np.array(datasheet[dataset]['Density (g/cm3)'])
    zi = np.array(datasheet['ElementParameters']['Zi'])
    ai = np.array(datasheet['ElementParameters']['Ai'])
    wi_mat = np.array(pd.DataFrame(datasheet[dataset], columns=elements))

    # Calculate values for CT number fit from fit formulas
    z_tilde, z_tilde_w, z_hat, z_hat_w, ng, ng_w = (k_value_formulas(wi_mat, zi, ai))
    
    # Calculate mu from CTN-specific k set
    k = k_set
    mu = density_mat * ng * (k[0]*z_tilde + k[1]*z_hat + k[2])
    mu_w = rho_w * ng_w * (k[0]*z_tilde_w + k[1]*z_hat_w + k[2])

    return 1000*(mu/mu_w - 1)


def hlut_fit(datasheet, phantom_ctn, tabul_ctn):
    """
    Fit CT numbers and determine connection points
    Input:  datasheet  - Dictionary containing data from excel sheets
            phantom_ctn - CT numbers from head/body/avgd
            tabul_ctn - tabulated tissue CT numbers from head/body/avgd
    Output: cp_ctn, cp_spr - connection points (CTN, SPR)
            sprtype - Used SPR type, either calculated or measured
    """
    
    # Check if measured SPR data exists for phantom
    if np.isnan(datasheet['PhantomInserts']['SPR Measured'][0]):
        sprtype = 'SPR_calc'
    else:
        sprtype = 'SPR Measured'
    
    # Load and fit data
    # Initiate CT number and SPR lists
    ctn_lung, ctn_fat, ctn_soft, ctn_bone = [], [], [], []
    spr_lung, spr_fat, spr_soft, spr_bone = [], [], [], []

    # Add CT numbers and CTN from phantom
    indexlist = datasheet['PhantomInserts']['Tissue group']  # tissue grouping
    for i in range(len(indexlist)):
        if indexlist[i] == 1:
            ctn_lung.append(datasheet['CTnumbers'][phantom_ctn][i])
            spr_lung.append(datasheet['PhantomInserts'][sprtype][i])
        if indexlist[i] == 2:
            ctn_fat.append(datasheet['CTnumbers'][phantom_ctn][i])    
            spr_fat.append(datasheet['PhantomInserts'][sprtype][i])
        if indexlist[i] == 3:
            ctn_soft.append(datasheet['CTnumbers'][phantom_ctn][i])
            spr_soft.append(datasheet['PhantomInserts'][sprtype][i])
        if indexlist[i] == 4:
            ctn_bone.append(datasheet['CTnumbers'][phantom_ctn][i])
            spr_bone.append(datasheet['PhantomInserts'][sprtype][i])

    # Add calculated CT numbers from tabulated human tissues
    indexlist = datasheet['TabulatedHumanTissues']['Tissue group']  # tissue grouping
    for i in range(len(indexlist)):
        if indexlist[i] == 1:
            ctn_lung.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            spr_lung.append(datasheet['TabulatedHumanTissues']['SPR_calc'][i])
        if indexlist[i] == 2:
            ctn_fat.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])    
            spr_fat.append(datasheet['TabulatedHumanTissues']['SPR_calc'][i])
        if indexlist[i] == 3:
            ctn_soft.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            spr_soft.append(datasheet['TabulatedHumanTissues']['SPR_calc'][i])
        if indexlist[i] == 4:
            ctn_bone.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])    
            spr_bone.append(datasheet['TabulatedHumanTissues']['SPR_calc'][i])

    # Perform fit for each tissue group
    p_lung_soft = np.polyfit(ctn_lung+ctn_soft, spr_lung + spr_soft, 1)
    p_fat = np.polyfit(ctn_fat, spr_fat, 1)
    p_bone = np.polyfit(ctn_bone, spr_bone, 1)

    # Define connection points, following Table S1.4
    cp_ctn_lung = [-1024, -999, -950, np.round(min(ctn_fat) - 60)]  # contains air
    cp_ctn_fat = [np.round(min(ctn_fat) - 40), -30]
    cp_ctn_soft = [0, np.round(max(ctn_soft)) + 10] 
    if max(ctn_bone) > 2000:
        cp_ctn_bone = [np.round(min(ctn_bone) + 50), 
                       np.round(max(ctn_bone)) + 100] 
    else:
        cp_ctn_bone = [np.round(min(ctn_bone) + 50), 2000] 

    # Initialize array for the matching spr values
    cp_spr_lung, cp_spr_fat, cp_spr_soft, cp_spr_bone = [], [], [], []        

    # Calculate SPR for connection points
    for i in cp_ctn_lung:
        cp_spr_lung.append(np.polyval(p_lung_soft, i))
    for i in cp_ctn_fat:
        cp_spr_fat.append(np.polyval(p_fat, i))
    for i in cp_ctn_soft:
        cp_spr_soft.append(np.polyval(p_lung_soft, i))
    for i in cp_ctn_bone:
        cp_spr_bone.append(np.polyval(p_bone, i))
    
    # Adjust lowest SPR values for lung to value of air, following NIST data
    # from https://physics.nist.gov/cgi-bin/Star/compos.pl?matno=104

    rho_air = 1.20479E-03  # mass density
    zi_air = np.array([6, 7, 8, 18])  # atomic number of components
    ai_air = np.array([12.011, 14.007, 15.999, 39.948])  # atomic mass of components
    wi_air = np.array([0.000124, 0.755267, 0.231781, 0.012827])  # weight fractions
    i_air = 85.7  # mean excitation energy
    rho_e_air = (rho_air * np.matmul(wi_air, (zi_air/ai_air)) / (rho_w * np.matmul(wi_w, zi_w/ai_w)))
    spr_air = rho_e_air * (spr_num - np.log(i_air)) / spr_den

    cp_spr_lung[0], cp_spr_lung[1] = spr_air, spr_air
    
    # Define relevant digits in SPR
    spr_digits = 4  # number of digits to which to round the SPR
    offs = 1*10**(-spr_digits)  # SPR offset in case connecting points have the same value
    
    # Check to see if slope of the segment connections are always positive

    # Check slope between air and lung
    if cp_spr_lung[1] >= cp_spr_lung[2]:
        cp_ctn_lung[2] = math.ceil((cp_spr_lung[1] + offs - p_lung_soft[1])/p_lung_soft[0])
        cp_spr_lung[2] = cp_spr_lung[1] + offs

        note = "{} {} {}HU".format('--- The slope between air and lung tissue is negative or zero.',
                                   'The lowest lung tissue is increased to', cp_spr_lung[2])
        print(note)

    # Check slope between lung and adipose
    if np.polyval(p_lung_soft, cp_ctn_lung[-1]) >= np.polyval(p_fat, cp_ctn_fat[0]):
        print('--- The slope between lung and adipose is negative or zero. ' 
              'This should not happen. Please revise your input data.')

    # Check slope between Adipose and Soft Tissue
    if cp_spr_fat[-1] >= cp_spr_soft[0]:
        cp_ctn_fat[-1] = math.floor((cp_spr_soft[0] - offs - p_fat[1]) / p_fat[0])
        cp_spr_fat[-1] = np.polyval(p_fat, cp_ctn_fat[-1])

        note = "{} {} {}HU".format('--- The slope between adipose and soft tissue is negative or zero.',
                                   'The highest adipose value is thus lowered to', cp_ctn_fat[-1])
        print(note)
        
    # Slope between Soft Tissue and Bone
    if cp_spr_soft[-1] >= cp_spr_bone[0]:
        cp_ctn_bone[0] = math.floor((cp_spr_soft[-1] + offs - p_bone[1]) / p_bone[0])
        cp_ctn_bone[0] = np.polyval(p_bone, cp_ctn_bone[0])

        note = "{} {} {}HU".format('--- The slope between Soft Tissue and Bone is negative.',
                                   'The lowest bone value is increased to', cp_ctn_soft[-1])
        print(note)

    # Create overall list containing all numbers
    cp_ctn = cp_ctn_lung + cp_ctn_fat + cp_ctn_soft + cp_ctn_bone
    cp_spr = cp_spr_lung + cp_spr_fat + cp_spr_soft + cp_spr_bone

    print('\nHLUT creation finished.')

    return cp_ctn, cp_spr, sprtype
