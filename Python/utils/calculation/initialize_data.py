# -*- coding: utf-8 -*-
"""
Initialize data for the HLUT definition

% SPDX-License-Identifier: MIT
"""

import pandas as pd
import numpy as np
import os
from datetime import datetime


def main(output_folder_name, output_parameter, input_folder_name, file_name, e_prot):
    # Create Results folder:
    if not os.path.exists(f'{output_folder_name}'):
        os.makedirs(f'{output_folder_name}')
    # Make dedicated subfolder for this sepcific run of the code:
    output_folder_name_subfolder = 'Results_' + output_parameter + '_' + datetime.now().strftime("%Y%m%d_%H%M%S")
    # If this subfolder already exists, then add a number:
    output_folder_name_subfolder_i = output_folder_name_subfolder
    diffname = 0
    ii = 0
    while diffname == 0:
        diffname = 1
        if os.path.exists(output_folder_name + '/' + output_folder_name_subfolder_i):
            ii += 1
            output_folder_name_subfolder_i = output_folder_name_subfolder + '_' + str(ii)
            diffname = 0
    output_folder_name_subfolder = output_folder_name_subfolder_i
    os.makedirs(output_folder_name + '/' + output_folder_name_subfolder + '/for_report/svg')
    del output_folder_name_subfolder_i, diffname, ii

    # Load data from excel file
    datasheet = {}
    datasheet['output_parameter'] = output_parameter
    datasheet['output'] = output_folder_name + '/' + output_folder_name_subfolder
    excelfile = input_folder_name + '/' + file_name
    del input_folder_name
    xls = pd.ExcelFile(excelfile)
    for sheet_name in xls.sheet_names:
        datasheet[sheet_name] = xls.parse(sheet_name)

    # Import parameters for water, elemental composition and constant values
    import_initialdata(datasheet)
    datasheet['constants'].update({'E_prot': e_prot})

    # Calculate reference values for phantom inserts and tabulated human tissues:
    (datasheet['TabulatedHumanTissues']['SPR_calc'], datasheet['TabulatedHumanTissues']['rhoe_calc'],
     datasheet['TabulatedHumanTissues']['Zeff_calc'], datasheet['TabulatedHumanTissues']['I_calc']) = (
        parameter_calculation(datasheet, 'TabulatedHumanTissues'))

    (datasheet['PhantomInserts']['SPR_calc'], datasheet['PhantomInserts']['rhoe_calc'],
     datasheet['PhantomInserts']['Zeff_calc'], datasheet['PhantomInserts']['I_calc']) = (
        parameter_calculation(datasheet, 'PhantomInserts'))

    # Add averaged CT numbers to CT number input sheet
    ctn_head = datasheet['CTnumbers']['CT number (Head)']
    ctn_body = datasheet['CTnumbers']['CT number (Body)']
    datasheet['CTnumbers']['CT number (averaged)'] = np.nanmean(
        np.array([ctn_head, ctn_body]), axis=0)

    return datasheet


def import_initialdata(datasheet):
    """
    Initialize phantom-independent parameters and load elements
    Input:  datasheet  - Dictionary containing data from excel sheets
    Output: rho_w, zi_w, ai_w, wi_w, ii_w, e_0, m_e, elements - parameters for the respective elements
    """

    # Input data for water:
    rho_w = 1  # mass density
    zi_w = np.array([1, 8])  # Atomic number of components
    ai_w = np.array([1.008, 15.999])  # Atomic mass of components
    wi_w = np.array([0.1119, 0.8881])  # Weight fraction of components of water
    ii_w = np.array([19.2, 106])  # mean excitation energy of components
    datasheet['Data_water'] = {'rho_w': rho_w, 'zi_w': zi_w, 'ai_w': ai_w,
                               'wi_w': wi_w, 'ii_w': ii_w}

    e_0 = 938  # Rest mass of protons in MeV
    m_e = 511 * 10 ** 3  # Rest mass of electron in eV
    datasheet['constants'] = {'e_0': e_0, 'm_e': m_e}

    elements = ['H', 'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Na', 'Mg', 'Al', 'Si', 'P', 'S', 'Cl', 'K', 'Ca',
                'Ti', 'Fe', 'Zn', 'I', 'Ba']  # Elements to be considered from excel sheet
    datasheet['elements'] = elements

    return datasheet


def parameter_calculation(datasheet, dataset):
    """
    Calculate the SPR, RED and EAN for materials in the excel sheet
    Input:  datasheet  - Dictionary containing data from excel sheets
            dataset - either PhantomInserts or TabulatedHumanTissues
    Output: spr_theor, rho_e_mat, zeff_mat, i_mat array - parameters for the respective materials
    """

    # Load relevant data from datasheet
    density_mat = np.array(datasheet[dataset]['Density (g/cm3)'])  # mass density
    zi = np.array(datasheet['ElementParameters']['Zi'])  # atomic numbers
    ai = np.array(datasheet['ElementParameters']['Ai'])  # atomic mass
    ii = np.array(datasheet['ElementParameters']['Ii'])  # mean excitation energy
    wi_mat = np.array(pd.DataFrame(datasheet[dataset], columns=datasheet['elements']))  # weight fraction
    rho_w = datasheet['Data_water']['rho_w']
    wi_w = datasheet['Data_water']['wi_w']
    zi_w = datasheet['Data_water']['zi_w']
    ai_w = datasheet['Data_water']['ai_w']
    ii_w = datasheet['Data_water']['ii_w']
    e_0 = datasheet['constants']['e_0']
    m_e = datasheet['constants']['m_e']
    e_kin = datasheet['constants']['E_prot']

    # Calculate relative electron density for materials
    rho_e_mat = (density_mat * np.matmul(wi_mat, (zi / ai)) / (rho_w * np.matmul(wi_w, zi_w / ai_w)))

    # Calculate effective atomic number
    beta_zeff = 3.1  # Parameter for the power equation
    zeff_mat = (np.matmul(wi_mat, zi ** (beta_zeff + 1) / ai) / np.matmul(wi_mat, zi / ai)) ** (1 / beta_zeff)

    # Calculate ln(I) for materials and for water
    ln_i_mat = (np.matmul(wi_mat, ((zi / ai) * np.log(ii))) / np.matmul(wi_mat, (zi / ai)))
    ln_i_w = (np.matmul(wi_w, ((zi_w / ai_w) * np.log(ii_w))) / np.matmul(wi_w, (zi_w / ai_w)))

    # Calculate mean excitation energy I following Bragg rule
    i_mat = np.exp(ln_i_mat)

    # Calculate relativistic beta squared
    beta_sq = 1 - (e_kin / e_0 + 1) ** (-2)

    # Calculate SPR values
    spr_num = np.log(2 * m_e) + np.log(beta_sq / (1 - beta_sq)) - beta_sq
    spr_den = np.log(2 * m_e) + np.log(beta_sq / (1 - beta_sq)) - ln_i_w - beta_sq
    spr_theor = rho_e_mat * (spr_num - ln_i_mat) / spr_den

    datasheet['constants'].update({'spr_num': spr_num, 'spr_den': spr_den})

    return spr_theor, rho_e_mat, zeff_mat, i_mat