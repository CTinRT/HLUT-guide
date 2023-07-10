# -*- coding: utf-8 -*-
"""
HLUT export and plot functions for the HLUT definition, to be used in main.py
Python implementation: Nils Peters
Matlab implementation: Vicki Taasti
Version 1.0, 05/08/2023

% SPDX-License-Identifier: MIT
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import interpolate
from sklearn.metrics import mean_squared_error, mean_absolute_error


def hlut_export(datasheet, hluttype):
    """
    Export of calculated HLUTs in two different formats
    Input:  datasheet - Dictionary containing all calculated and measured data
            hluttype - HLUT to be exported
    Output: .txt and .csv files
    """

    # Export of .txt file
    for i in hluttype:
        filename = 'HLUT_{}'.format(i)
        with open('Results/{}.txt'.format(filename), 'w') as f:
            ctn = datasheet['HLUTs'][i]['ctn']
            spr = datasheet['HLUTs'][i]['spr']
            f.write('CT number    SPR \n')
            for line in range(0, len(ctn)):
                f.write(f'{round(ctn[line])}    ' + f'{np.round(spr[line], decimals = 4 )} \n')
                
    # Export of .csv file
    # CTN in first line set to -1000 instead of -1024 for use in RayStation
    for i in hluttype:
        filename = 'HLUT_{}'.format(i)
        with open('Results/{}.csv'.format(filename), 'w') as f:
            ctn = datasheet['HLUTs'][i]['ctn']
            spr = datasheet['HLUTs'][i]['spr']
            f.write('-1000, ' + f'{np.round(spr[0], decimals = 4 )} \n')
            for line in range(1, len(ctn)):
                f.write(f'{round(ctn[line])}, ' + f'{np.round(spr[line], decimals = 4 )} \n')
                
                
def plot_hlut(datasheet, hluttype):
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
        
        x = datasheet['HLUTs'][i]['ctn']
        y = datasheet['HLUTs'][i]['spr']
        ls = 'dotted'

        # Obtain data points for phantom and tabulated tissues
        ht_y = datasheet['PhantomInserts']['SPR_calc']
        ins_y = datasheet['TabulatedHumanTissues']['SPR_calc']

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
        for j in range(0, len(datasheet['PhantomInserts']['Tissue group'])):
            if datasheet['PhantomInserts']['Tissue group'][j] == 1:
                plt.plot(ht_x[j], ht_y[j], 'o', color=c_lung)
            elif datasheet['PhantomInserts']['Tissue group'][j] == 2:
                plt.plot(ht_x[j], ht_y[j], 'o', color=c_fat)
            elif datasheet['PhantomInserts']['Tissue group'][j] == 3:
                plt.plot(ht_x[j], ht_y[j], 'o', color=c_soft)
            elif datasheet['PhantomInserts']['Tissue group'][j] == 4:
                plt.plot(ht_x[j], ht_y[j], 'o', color=c_bone)

        # Plot tabulated tissue datapoints according to their tissue group
        for j in range(0, len(datasheet['TabulatedHumanTissues']['Tissue group'])):
            if datasheet['TabulatedHumanTissues']['Tissue group'][j] == 1:
                plt.plot(ins_x[j], ins_y[j], 'o', color=c_lung)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 2:
                plt.plot(ins_x[j], ins_y[j], 'o', color=c_fat)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 3:
                plt.plot(ins_x[j], ins_y[j], 'o', color=c_soft)
            elif datasheet['TabulatedHumanTissues']['Tissue group'][j] == 4:
                plt.plot(ins_x[j], ins_y[j], 'o', color=c_bone)

        # plot the HLUT
        plt.plot([-1501, -1500], [0, 0], color=c_lung, label='Lung tissues')  # just for legend

        plt.plot(x[0:2], y[0:2], color=c_con, ls=ls)  # Horizontal part
        plt.plot(x[1:3], y[1:3], color=c_con, ls=ls)  # Con. within lung
        plt.plot(x[2:4], y[2:4], color=c_soft)  # Lung
        plt.plot(x[2:4], y[2:4], color=c_lung, ls=(2, (2, 2)))  # Lung
        plt.plot(x[3:5], y[3:5], color=c_con, ls=ls)  # Con. lung to fat
        plt.plot(x[4:6], y[4:6], color=c_fat, label='Adipose tissues')  # Fat
        plt.plot(x[5:7], y[5:7], color=c_con, ls=ls)  # Con. fat to soft
        plt.plot(x[6:8], y[6:8], color=c_soft, label='Soft tissues')  # Soft
        plt.plot(x[6:8], y[6:8], color=c_lung, ls=(2, (2, 2)))  # Soft
        plt.plot(x[7:9], y[7:9], color=c_con, ls=ls)  # Con. soft to bone
        plt.plot(x[8:10], y[8:10], color=c_bone, label='Bone tissues')  # Bone
        plt.plot(x[9:11], y[9:11], color=c_bone)  # End of bone

        plt.plot([-1501, -1500], [0, 0], color=c_con, ls=ls, label='Connection lines')  # just for legend
        
        ax.set_title('HLUT for {} CT numbers'.format(i))
        ax.set_xlabel('CT number in HU')
        ax.set_ylabel('Stopping-power ratio')
        ax.set_ylim([0, 1.8])
        ax.set_xlim([-1024, np.max(datasheet['CTnumbers']['CT number (Head)']) + 100])
        ax.yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3)  # vertical lines (major)

        plt.legend()

        # Plot insets
        axins = ax.inset_axes([0.55, 0.1, 0.4, 0.4])

        # Plot phantom datapoints according to their tissue group
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

        axins.set_xlim(-200, 200)
        axins.set_ylim(0.8, 1.2)
        ax.indicate_inset_zoom(axins, edgecolor="black")
        plt.savefig("Results/for_report/svg/hlut_{}.svg".format(i))
        plt.savefig('Results/HLUT_{}.pdf'.format(i), bbox_inches="tight", dpi=300)
        
        
def evaluation_steps(datasheet):
    """
    Analysis and plot of the individual evaluation steps described in the manuscript
    Input:  datasheet - Dictionary containing all calculated and measured data
    Output: Analysis and plot of the evaluation steps, as .txt, .pdf and .svg
    """

    # Load HLUT values
    hlut_head_ctn = datasheet['HLUTs']['head']['ctn']
    hlut_head_spr = datasheet['HLUTs']['head']['spr']
    hlut_body_ctn = datasheet['HLUTs']['body']['ctn']
    hlut_body_spr = datasheet['HLUTs']['body']['spr']
    hlut_advgd_ctn = datasheet['HLUTs']['avgdCT']['ctn']
    hlut_avgd_spr = datasheet['HLUTs']['avgdCT']['spr']
    
    # Define HLUT as function
    hlut_head = interpolate.interp1d(hlut_head_ctn, hlut_head_spr)
    hlut_body = interpolate.interp1d(hlut_body_ctn, hlut_body_spr)
    hlut_avgd = interpolate.interp1d(hlut_advgd_ctn, hlut_avgd_spr)
    
    ctn_head = datasheet['CTnumbers']['CT number (Head)']
    ctn_body = datasheet['CTnumbers']['CT number (Body)']
    
    name = datasheet['PhantomInserts']['Insert name']
    diff = ctn_head - ctn_body
    with open('Results/for_report/{}.txt'.format('Eval_box_1_beamhardening'), 'w') as f:
        f.write('Insert name    CT number head    CT number body    Difference\n')
        for line in range(0, len(ctn_head)):
            f.write(f'{name[line]}    ' + f'{round(ctn_head[line])}    ' +
                    f'{round(ctn_body[line])}    ' + f'{round(diff[line])} \n')
    
    # Evaluation box 2: Tissue equivalency
    rhoe_tissues = datasheet['TabulatedHumanTissues']['rhoe_calc']
    zeff_tissues = datasheet['TabulatedHumanTissues']['Zeff_calc']
    i_tissues = datasheet['TabulatedHumanTissues']['I_calc']

    rhoe_phantom = datasheet['PhantomInserts']['rhoe_calc']
    zeff_phantom = datasheet['PhantomInserts']['Zeff_calc']
    i_phantom = datasheet['PhantomInserts']['I_calc']
    
    fig, axs = plt.subplots(3, figsize=(10, 20))
    alphavalue = 0.2
    
    # Plot of Zeff vs rhoe
    axs[0].plot(rhoe_tissues, zeff_tissues, 'o', color='steelblue', label='Tabulated human tissues')
    axs[0].plot(rhoe_phantom, zeff_phantom, 'o', color='darkred', label='Phantom inserts')
    axs[0].set_title('X-ray attenuation')    
    axs[0].legend()
    axs[0].set_xlabel('Relative electron density')
    axs[0].set_ylabel('Effective atomic number')
    axs[0].grid(alpha=alphavalue)
    
    # Plot of I-value vs Zeff 
    axs[1].plot(zeff_tissues, i_tissues, 'o', color='steelblue', label='Tabulated human tissues')
    axs[1].plot(zeff_phantom, i_phantom, 'o', color='darkred', label='Phantom inserts')
    axs[1].set_title('X-ray attenuation vs proton stopping power')    
    axs[1].legend()
    axs[1].set_xlabel('Effective atomic number')
    axs[1].set_ylabel('Mean excitation energy (eV)')    
    axs[1].grid(alpha=alphavalue)

    # Plot of I-value vs rhoe
    axs[2].plot(rhoe_tissues, i_tissues, 'o', color='steelblue', label='Tabulated human tissues')
    axs[2].plot(rhoe_phantom, i_phantom, 'o', color='darkred', label='Phantom inserts')
    axs[2].set_title('Proton stopping power')    
    axs[2].legend()
    axs[2].set_xlabel('Relative electron density')
    axs[2].set_ylabel('Mean excitation energy (eV)')    
    axs[2].grid(alpha=alphavalue)
    
    plt.savefig("Results/for_report/svg/Eval_box_2_tissue_equivalence.svg", bbox_inches="tight")
    plt.savefig('Results/for_report/Eval_box_2_tissue_equivalence.pdf', bbox_inches="tight", dpi=300)

    # Evaluation box 3: CT number estimation
    for i in ['head', 'body']:
        filename = 'Eval_box_3_ctnumber_estimation_{}'.format(i)
        
        if i == 'head':
            ctn_meas = datasheet['CTnumbers']['CT number (Head)']
            ctn_calc = datasheet['PhantomInserts']['ctn_calc_head']
        elif i == 'body':
            ctn_meas = datasheet['CTnumbers']['CT number (Body)']
            ctn_calc = datasheet['PhantomInserts']['ctn_calc_body']        
        
        name = datasheet['PhantomInserts']['Insert name']
        diff = ctn_meas - ctn_calc
        with open('Results/for_report/{}.txt'.format(filename), 'w') as f:
            f.write('Insert name    CT number measured    CT number calculated    Difference\n')
            for line in range(0, len(ctn_meas)):
                f.write(f'{name[line]}    ' + f'{round(ctn_meas[line])}    ' +
                        f'{round(ctn_calc[line])}    ' + f'{round(diff[line])} \n')

    # Plot of CT number difference
    fig, ax = plt.subplots(figsize=(10, 4))
        
    diff_head = (datasheet['CTnumbers']['CT number (Head)'] - 
                 datasheet['PhantomInserts']['ctn_calc_head'])
    diff_body = (datasheet['CTnumbers']['CT number (Body)'] - 
                 datasheet['PhantomInserts']['ctn_calc_body'])
    
    xpos = np.arange(0, len(diff_head))
    plt.bar(xpos-0.2, diff_head, 0.4, label='Head phantom', zorder=1000)
    plt.bar(xpos+0.2, diff_body, 0.4, label='Body phantom', zorder=1000)

    ax.yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3, zorder=0)  # vertical lines (major)
    ax.axhline(0, color='black', zorder=5000)
    
    ax.set_xticks(xpos, datasheet['PhantomInserts']['Insert name'], rotation=45, horizontalalignment='right')

    ax.set_ylabel('$CTN_{meas} - CTN_{est}$ (HU)')    
    ax.set_title('Check of estimated CT numbers')    
    plt.legend()

    plt.savefig("Results/for_report/svg/Eval_box_3_ctnumber_estimation.svg", bbox_inches="tight")
    plt.savefig('Results/for_report/Eval_box_3_ctnumber_estimation.pdf', bbox_inches="tight", dpi=300)

    # Evaluation box 4: SPR calculation
    filename = 'Eval_box_4_spr_estimation'
    spr_digits = 3
    spr_meas = datasheet['PhantomInserts']['SPR Measured']
    spr_calc = datasheet['PhantomInserts']['SPR_calc']

    # Check if measured SPR data exists for phantom
    if np.isnan(datasheet['PhantomInserts']['SPR Measured'][0]):
        print('No measured SPR for phantom provided. Calculated SPR was used.')
    else:
        diff = spr_meas - spr_calc
        with open('Results/for_report/{}.txt'.format(filename), 'w') as f:
            f.write('Insert name    SPR measured    SPR calculated    Difference\n')
            for line in range(0, len(ctn_meas)):
                f.write(f'{name[line]}    ' + f'{np.round(spr_meas[line], spr_digits)}    ' +
                        f'{np.round(spr_calc[line], spr_digits)}    ' + f'{np.round(diff[line], spr_digits)} \n')

        # Plot of SPR difference
        figx, axx = plt.subplots(figsize=(10, 4))
            
        diff = spr_meas - spr_calc
        xpos = np.arange(0, len(diff))
        plt.bar(xpos, diff, 0.8, label='SPR difference', zorder=1000)
    
        axx.yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3, zorder=0)  # vertical lines (major)
        axx.axhline(0, color='black', zorder=5000)
        
        axx.set_xticks(xpos, datasheet['PhantomInserts']['Insert name'], rotation=45, horizontalalignment='right')
    
        axx.set_ylabel('$SPR_{meas} - SPR_{est}$ (HU)')    
        axx.set_title('Comparison measured vs calculated SPR')    
        plt.legend()
        
        plt.savefig("Results/for_report/svg/{}.svg".format(filename))
        plt.savefig('Results/for_report/{}.pdf'.format(filename), bbox_inches="tight", dpi=300)

    # Evaluation box 5: Need for additional HLUT
    fig6, ax6 = plt.subplots(2, figsize=(10, 10))
    
    if str(datasheet['PhantomInserts']['SPR Measured'][0]) == 'nan':
        ax6[0].plot(datasheet['CTnumbers']['CT number (Body)'], 
                    datasheet['PhantomInserts']['SPR_calc'], 'o', color='blue')
        ax6[0].plot(datasheet['CTnumbers']['CT number (Head)'], 
                    datasheet['PhantomInserts']['SPR_calc'], 'o', color='green')

        ax6[0].plot(datasheet['TabulatedHumanTissues']['ctn_calc_head'], 
                    datasheet['TabulatedHumanTissues']['SPR_calc'], 'o', color='blue')
        ax6[0].plot(datasheet['TabulatedHumanTissues']['ctn_calc_body'], 
                    datasheet['TabulatedHumanTissues']['SPR_calc'], 'o', color='green')

    ax6[0].plot(datasheet['HLUTs']['head']['ctn'], datasheet['HLUTs']['head']['spr'],
                label='HLUT head', color='steelblue')
    ax6[0].plot(datasheet['HLUTs']['body']['ctn'], datasheet['HLUTs']['body']['spr'], 
                label='HLUT body', color='green')
    ax6[0].plot(datasheet['HLUTs']['avgdCT']['ctn'], datasheet['HLUTs']['avgdCT']['spr'], 
                label='HLUT average CT numbers', color='black')

    ax6[0].set_title('Size-specific HLUTs vs HLUT from averaged CTN')
    ax6[0].set_xlabel('CT number in HU')
    ax6[0].set_ylabel('Stopping-power ratio')
    ax6[0].set_ylim([0, 1.8])
    ax6[0].set_xlim([-1024, np.max(datasheet['CTnumbers']['CT number (Head)']) + 100])
    ax6[0].yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3)  # vertical lines (major)
    ax6[0].legend()

    # Create difference plot bottom
    xlist = np.arange(-1024, 2000)
    yval_head = hlut_head(xlist)
    yval_body = hlut_body(xlist)
    yval_avgd = hlut_avgd(xlist)
    
    ax6[1].plot(xlist, 100*(yval_head - yval_avgd), '-', color='steelblue', label='HLUT head - HLUT average')
    ax6[1].plot(xlist, 100*(yval_body - yval_avgd), '-', color='green', label='HLUT body - HLUT average')
    ax6[1].plot(xlist, 100*(yval_avgd - yval_avgd), '-', color='black')

    ax6[1].set_title('Difference of HLUTs: size-specific - averaged CT numbers')
    ax6[1].set_xlabel('CT number in HU')
    ax6[1].set_ylabel(r'$\Delta$ SPR in %')    
    ax6[1].yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3)  # vertical lines (major)

    ax6[1].set_xlim([-1024, np.max(datasheet['CTnumbers']['CT number (Head)']) + 100])
    ax6[1].legend()

    plt.savefig("Results/for_report/svg/Eval_box_5_hlut_comp.svg")
    plt.savefig('Results/for_report/Eval_box_5_hlut_comp.pdf', bbox_inches="tight", dpi=300)

    # Evaluation of position dependency of CT numbers
    datasheet['CTnumbers']['CT number (eval - body)'] = (
            datasheet['CTnumbers']['CT number (Body)'] - datasheet['CTnumbers']['CT number (Evaluation - Body)'])

    with open('Results/for_report/Eval_ctn_positiondependency.txt', 'w') as f:
        f.write('Insert name    CTN middle (HU)    CTN outer (HU)    Difference (HU) \n')
        for i in range(0, len(datasheet['CTnumbers']['CT number (Body)'])):
            if str(datasheet['CTnumbers']['CT number (Evaluation - Body)'][i]) != 'nan':
                f.write('{}    {}    {}    {}\n'.format(
                    datasheet['CTnumbers']['Insert name'][i],
                    round(datasheet['CTnumbers']['CT number (Body)'][i]),
                    round(datasheet['CTnumbers']['CT number (Evaluation - Body)'][i]),
                    round(datasheet['CTnumbers']['CT number (eval - body)'][i])))

    # Evaluation of HLUT accuracy
    # Initiate SPR lists
    spr_meas_lung, spr_meas_fat, spr_meas_soft, spr_meas_bone = [], [], [], []
    spr_cal_head_lung, spr_cal_head_fat, spr_cal_head_soft, spr_cal_head_bone = [], [], [], []
    spr_cal_body_lung, spr_cal_body_fat, spr_cal_body_soft, spr_cal_body_bone = [], [], [], []
    spr_cal_body_avgd_lung, spr_cal_body_avgd_fat, spr_cal_body_avgd_soft, spr_cal_body_avgd_bone = [], [], [], []
    spr_cal_head_avgd_lung, spr_cal_head_avgd_fat, spr_cal_head_avgd_soft, spr_cal_head_avgd_bone = [], [], [], []

    # Check if measured SPR data exists for phantom
    if np.isnan(datasheet['PhantomInserts']['SPR Measured'][0]):
        sprtype = 'SPR_calc'
    else:
        sprtype = 'SPR Measured'
    
    # Calculate SPR based on CTN and HLUT in phantom
    datasheet['PhantomInserts']['SPR_head_fromHLUT'] = (hlut_head(datasheet['CTnumbers']['CT number (Head)']))
    datasheet['PhantomInserts']['SPR_body_fromHLUT'] = (hlut_body(datasheet['CTnumbers']['CT number (Body)']))
    datasheet['PhantomInserts']['SPR_head_avgd_fromHLUT'] = (hlut_avgd(datasheet['CTnumbers']['CT number (Head)']))
    datasheet['PhantomInserts']['SPR_body_avgd_fromHLUT'] = (hlut_avgd(datasheet['CTnumbers']['CT number (Body)']))
    
    # Calculate SPR based on CTN and HLUT in tabulates tissues
    datasheet['TabulatedHumanTissues']['SPR_head_fromHLUT'] = (
        hlut_head(datasheet['TabulatedHumanTissues']['ctn_calc_head']))
    datasheet['TabulatedHumanTissues']['SPR_body_fromHLUT'] = (
        hlut_body(datasheet['TabulatedHumanTissues']['ctn_calc_body']))
    datasheet['TabulatedHumanTissues']['SPR_head_avgd_fromHLUT'] = (
        hlut_avgd(datasheet['TabulatedHumanTissues']['ctn_calc_head']))
    datasheet['TabulatedHumanTissues']['SPR_body_avgd_fromHLUT'] = (
        hlut_avgd(datasheet['TabulatedHumanTissues']['ctn_calc_body']))

    # Add SPR estimation based on HLUT
    indexlist = datasheet['PhantomInserts']['Tissue group']  # tissue grouping
    for i in range(len(indexlist)):
        if indexlist[i] == 1:
            spr_meas_lung.append(datasheet['PhantomInserts'][sprtype][i])
            spr_cal_head_lung.append(datasheet['PhantomInserts']['SPR_head_fromHLUT'][i])
            spr_cal_body_lung.append(datasheet['PhantomInserts']['SPR_body_fromHLUT'][i])
            spr_cal_head_avgd_lung.append(datasheet['PhantomInserts']['SPR_head_avgd_fromHLUT'][i])
            spr_cal_body_avgd_lung.append(datasheet['PhantomInserts']['SPR_body_avgd_fromHLUT'][i])
        if indexlist[i] == 2:
            spr_meas_fat.append(datasheet['PhantomInserts'][sprtype][i])
            spr_cal_head_fat.append(datasheet['PhantomInserts']['SPR_head_fromHLUT'][i])
            spr_cal_body_fat.append(datasheet['PhantomInserts']['SPR_body_fromHLUT'][i])
            spr_cal_head_avgd_fat.append(datasheet['PhantomInserts']['SPR_head_avgd_fromHLUT'][i])
            spr_cal_body_avgd_fat.append(datasheet['PhantomInserts']['SPR_body_avgd_fromHLUT'][i])
        if indexlist[i] == 3:
            spr_meas_soft.append(datasheet['PhantomInserts'][sprtype][i])
            spr_cal_head_soft.append(datasheet['PhantomInserts']['SPR_head_fromHLUT'][i])
            spr_cal_body_soft.append(datasheet['PhantomInserts']['SPR_body_fromHLUT'][i])
            spr_cal_head_avgd_soft.append(datasheet['PhantomInserts']['SPR_head_avgd_fromHLUT'][i])
            spr_cal_body_avgd_soft.append(datasheet['PhantomInserts']['SPR_body_avgd_fromHLUT'][i])
        if indexlist[i] == 4:
            spr_meas_bone.append(datasheet['PhantomInserts'][sprtype][i])
            spr_cal_head_bone.append(datasheet['PhantomInserts']['SPR_head_fromHLUT'][i])
            spr_cal_body_bone.append(datasheet['PhantomInserts']['SPR_body_fromHLUT'][i])
            spr_cal_head_avgd_bone.append(datasheet['PhantomInserts']['SPR_head_avgd_fromHLUT'][i])
            spr_cal_body_avgd_bone.append(datasheet['PhantomInserts']['SPR_body_avgd_fromHLUT'][i])

    # Add calculated CT numbers from tabulated human tissues
    indexlist = datasheet['TabulatedHumanTissues']['Tissue group']  # tissue grouping
    for i in range(len(indexlist)):
        if indexlist[i] == 1:
            spr_meas_lung.append(datasheet['TabulatedHumanTissues']['SPR_calc'][i])
            spr_cal_head_lung.append(datasheet['TabulatedHumanTissues']['SPR_head_fromHLUT'][i])
            spr_cal_body_lung.append(datasheet['TabulatedHumanTissues']['SPR_body_fromHLUT'][i])
            spr_cal_head_avgd_lung.append(datasheet['TabulatedHumanTissues']['SPR_head_avgd_fromHLUT'][i])
            spr_cal_body_avgd_lung.append(datasheet['TabulatedHumanTissues']['SPR_body_avgd_fromHLUT'][i])
        if indexlist[i] == 2:
            spr_meas_fat.append(datasheet['TabulatedHumanTissues']['SPR_calc'][i])
            spr_cal_head_fat.append(datasheet['TabulatedHumanTissues']['SPR_head_fromHLUT'][i])
            spr_cal_body_fat.append(datasheet['TabulatedHumanTissues']['SPR_body_fromHLUT'][i])
            spr_cal_head_avgd_fat.append(datasheet['TabulatedHumanTissues']['SPR_head_avgd_fromHLUT'][i])
            spr_cal_body_avgd_fat.append(datasheet['TabulatedHumanTissues']['SPR_body_avgd_fromHLUT'][i])
        if indexlist[i] == 3:
            spr_meas_soft.append(datasheet['TabulatedHumanTissues']['SPR_calc'][i])
            spr_cal_head_soft.append(datasheet['TabulatedHumanTissues']['SPR_head_fromHLUT'][i])
            spr_cal_body_soft.append(datasheet['TabulatedHumanTissues']['SPR_body_fromHLUT'][i])
            spr_cal_head_avgd_soft.append(datasheet['TabulatedHumanTissues']['SPR_head_avgd_fromHLUT'][i])
            spr_cal_body_avgd_soft.append(datasheet['TabulatedHumanTissues']['SPR_body_avgd_fromHLUT'][i])
        if indexlist[i] == 4:
            spr_meas_bone.append(datasheet['TabulatedHumanTissues']['SPR_calc'][i])
            spr_cal_head_bone.append(datasheet['TabulatedHumanTissues']['SPR_head_fromHLUT'][i])
            spr_cal_body_bone.append(datasheet['TabulatedHumanTissues']['SPR_body_fromHLUT'][i])
            spr_cal_head_avgd_bone.append(datasheet['TabulatedHumanTissues']['SPR_head_avgd_fromHLUT'][i])
            spr_cal_body_avgd_bone.append(datasheet['TabulatedHumanTissues']['SPR_body_avgd_fromHLUT'][i])
    
    spr_cal_head_all = np.concatenate((np.array(datasheet['PhantomInserts']['SPR_head_fromHLUT']),
                                       np.array(datasheet['TabulatedHumanTissues']['SPR_head_fromHLUT'])))

    spr_cal_body_all = np.concatenate((np.array(datasheet['PhantomInserts']['SPR_body_fromHLUT']),
                                       np.array(datasheet['TabulatedHumanTissues']['SPR_body_fromHLUT'])))

    spr_meas_all = np.concatenate((np.array(datasheet['PhantomInserts'][sprtype]),
                                   np.array(datasheet['TabulatedHumanTissues']['SPR_calc'])))

    # Calculate ME, MAE, RMSE for difference between HLUT and datapoints
    roundto = 2
    
    me_head_lung = round(100*np.mean(np.subtract(np.array(spr_cal_head_lung), np.array(spr_meas_lung))), roundto)
    me_head_fat = round(100*np.mean(np.subtract(np.array(spr_cal_head_fat), np.array(spr_meas_fat))), roundto)
    me_head_soft = round(100*np.mean(np.subtract(np.array(spr_cal_head_soft), np.array(spr_meas_soft))), roundto)
    me_head_bone = round(100*np.mean(np.subtract(np.array(spr_cal_head_bone), np.array(spr_meas_bone))), roundto)
    me_head_all = round(100*np.mean(np.subtract(np.array(spr_cal_head_all), np.array(spr_meas_all))), roundto)
    
    me_body_lung = round(100*np.mean(np.subtract(np.array(spr_cal_body_lung), np.array(spr_meas_lung))), roundto)
    me_body_fat = round(100*np.mean(np.subtract(np.array(spr_cal_body_fat), np.array(spr_meas_fat))), roundto)
    me_body_soft = round(100*np.mean(np.subtract(np.array(spr_cal_body_soft), np.array(spr_meas_soft))), roundto)
    me_body_bone = round(100*np.mean(np.subtract(np.array(spr_cal_body_bone), np.array(spr_meas_bone))), roundto)
    me_body_all = round(100*np.mean(np.subtract(np.array(spr_cal_body_all), np.array(spr_meas_all))), roundto)
    
    mae_head_lung = round(100*mean_absolute_error(spr_cal_head_lung, spr_meas_lung), roundto)
    mae_head_fat = round(100*mean_absolute_error(spr_cal_head_fat, spr_meas_fat), roundto)
    mae_head_soft = round(100*mean_absolute_error(spr_cal_head_soft, spr_meas_soft), roundto)
    mae_head_bone = round(100*mean_absolute_error(spr_cal_head_bone, spr_meas_bone), roundto)
    mae_head_all = round(100*mean_absolute_error(spr_cal_head_all, spr_meas_all), roundto)
    
    mae_body_lung = round(100*mean_absolute_error(spr_cal_body_lung, spr_meas_lung), roundto)
    mae_body_fat = round(100*mean_absolute_error(spr_cal_body_fat, spr_meas_fat), roundto)
    mae_body_soft = round(100*mean_absolute_error(spr_cal_body_soft, spr_meas_soft), roundto)
    mae_body_bone = round(100*mean_absolute_error(spr_cal_body_bone, spr_meas_bone), roundto)
    mae_body_all = round(100*mean_absolute_error(spr_cal_body_all, spr_meas_all), roundto)

    rmse_head_lung = round(100*np.sqrt(mean_squared_error(spr_cal_head_lung, spr_meas_lung)), roundto)
    rmse_head_fat = round(100*np.sqrt(mean_squared_error(spr_cal_head_fat, spr_meas_fat)), roundto)
    rmse_head_soft = round(100*np.sqrt(mean_squared_error(spr_cal_head_soft, spr_meas_soft)), roundto)
    rmse_head_bone = round(100*np.sqrt(mean_squared_error(spr_cal_head_bone, spr_meas_bone)), roundto)
    rmse_head_all = round(100*np.sqrt(mean_squared_error(spr_cal_head_all, spr_meas_all)), roundto)

    rmse_body_lung = round(100*np.sqrt(mean_squared_error(spr_cal_body_lung, spr_meas_lung)), roundto)
    rmse_body_fat = round(100*np.sqrt(mean_squared_error(spr_cal_body_fat, spr_meas_fat)), roundto)
    rmse_body_soft = round(100*np.sqrt(mean_squared_error(spr_cal_body_soft, spr_meas_soft)), roundto)
    rmse_body_bone = round(100*np.sqrt(mean_squared_error(spr_cal_body_bone, spr_meas_bone)), roundto)
    rmse_body_all = round(100*np.sqrt(mean_squared_error(spr_cal_body_all, spr_meas_all)), roundto)
    
    with open('Results/for_report/Eval_box_5_accuracy_head.txt', 'w') as f:
        f.write('Metric    All tissues    Lung    Adipose    Soft tissue    Bone\n')
        f.write('Mean error (%)    {}    {}    {}    {}    {}\n'.format(
            me_head_all, me_head_lung, me_head_fat, me_head_soft, me_head_bone))
        f.write('Mean absolute error (%)    {}    {}    {}    {}    {}\n'.format(
            mae_head_all, mae_head_lung, mae_head_fat, mae_head_soft, mae_head_bone))
        f.write('RMSE (%)    {}    {}    {}    {}    {}\n'.format(
            rmse_head_all, rmse_head_lung, rmse_head_fat, rmse_head_soft, rmse_head_bone))   

    with open('Results/for_report/Eval_box_5_accuracy_body.txt', 'w') as f:
        f.write('Metric    All tissues    Lung    Adipose    Soft tissue    Bone\n')
        f.write('Mean error (%)    {}    {}    {}    {}    {}\n'.format(
            me_body_all, me_body_lung, me_body_fat, me_body_soft, me_body_bone))
        f.write('Mean absolute error (%)    {}    {}    {}    {}    {}\n'.format(
            mae_body_all, mae_body_lung, mae_body_fat, mae_body_soft, mae_body_bone))
        f.write('RMSE (%)    {}    {}    {}    {}    {}\n'.format(
            rmse_body_all, rmse_body_lung, rmse_body_fat, rmse_body_soft, rmse_body_bone))           
        
    fig, ax_1 = plt.subplots(figsize=(10, 4))
    
    xpos = [0.7, 0.9, 1.1, 1.3]
    colors = ['royalblue', 'powderblue', 'seagreen', 'yellowgreen']
    ax_1.axhline(0, color='black')
    
    if len(spr_meas_lung) < 5:
        # Plot long datapoints individually
        ax_1.plot(xpos[0]*np.ones(len(spr_meas_lung)), 100*np.subtract(
            np.array(spr_cal_head_lung), np.array(spr_meas_lung)), 'o', color=colors[0],
                  label='CTN head, HLUT head')
        ax_1.plot(xpos[1]*np.ones(len(spr_meas_lung)), 100*np.subtract(
            np.array(spr_cal_head_avgd_lung), np.array(spr_meas_lung)), 'o', color=colors[1],
                  label='CTN head, HLUT avgd')
        ax_1.plot(xpos[2]*np.ones(len(spr_meas_lung)), 100*np.subtract(
            np.array(spr_cal_body_lung), np.array(spr_meas_lung)), 'o', color=colors[2],
                  label='CTN body, HLUT body')
        ax_1.plot(xpos[3]*np.ones(len(spr_meas_lung)), 100*np.subtract(
            np.array(spr_cal_body_avgd_lung), np.array(spr_meas_lung)), 'o', color=colors[3],
                  label='CTN body, HLUT avgd')
    else: 
        bp0 = ax_1.boxplot([100*np.subtract(np.array(spr_cal_head_lung), np.array(spr_meas_lung)),
                            100*np.subtract(np.array(spr_cal_head_avgd_lung), np.array(spr_meas_lung)),
                            100*np.subtract(np.array(spr_cal_body_lung), np.array(spr_meas_lung)),
                            100*np.subtract(np.array(spr_cal_body_avgd_lung), np.array(spr_meas_lung))],
                           positions=list(map(lambda x: x + 0, xpos)), patch_artist=True, showmeans=True)  
        for patch, color in zip(bp0['boxes'], colors):
            patch.set_facecolor(color) 
    
    bp1 = ax_1.boxplot([100*np.subtract(np.array(spr_cal_head_fat), np.array(spr_meas_fat)),
                        100*np.subtract(np.array(spr_cal_head_avgd_fat), np.array(spr_meas_fat)),
                        100*np.subtract(np.array(spr_cal_body_fat), np.array(spr_meas_fat)),
                        100*np.subtract(np.array(spr_cal_body_avgd_fat), np.array(spr_meas_fat))],
                       positions=list(map(lambda x: x + 1, xpos)), patch_artist=True, showmeans=True)
    
    bp2 = ax_1.boxplot([100*np.subtract(np.array(spr_cal_head_soft), np.array(spr_meas_soft)),
                        100*np.subtract(np.array(spr_cal_head_avgd_soft), np.array(spr_meas_soft)),
                        100*np.subtract(np.array(spr_cal_body_soft), np.array(spr_meas_soft)),
                        100*np.subtract(np.array(spr_cal_body_avgd_soft), np.array(spr_meas_soft))],
                       positions=list(map(lambda x: x + 2, xpos)), patch_artist=True, showmeans=True)
    
    bp3 = ax_1.boxplot([100*np.subtract(np.array(spr_cal_head_bone), np.array(spr_meas_bone)),
                        100*np.subtract(np.array(spr_cal_head_avgd_bone), np.array(spr_meas_bone)),
                        100*np.subtract(np.array(spr_cal_body_bone), np.array(spr_meas_bone)),
                        100*np.subtract(np.array(spr_cal_body_avgd_bone), np.array(spr_meas_bone))],
                       positions=list(map(lambda x: x + 3, xpos)), patch_artist=True, showmeans=True)

    # Change color of boxes
    for patch, color in zip(bp1['boxes'], colors):
        patch.set_facecolor(color)    
    for patch, color in zip(bp2['boxes'], colors):
        patch.set_facecolor(color)        
    for patch, color in zip(bp3['boxes'], colors):
        patch.set_facecolor(color)        
        
    ax_1.set_title('SPR accuracy with different HLUTs')
    ax_1.set_xlabel('Tissue group')
    ax_1.set_ylabel('$SPR_{HLUT} - SPR_{ref}$ (%)')    
    ax_1.yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3)  # vertical lines (major)

    ax_1.set_xticks((1, 2, 3, 4), ['Lung', 'Adipose', 'Soft tissues', 'Bones'],
                    rotation=0, horizontalalignment='center')
    ax_1.legend()

    plt.savefig("Results/for_report/svg/{}.svg".format('Eval_endtoend_hlut_accuracy'))
    plt.savefig('Results/for_report/{}.pdf'.format('Eval_endtoend_hlut_accuracy'), bbox_inches="tight", dpi=300)
    




    
