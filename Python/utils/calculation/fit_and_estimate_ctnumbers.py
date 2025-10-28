# -*- coding: utf-8 -*-
"""
Fit and estimation of CT numbers

% SPDX-License-Identifier: MIT
"""

import pandas as pd
import numpy as np
from scipy.optimize import least_squares


def main(datasheet, recon_type):
    """
    Make fits based on the CT numbers for the phantom inserts and estimate
    CT numbers for tabulated human tissues and the phantom inserts (the latter
    only for accuracy evaluation).
    If recon_type=='DD', the fit is split in two - one for bones and one for none-bones.
    Input:  datasheet  - Dictionary containing data from excel sheets
            recon_type   - Reconstruction type
    Output: datasheet which has been addended with the estimated CT numbers.
    """

    # Check that there are enough phantom inserts to perform the fits:
    if recon_type == 'regular':
        if len(datasheet['PhantomInserts'] ) <4:
            raise ValueError("At least 4 phantom inserts are needed to perform the needed fitting procedures.")
    elif recon_type == 'DD':
        if (datasheet['PhantomInserts']['Tissue group'] < 4).sum( ) <4:
            raise ValueError \
                ("At least 4 non-bone (i.e. lung, adipose, and soft tissue) phantom inserts are needed to perform the needed fitting procedures.")
        elif (datasheet['PhantomInserts']['Tissue group'] == 4).sum( ) <4:
            raise ValueError("At least 4 bone phantom inserts are needed to perform the needed fitting procedures.")

    # Fit k values for stoichiometric calibration:
    if recon_type == 'regular':
        inserts = np.ones(len(datasheet['PhantomInserts']), dtype=bool)
        k_head = k_value_fit(datasheet, 'CT number (Head)', inserts)
        k_body = k_value_fit(datasheet, 'CT number (Body)', inserts)
        k_avgCT = k_value_fit(datasheet, 'CT number (averaged)', inserts)
    elif recon_type == 'DD':
        soft_tissue = datasheet['PhantomInserts']['Tissue group'] < 4
        bone_tissue = datasheet['PhantomInserts']['Tissue group'] == 4
        k_soft_head = k_value_fit(datasheet, 'CT number (Head)', soft_tissue)
        k_bone_head = k_value_fit(datasheet, 'CT number (Head)', bone_tissue)
        k_soft_body = k_value_fit(datasheet, 'CT number (Body)', soft_tissue)
        k_bone_body = k_value_fit(datasheet, 'CT number (Body)', bone_tissue)
        k_soft_avgCT = k_value_fit(datasheet, 'CT number (averaged)', soft_tissue)
        k_bone_avgCT = k_value_fit(datasheet, 'CT number (averaged)', bone_tissue)

    # Estimate CT numbers for the phantom inserts (for quality check)
    if recon_type == 'regular':
        datasheet['PhantomInserts']['ctn_calc_head'] = (
            ctn_calculation(datasheet, 'PhantomInserts', inserts, k_head))
        datasheet['PhantomInserts']['ctn_calc_body'] = (
            ctn_calculation(datasheet, 'PhantomInserts', inserts, k_body))
        datasheet['PhantomInserts']['ctn_calc_avgCT'] = (
            ctn_calculation(datasheet, 'PhantomInserts', inserts, k_avgCT))
    elif recon_type == 'DD':
        ctn_soft = (ctn_calculation(datasheet, 'PhantomInserts', soft_tissue, k_soft_head))
        ctn_bone = (ctn_calculation(datasheet, 'PhantomInserts', bone_tissue, k_bone_head))
        datasheet['PhantomInserts']['ctn_calc_head'] = np.concatenate((ctn_soft, ctn_bone))
        ctn_soft = (ctn_calculation(datasheet, 'PhantomInserts', soft_tissue, k_soft_body))
        ctn_bone = (ctn_calculation(datasheet, 'PhantomInserts', bone_tissue, k_bone_body))
        datasheet['PhantomInserts']['ctn_calc_body'] = np.concatenate((ctn_soft, ctn_bone))
        ctn_soft = (ctn_calculation(datasheet, 'PhantomInserts', soft_tissue, k_soft_avgCT))
        ctn_bone = (ctn_calculation(datasheet, 'PhantomInserts', bone_tissue, k_bone_avgCT))
        datasheet['PhantomInserts']['ctn_calc_avgCT'] = np.concatenate((ctn_soft, ctn_bone))

    # Estimate CT numbers for the tabulated human tissues
    if recon_type == 'regular':
        inserts = np.ones(len(datasheet['TabulatedHumanTissues']), dtype=bool)
        datasheet['TabulatedHumanTissues']['ctn_calc_head'] = (
            ctn_calculation(datasheet, 'TabulatedHumanTissues', inserts, k_head))
        datasheet['TabulatedHumanTissues']['ctn_calc_body'] = (
            ctn_calculation(datasheet, 'TabulatedHumanTissues', inserts, k_body))
        datasheet['TabulatedHumanTissues']['ctn_calc_avgCT'] = (
            ctn_calculation(datasheet, 'TabulatedHumanTissues', inserts, k_avgCT))
    elif recon_type == 'DD':
        soft_tissue = datasheet['TabulatedHumanTissues']['Tissue group'] < 4
        bone_tissue = datasheet['TabulatedHumanTissues']['Tissue group'] == 4
        ctn_soft = (ctn_calculation(datasheet, 'TabulatedHumanTissues', soft_tissue, k_soft_head))
        ctn_bone = (ctn_calculation(datasheet, 'TabulatedHumanTissues', bone_tissue, k_bone_head))
        datasheet['TabulatedHumanTissues']['ctn_calc_head'] = np.concatenate((ctn_soft, ctn_bone))
        ctn_soft = (ctn_calculation(datasheet, 'TabulatedHumanTissues', soft_tissue, k_soft_body))
        ctn_bone = (ctn_calculation(datasheet, 'TabulatedHumanTissues', bone_tissue, k_bone_body))
        datasheet['TabulatedHumanTissues']['ctn_calc_body'] = np.concatenate((ctn_soft, ctn_bone))
        ctn_soft = (ctn_calculation(datasheet, 'TabulatedHumanTissues', soft_tissue, k_soft_avgCT))
        ctn_bone = (ctn_calculation(datasheet, 'TabulatedHumanTissues', bone_tissue, k_bone_avgCT))
        datasheet['TabulatedHumanTissues']['ctn_calc_avgCT'] = np.concatenate((ctn_soft, ctn_bone))

    return datasheet


def k_value_formulas(datasheet, wi_mat, zi, ai):
    """
    Formulas used in k_value_fit and ctn_calculation
    Input:  wi_mat, zi, ai - elemental composition parameters of the material
    Output: z_tilde, z_tilde_w, z_hat, z_hat_w, ng, ng_w - material parameters
    """

    # Load relevant data from datasheet
    wi_w = datasheet['Data_water']['wi_w']
    zi_w = datasheet['Data_water']['zi_w']
    ai_w = datasheet['Data_water']['ai_w']

    # Calculate values of Eq. 9 and Eq 10 in source for tissues
    z_tilde = np.matmul(wi_mat, zi ** (3.62 + 1) / ai) / np.matmul(wi_mat, (zi / ai))
    z_hat = np.matmul(wi_mat, zi ** (1.86 + 1) / ai) / np.matmul(wi_mat, (zi / ai))
    ng = np.matmul(wi_mat, (zi / ai))

    # Calculate values of Eq. 9 and Eq 10 in source for water
    z_tilde_w = (np.matmul(wi_w, zi_w ** (3.62 + 1) / ai_w) / np.matmul(wi_w, (zi_w / ai_w)))
    z_hat_w = (np.matmul(wi_w, zi_w ** (1.86 + 1) / ai_w) / np.matmul(wi_w, (zi_w / ai_w)))
    ng_w = np.matmul(wi_w, (zi_w / ai_w))

    return z_tilde, z_tilde_w, z_hat, z_hat_w, ng, ng_w


def k_value_fit(datasheet, phantom, inserts):
    """
    Performs the K value fit, following Schneider et al. 1996 (DOI: 10.1088/0031-9155/41/1/009)
    Input:  datasheet - Dictionary containing data from excel sheets
            phantom - Selection from which phantom type, the CT numbers are to be used
    Output: k_values - fitted k values
    """

    # Load relevant data from datasheet
    density_mat = np.array(datasheet['PhantomInserts']['Density (g/cm3)'])
    zi = np.array(datasheet['ElementParameters']['Zi'])
    ai = np.array(datasheet['ElementParameters']['Ai'])
    ctn = np.array(datasheet['CTnumbers'][phantom])
    wi_mat = np.array(pd.DataFrame(datasheet['PhantomInserts'], columns=datasheet['elements']))
    rho_w = datasheet['Data_water']['rho_w']

    # Calculate values for K fit from fit formulas
    z_tilde, z_tilde_w, z_hat, z_hat_w, ng, ng_w = (k_value_formulas(datasheet, wi_mat[inserts, :], zi, ai))

    # Initiate K-value guesses for the linear least square approach
    k_0 = [10 ** (-5), 10 ** (-4), 0.5]

    # Set Upper and lower bound on the K-values
    lb_k = np.zeros(3)
    ub_k = 10 * np.ones(3)

    k_values = least_squares(k_fit_function, k_0, bounds=[lb_k, ub_k],
                             args=[density_mat[inserts], ng, z_tilde, z_hat, rho_w, ng_w, z_tilde_w, z_hat_w,
                                   ctn[inserts]],
                             ftol=1e-8, xtol=1e-8, gtol=1e-8)
    return k_values.x


def k_fit_function(k, density_mat, ng, z_tilde, z_hat, rho_w, ng_w, z_tilde_w, z_hat_w, ctn):
    """
    Function for the k fit, to be used in k_value_fit
    Input:  k - value to be fitted
            Rest: material parameters from k_value_formulas
    Output: F - fit function
    """

    mu = density_mat * ng * (k[0] * z_tilde + k[1] * z_hat + k[2])
    mu_w = rho_w * ng_w * (k[0] * z_tilde_w + k[1] * z_hat_w + k[2])

    return ctn - 1000 * (mu / mu_w - 1)


def ctn_calculation(datasheet, dataset, inserts, k_set):
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
    wi_mat = np.array(pd.DataFrame(datasheet[dataset], columns=datasheet['elements']))
    rho_w = datasheet['Data_water']['rho_w']

    # Calculate values for CT number fit from fit formulas
    z_tilde, z_tilde_w, z_hat, z_hat_w, ng, ng_w = (k_value_formulas(datasheet, wi_mat[inserts, :], zi, ai))

    # Calculate mu from CTN-specific k set
    k = k_set
    mu = density_mat[inserts] * ng * (k[0] * z_tilde + k[1] * z_hat + k[2])
    mu_w = rho_w * ng_w * (k[0] * z_tilde_w + k[1] * z_hat_w + k[2])
    ctn_calc = 1000 * (mu / mu_w - 1)

    return ctn_calc