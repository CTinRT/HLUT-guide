# -*- coding: utf-8 -*-
"""
Fit and plot of HLUTs

% SPDX-License-Identifier: MIT
"""

import numpy as np
import math
import matplotlib.pyplot as plt


def main(datasheet, recon_type):
    # Initiate datasheet for HLUTs
    datasheet['HLUTs'] = {}

    # Initiate loop parameters for HLUT generation
    hluttype = ['head', 'body', 'avgdCT']  # the three parameter sets
    phantomtype = ['CT number (Head)', 'CT number (Body)', 'CT number (averaged)']  # respective phantom CT numbers
    ctnumbertype = ['ctn_calc_head', 'ctn_calc_body', 'ctn_calc_avgCT']  # respective calculated CT numbers

    # Fit CT numbers and generate HLUT
    for i in range(0, len(hluttype)):
        datasheet['HLUTs'][hluttype[i]] = {}
        (datasheet['HLUTs'][hluttype[i]]['ctn'], datasheet['HLUTs'][hluttype[i]][datasheet['output_parameter']]) = (
            hlut_fit(datasheet, phantomtype[i], ctnumbertype[i]))

    # Export HLUTs to txt files, saved in output folder
    hlut_export(datasheet, hluttype, recon_type)

    # Plot results, saved in output folder for SPR HLUT
    plot_hlut(datasheet, hluttype, recon_type)


def hlut_fit(datasheet, phantom_ctn, tabul_ctn):
    """
    Fit CT numbers and determine connection points
    Input:  datasheet  - Dictionary containing data from excel sheets
            phantom_ctn - CT numbers from head/body/avgd
            tabul_ctn - tabulated tissue CT numbers from head/body/avgd
    Output: cp_ctn, cp_spr - connection points (CTN, SPR)
    """

    # Load relevant data from datasheet
    rho_w = datasheet['Data_water']['rho_w']
    wi_w = datasheet['Data_water']['wi_w']
    zi_w = datasheet['Data_water']['zi_w']
    ai_w = datasheet['Data_water']['ai_w']

    # Initiate CT number and parameter (par) lists for each tissue group
    ctn_tiss_fat, ctn_tiss_soft, ctn_tiss_bone = [], [], []
    ctn_lung, ctn_fat, ctn_soft, ctn_bone = [], [], [], []
    par_lung, par_fat, par_soft, par_bone = [], [], [], []

    # Load data based on the output_parameter
    if datasheet['output_parameter'] == 'SPR':
        # Check if measured SPR data exists for phantom
        if np.isnan(datasheet['PhantomInserts']['SPR Measured'][0]):
            par_type_phantom = 'SPR_calc'
        else:
            par_type_phantom = 'SPR Measured'
        # Type for tabulated human tissues
        par_type_tiss = 'SPR_calc'
    elif datasheet['output_parameter'] == 'RED':
        par_type_phantom = 'rhoe_calc'
        par_type_tiss = 'rhoe_calc'
    elif datasheet['output_parameter'] == 'MD':
        par_type_phantom = 'Density (g/cm3)'
        par_type_tiss = 'Density (g/cm3)'

    # Add CT numbers and parameters from phantom
    if not (datasheet['output_parameter'] == 'MD'):
        indexlist = datasheet['PhantomInserts']['Tissue group']  # tissue grouping
        for i in range(len(indexlist)):
            if indexlist[i] == 1:
                ctn_lung.append(datasheet['CTnumbers'][phantom_ctn][i])
                par_lung.append(datasheet['PhantomInserts'][par_type_phantom][i])
            elif indexlist[i] == 2:
                ctn_fat.append(datasheet['CTnumbers'][phantom_ctn][i])
                par_fat.append(datasheet['PhantomInserts'][par_type_phantom][i])
            elif indexlist[i] == 3:
                ctn_soft.append(datasheet['CTnumbers'][phantom_ctn][i])
                par_soft.append(datasheet['PhantomInserts'][par_type_phantom][i])
            elif indexlist[i] == 4:
                ctn_bone.append(datasheet['CTnumbers'][phantom_ctn][i])
                par_bone.append(datasheet['PhantomInserts'][par_type_phantom][i])

    # Add calculated CT numbers from tabulated human tissues
    indexlist = datasheet['TabulatedHumanTissues']['Tissue group']  # tissue grouping
    for i in range(len(indexlist)):
        if indexlist[i] == 1:
            ctn_lung.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            par_lung.append(datasheet['TabulatedHumanTissues'][par_type_tiss][i])
        elif indexlist[i] == 2:
            ctn_tiss_fat.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            ctn_fat.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            par_fat.append(datasheet['TabulatedHumanTissues'][par_type_tiss][i])
        elif indexlist[i] == 3:
            ctn_tiss_soft.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            ctn_soft.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            par_soft.append(datasheet['TabulatedHumanTissues'][par_type_tiss][i])
        elif indexlist[i] == 4:
            ctn_tiss_bone.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            ctn_bone.append(datasheet['TabulatedHumanTissues'][tabul_ctn][i])
            par_bone.append(datasheet['TabulatedHumanTissues'][par_type_tiss][i])

    # Perform fit for each tissue group
    p_lung_soft = np.polyfit(ctn_lung + ctn_soft, par_lung + par_soft, 1)
    p_fat = np.polyfit(ctn_fat, par_fat, 1)
    p_bone = np.polyfit(ctn_bone, par_bone, 1)

    # Define connection points, following Table S1.4
    cp_ctn_lung = [-1024, -999, -950, np.round(min(ctn_tiss_fat) - 60)]  # contains air
    cp_ctn_fat = [np.round(min(ctn_tiss_fat) - 40), -30]
    cp_ctn_soft = [0, np.round(max(ctn_tiss_soft)) + 10]
    if max(ctn_bone) > 2000:
        cp_ctn_bone = [np.round(min(ctn_tiss_bone) + 50),
                       np.ceil((max(ctn_bone) + 100)/100)*100]
    else:
        cp_ctn_bone = [np.round(min(ctn_tiss_bone) + 50), 2000]

        # Initialize array for the matching parameter values
    cp_par_lung, cp_par_fat, cp_par_soft, cp_par_bone = [], [], [], []

    # Calculate parameter value for connection points
    for i in cp_ctn_lung:
        cp_par_lung.append(np.polyval(p_lung_soft, i))
    for i in cp_ctn_fat:
        cp_par_fat.append(np.polyval(p_fat, i))
    for i in cp_ctn_soft:
        cp_par_soft.append(np.polyval(p_lung_soft, i))
    for i in cp_ctn_bone:
        cp_par_bone.append(np.polyval(p_bone, i))

    # Adjust lowest parameter value for lung to value of air, following NIST data
    # from https://physics.nist.gov/cgi-bin/Star/compos.pl?matno=104
    rho_air = 1.20479E-03  # mass density
    zi_air = np.array([6, 7, 8, 18])  # atomic number of components
    ai_air = np.array([12.011, 14.007, 15.999, 39.948])  # atomic mass of components
    wi_air = np.array([0.000124, 0.755267, 0.231781, 0.012827])  # weight fractions
    i_air = 85.7  # mean excitation energy
    rho_e_air = (rho_air * np.matmul(wi_air, (zi_air / ai_air)) / (rho_w * np.matmul(wi_w, zi_w / ai_w)))
    spr_air = rho_e_air * (datasheet['constants']['spr_num'] - np.log(i_air)) / datasheet['constants']['spr_den']

    # lowest value adjusted based on inputed ouput_parameter
    if datasheet['output_parameter'] == 'SPR':
        cp_par_lung[0], cp_par_lung[1] = spr_air, spr_air
    elif datasheet['output_parameter'] == 'MD':
        cp_par_lung[0], cp_par_lung[1] = rho_air, rho_air
    elif datasheet['output_parameter'] == 'RED':
        cp_par_lung[0], cp_par_lung[1] = rho_e_air, rho_e_air

    # Define relevant digits in parameter
    par_digits = 4  # number of digits to which to round the parameter
    offs = 1 * 10 ** (-par_digits)  # parameter offset in case connecting points have the same value

    # Check to see if slope of the segment connections are always positive

    # Check slope between air and lung
    if cp_par_lung[1] >= cp_par_lung[2]:
        cp_ctn_lung[2] = math.ceil((cp_par_lung[1] + offs - p_lung_soft[1]) / p_lung_soft[0])
        cp_par_lung[2] = np.polyval(p_lung_soft, cp_ctn_lung[2])

        note = "{} {} {} HU".format('--- The slope between air and lung tissue is negative or zero.',
                                    'The CT number for the lower end of the lung tissue curve is increased to',
                                    cp_ctn_lung[2])
        print(note)

    # Check slope between lung and adipose
    if np.polyval(p_lung_soft, cp_ctn_lung[-1]) >= np.polyval(p_fat, cp_ctn_fat[0]):
        print('--- The slope between lung and adipose is negative or zero. '
              'This should not happen. Please revise your input data.')

    # Check slope between Adipose and Soft Tissue
    if cp_par_fat[-1] >= cp_par_soft[0]:
        cp_ctn_fat[-1] = math.floor((cp_par_soft[0] - offs - p_fat[1]) / p_fat[0])
        cp_par_fat[-1] = np.polyval(p_fat, cp_ctn_fat[-1])

        note = "{} {} {} HU".format('--- The slope between adipose and soft tissue is negative or zero.',
                                    'The CT number for the upper end of the adipose curve is thus lowered to',
                                    cp_ctn_fat[-1])
        print(note)

    # Slope between Soft Tissue and Bone
    if cp_par_soft[-1] >= cp_par_bone[0]:
        cp_ctn_bone[0] = math.ceil((cp_par_soft[-1] + offs - p_bone[1]) / p_bone[0])
        cp_par_bone[0] = np.polyval(p_bone, cp_ctn_bone[0])

        note = "{} {} {} HU".format('--- The slope between soft tissue and bone is negative.',
                                    'The CT number for the lower end of the bone curve is increased to', cp_ctn_bone[0])
        print(note)

    # Create overall list containing all numbers
    cp_ctn = cp_ctn_lung + cp_ctn_fat + cp_ctn_soft + cp_ctn_bone
    cp_par = cp_par_lung + cp_par_fat + cp_par_soft + cp_par_bone

    return cp_ctn, cp_par


def hlut_export(datasheet, hluttype, recon_type):
    """
    Export of calculated SPR HLUTs in two different formats
    Input:  datasheet - Dictionary containing all calculated and measured data
            hluttype - HLUT to be exported
    Output: .txt and .csv files
    """

    # Export of .txt file
    for i in hluttype:
        filename = '{}_HLUT_{}'.format(datasheet['output_parameter'], i)
        with open('{}/{}.txt'.format(datasheet['output'], filename), 'w') as f:
            ctn = datasheet['HLUTs'][i]['ctn']
            par = datasheet['HLUTs'][i][datasheet['output_parameter']]
            if recon_type == 'regular':
                if datasheet['output_parameter'] == 'MD':
                    f.write('CT number\t{} (g/cm3)\n'.format(datasheet['output_parameter']))
                else:
                    f.write('CT number\t{}\n'.format(datasheet['output_parameter']))
            elif recon_type == 'DD':
                if datasheet['output_parameter'] == 'MD':
                    f.write('DD CT number\t{} (g/cm3)\n'.format(datasheet['output_parameter']))
                else:
                    f.write('DD CT number\t{}\n'.format(datasheet['output_parameter']))
            for line in range(0, len(ctn)):
                f.write(f'{round(ctn[line])}\t' + f'{np.round(par[line], decimals=4)}\n')

    # Export of .csv file
    # CT number in first line set to -1000 instead of -1024 for use in RayStation
    for i in hluttype:
        filename = '{}_HLUT_{}'.format(datasheet['output_parameter'], i)
        with open('{}/{}.csv'.format(datasheet['output'], filename), 'w') as f:
            ctn = datasheet['HLUTs'][i]['ctn']
            par = datasheet['HLUTs'][i][datasheet['output_parameter']]
            f.write('-1000, ' + f'{np.round(par[0], decimals=4)} \n')
            for line in range(1, len(ctn)):
                f.write(f'{round(ctn[line])}, ' + f'{np.round(par[line], decimals=4)} \n')


def plot_hlut(datasheet, hluttype, recon_type):
    """
    Export of plots of the three different HLUTs
    Input:  datasheet - Dictionary containing all calculated and measured data
            hluttype - HLUT to be exported
    Output: Plots of the HLUTs as .pdf and .svg
    """

    # Define colors for plot
    c_con, c_lung, c_fat, c_soft, c_bone = ('black', 'gold', 'darkorange', 'green', 'steelblue')

    # Initialize plot data
    for i in hluttype:
        fig, ax = plt.subplots(figsize=(10, 4))

        ## Uniform for all output parameters
        x = datasheet['HLUTs'][i]['ctn']
        y = datasheet['HLUTs'][i][datasheet['output_parameter']]
        ls = 'dotted'

        # Specify output_parameter-specific datapoints for HLUT fit
        if datasheet['output_parameter'] == 'SPR':
            y_axis = 'Stopping-power ratio'  # Name of y-axis label
            # Obtain data points for phantom and tabulated tissues
            ht_y = datasheet['PhantomInserts']['SPR_calc']
            ins_y = datasheet['TabulatedHumanTissues']['SPR_calc']
        elif datasheet['output_parameter'] == 'RED':
            y_axis = 'Relative Electron Density'  # Name of y-axis label
            # Obtain data points for phantom and tabulated tissues
            ht_y = datasheet['PhantomInserts']['rhoe_calc']
            ins_y = datasheet['TabulatedHumanTissues']['rhoe_calc']
        elif datasheet['output_parameter'] == 'MD':
            y_axis = 'Mass density (g/cm³)'  # Name of y-axis label
            # Obtain data points for phantom and tabulated tissues
            ht_y = datasheet['PhantomInserts']['Density (g/cm3)']
            ins_y = datasheet['TabulatedHumanTissues']['Density (g/cm3)']

        # Specify hluttype-specific parameters
        if i == 'body':
            ht_x = datasheet['CTnumbers']['CT number (Body)']
            ins_x = datasheet['TabulatedHumanTissues']['ctn_calc_body']
        elif i == 'head':
            ht_x = datasheet['CTnumbers']['CT number (Head)']
            ins_x = datasheet['TabulatedHumanTissues']['ctn_calc_head']
        elif i == 'avgdCT':
            ht_x = datasheet['CTnumbers']['CT number (averaged)']
            ins_x = datasheet['TabulatedHumanTissues']['ctn_calc_avgCT']

        # Plot phantom datapoints according to their tissue group
        ms = 5
        if not (datasheet['output_parameter'] == 'MD'):
            for j in range(0, len(datasheet['PhantomInserts']['Tissue group'])):
                if datasheet['PhantomInserts']['Tissue group'][j] == 1:
                    plt.plot(ht_x[j], ht_y[j], 'o', color=c_lung, markersize=ms)
                elif datasheet['PhantomInserts']['Tissue group'][j] == 2:
                    plt.plot(ht_x[j], ht_y[j], 'o', color=c_fat, markersize=ms)
                elif datasheet['PhantomInserts']['Tissue group'][j] == 3:
                    plt.plot(ht_x[j], ht_y[j], 'o', color=c_soft, markersize=ms)
                elif datasheet['PhantomInserts']['Tissue group'][j] == 4:
                    plt.plot(ht_x[j], ht_y[j], 'o', color=c_bone, markersize=ms)

        # Plot tabulated tissue datapoints according to their tissue group
        for j in range(0, len(datasheet['TabulatedHumanTissues']['Tissue group'])):
            if datasheet['TabulatedHumanTissues']['Tissue group'][j] == 1:
                plt.plot(ins_x[j], ins_y[j], 'o', color=c_lung, markersize=ms)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 2:
                plt.plot(ins_x[j], ins_y[j], 'o', color=c_fat, markersize=ms)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 3:
                plt.plot(ins_x[j], ins_y[j], 'o', color=c_soft, markersize=ms)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 4:
                plt.plot(ins_x[j], ins_y[j], 'o', color=c_bone, markersize=ms)

        # Plot the HLUT
        plt.plot([], [], color=c_lung, label='Lung tissues')  # just for legend

        plt.plot(x[0:2], y[0:2], color=c_con, ls=ls)  # Horizontal part
        plt.plot(x[1:3], y[1:3], color=c_con, ls=ls)  # Connection within lung
        plt.plot(x[2:4], y[2:4], color=c_soft)  # Lung
        plt.plot(x[2:4], y[2:4], color=c_lung, ls=(2, (2, 2)))  # Lung
        plt.plot(x[3:5], y[3:5], color=c_con, ls=ls)  # Connection lung to fat
        plt.plot(x[4:6], y[4:6], color=c_fat, label='Adipose tissues')  # Fat
        plt.plot(x[5:7], y[5:7], color=c_con, ls=ls)  # Connection fat to soft
        plt.plot(x[6:8], y[6:8], color=c_soft, label='Soft tissues')  # Soft
        plt.plot(x[6:8], y[6:8], color=c_lung, ls=(2, (2, 2)))  # Soft
        plt.plot(x[7:9], y[7:9], color=c_con, ls=ls)  # Connection soft to bone
        plt.plot(x[8:10], y[8:10], color=c_bone, label='Bone tissues')  # Bone
        plt.plot(x[9:11], y[9:11], color=c_bone)  # End of bone

        plt.plot([], [], color=c_con, ls=ls, label='Connection lines')  # just for legend

        if recon_type == 'regular':
            ax.set_title('{} HLUT for {} CT numbers'.format(datasheet['output_parameter'], i))
            ax.set_xlabel('CT numbers (HU)')
        elif recon_type == 'DD':
            ax.set_title('{} HLUT for {} DirectDensity (DD) CT numbers'.format(datasheet['output_parameter'], i))
            ax.set_xlabel('DD CT numbers (HU)')
        ax.set_ylabel(y_axis)

        # Find maximum CT number:
        max_i = np.ceil(max(ht_x) / 100) * 100
        if max_i - max(ht_x) < 40:
            max_i = max_i + 100
        max_t = np.ceil(max(ins_x) / 100) * 100
        if max_t - max(ins_x) < 40:
            max_t = max_t + 100
        x_max = max(1600, max_i, max_t)
        ax.set_xlim([-1024, x_max])

        # Find maximum y-axis value:
        max_i = np.ceil(max(ht_y) * 10) / 10
        if max_i - max(ht_y) < 0.03:
            max_i = max_i + 0.1
        max_t = np.ceil(max(ins_y) * 10) / 10
        if max_i - max(ins_y) < 0.03:
            max_t = max_t + 0.1
        y_max = max(max_i, max_t)
        ax.set_ylim([0, y_max])
        ax.yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3)  # vertical lines (major)

        plt.legend()

        # Plot inset
        axins = ax.inset_axes([0.55, 0.1, 0.4, 0.4])

        # Plot phantom datapoints according to their tissue group
        if not (datasheet['output_parameter'] == 'MD'):
            for j in range(0, len(datasheet['PhantomInserts']['Tissue group'])):
                if datasheet['PhantomInserts']['Tissue group'][j] == 1:
                    axins.plot(ht_x[j], ht_y[j], 'o', color=c_lung)
                elif datasheet['PhantomInserts']['Tissue group'][j] == 2:
                    axins.plot(ht_x[j], ht_y[j], 'o', color=c_fat)
                elif datasheet['PhantomInserts']['Tissue group'][j] == 3:
                    axins.plot(ht_x[j], ht_y[j], 'o', color=c_soft)
                elif datasheet['PhantomInserts']['Tissue group'][j] == 4:
                    axins.plot(ht_x[j], ht_y[j], 'o', color=c_bone)

        # Plot tabulated tissue datapoints according to their tissue group
        for j in range(0, len(datasheet['TabulatedHumanTissues']['Tissue group'])):
            if datasheet['TabulatedHumanTissues']['Tissue group'][j] == 1:
                axins.plot(ins_x[j], ins_y[j], 'o', color=c_lung)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 2:
                axins.plot(ins_x[j], ins_y[j], 'o', color=c_fat)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 3:
                axins.plot(ins_x[j], ins_y[j], 'o', color=c_soft)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 4:
                axins.plot(ins_x[j], ins_y[j], 'o', color=c_bone)

        axins.plot(x[2:4], y[2:4], color=c_soft)  # Lung
        axins.plot(x[2:4], y[2:4], color=c_lung, ls=(2, (2, 2)))
        axins.plot(x[3:5], y[3:5], color=c_con, ls=ls)
        axins.plot(x[4:6], y[4:6], color=c_fat)
        axins.plot(x[5:7], y[5:7], color=c_con, ls=ls)
        axins.plot(x[6:8], y[6:8], color=c_soft)
        axins.plot(x[6:8], y[6:8], color=c_lung, ls=(2, (2, 2)))
        axins.plot(x[7:9], y[7:9], color=c_con, ls=ls)
        axins.plot(x[8:10], y[8:10], color=c_bone)

        axins.set_xlim(-170, 170)
        axins.set_ylim(0.8, 1.2)
        ax.indicate_inset_zoom(axins, edgecolor="black")

        plt.savefig('{}/for_report/svg/hlut_{}.svg'.format(datasheet['output'], i))
        plt.savefig('{}/for_report/svg/hlut_{}.pdf'.format(datasheet['output'], i), bbox_inches="tight", dpi=300)
        
        plt.clf()
        plt.cla()
        plt.close()