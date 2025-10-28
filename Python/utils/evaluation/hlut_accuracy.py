# -*- coding: utf-8 -*-
"""
Evaluation of HLUT accuracy

% SPDX-License-Identifier: MIT
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import interpolate
from sklearn.metrics import mean_squared_error, mean_absolute_error


def main(datasheet):
    """
    Step 6: Evaluation of HLUT specification - End-to-end test.
    Compute the accuracy of the generated HLUTs.
    """
    # Define value used:
    if datasheet['output_parameter'] == 'SPR':
        parameter = 'SPR_calc'
        # Parameter type for phantom inserts:
        if np.isnan(datasheet['PhantomInserts']['SPR Measured'][0]):
            partype = 'SPR_calc'
        else:
            partype = 'SPR Measured'
    elif datasheet['output_parameter'] == 'RED':
        parameter = 'rhoe_calc'
        partype =  'rhoe_calc'
    elif datasheet['output_parameter'] == 'MD':
        parameter = 'Density (g/cm3)'

    # Define HLUT functions:
    hlut_head = interpolate.interp1d(datasheet['HLUTs']['head']['ctn'],
                                     datasheet['HLUTs']['head'][datasheet['output_parameter']])
    hlut_body = interpolate.interp1d(datasheet['HLUTs']['body']['ctn'],
                                     datasheet['HLUTs']['body'][datasheet['output_parameter']])
    hlut_avgd = interpolate.interp1d(datasheet['HLUTs']['avgdCT']['ctn'],
                                     datasheet['HLUTs']['avgdCT'][datasheet['output_parameter']])

    # Calculate Output based on CT number and HLUT for phantom inserts:
    datasheet['PhantomInserts']['head_fromHLUT'] = (hlut_head(datasheet['CTnumbers']['CT number (Head)']))
    datasheet['PhantomInserts']['body_fromHLUT'] = (hlut_body(datasheet['CTnumbers']['CT number (Body)']))
    datasheet['PhantomInserts']['head_avgd_fromHLUT'] = (hlut_avgd(datasheet['CTnumbers']['CT number (Head)']))
    datasheet['PhantomInserts']['body_avgd_fromHLUT'] = (hlut_avgd(datasheet['CTnumbers']['CT number (Body)']))

    # Calculate Output based on CT number and HLUT for tabulates tissues:
    datasheet['TabulatedHumanTissues']['head_fromHLUT'] = (
        hlut_head(datasheet['TabulatedHumanTissues']['ctn_calc_head']))
    datasheet['TabulatedHumanTissues']['body_fromHLUT'] = (
        hlut_body(datasheet['TabulatedHumanTissues']['ctn_calc_body']))
    datasheet['TabulatedHumanTissues']['head_avgd_fromHLUT'] = (
        hlut_avgd(datasheet['TabulatedHumanTissues']['ctn_calc_head']))
    datasheet['TabulatedHumanTissues']['body_avgd_fromHLUT'] = (
        hlut_avgd(datasheet['TabulatedHumanTissues']['ctn_calc_body']))

    ###########################################################################
    # Initialize parameter lists
    par_meas_lung, par_meas_fat, par_meas_soft, par_meas_bone = [], [], [], []
    par_cal_head_lung, par_cal_head_fat, par_cal_head_soft, par_cal_head_bone = [], [], [], []
    par_cal_body_lung, par_cal_body_fat, par_cal_body_soft, par_cal_body_bone = [], [], [], []
    par_cal_body_avgd_lung, par_cal_body_avgd_fat, par_cal_body_avgd_soft, par_cal_body_avgd_bone = [], [], [], []
    par_cal_head_avgd_lung, par_cal_head_avgd_fat, par_cal_head_avgd_soft, par_cal_head_avgd_bone = [], [], [], []

    # Add Output estimation based on HLUT for phantom inserts:
    if not(datasheet['output_parameter'] == 'MD'):
        indexlist = datasheet['PhantomInserts']['Tissue group']  # tissue grouping
        for i in range(len(indexlist)):
            if indexlist[i] == 1:
                par_meas_lung.append(datasheet['PhantomInserts'][partype][i])
                par_cal_head_lung.append(datasheet['PhantomInserts']['head_fromHLUT'][i])
                par_cal_body_lung.append(datasheet['PhantomInserts']['body_fromHLUT'][i])
                par_cal_head_avgd_lung.append(datasheet['PhantomInserts']['head_avgd_fromHLUT'][i])
                par_cal_body_avgd_lung.append(datasheet['PhantomInserts']['body_avgd_fromHLUT'][i])
            elif indexlist[i] == 2:
                par_meas_fat.append(datasheet['PhantomInserts'][partype][i])
                par_cal_head_fat.append(datasheet['PhantomInserts']['head_fromHLUT'][i])
                par_cal_body_fat.append(datasheet['PhantomInserts']['body_fromHLUT'][i])
                par_cal_head_avgd_fat.append(datasheet['PhantomInserts']['head_avgd_fromHLUT'][i])
                par_cal_body_avgd_fat.append(datasheet['PhantomInserts']['body_avgd_fromHLUT'][i])
            elif indexlist[i] == 3:
                par_meas_soft.append(datasheet['PhantomInserts'][partype][i])
                par_cal_head_soft.append(datasheet['PhantomInserts']['head_fromHLUT'][i])
                par_cal_body_soft.append(datasheet['PhantomInserts']['body_fromHLUT'][i])
                par_cal_head_avgd_soft.append(datasheet['PhantomInserts']['head_avgd_fromHLUT'][i])
                par_cal_body_avgd_soft.append(datasheet['PhantomInserts']['body_avgd_fromHLUT'][i])
            elif indexlist[i] == 4:
                par_meas_bone.append(datasheet['PhantomInserts'][partype][i])
                par_cal_head_bone.append(datasheet['PhantomInserts']['head_fromHLUT'][i])
                par_cal_body_bone.append(datasheet['PhantomInserts']['body_fromHLUT'][i])
                par_cal_head_avgd_bone.append(datasheet['PhantomInserts']['head_avgd_fromHLUT'][i])
                par_cal_body_avgd_bone.append(datasheet['PhantomInserts']['body_avgd_fromHLUT'][i])

    # Add calculated CT numbers from tabulated human tissues
    indexlist = datasheet['TabulatedHumanTissues']['Tissue group']  # tissue grouping
    for i in range(len(indexlist)):
        if indexlist[i] == 1:
            par_meas_lung.append(datasheet['TabulatedHumanTissues'][parameter][i])
            par_cal_head_lung.append(datasheet['TabulatedHumanTissues']['head_fromHLUT'][i])
            par_cal_body_lung.append(datasheet['TabulatedHumanTissues']['body_fromHLUT'][i])
            par_cal_head_avgd_lung.append(datasheet['TabulatedHumanTissues']['head_avgd_fromHLUT'][i])
            par_cal_body_avgd_lung.append(datasheet['TabulatedHumanTissues']['body_avgd_fromHLUT'][i])
        elif indexlist[i] == 2:
            par_meas_fat.append(datasheet['TabulatedHumanTissues'][parameter][i])
            par_cal_head_fat.append(datasheet['TabulatedHumanTissues']['head_fromHLUT'][i])
            par_cal_body_fat.append(datasheet['TabulatedHumanTissues']['body_fromHLUT'][i])
            par_cal_head_avgd_fat.append(datasheet['TabulatedHumanTissues']['head_avgd_fromHLUT'][i])
            par_cal_body_avgd_fat.append(datasheet['TabulatedHumanTissues']['body_avgd_fromHLUT'][i])
        elif indexlist[i] == 3:
            par_meas_soft.append(datasheet['TabulatedHumanTissues'][parameter][i])
            par_cal_head_soft.append(datasheet['TabulatedHumanTissues']['head_fromHLUT'][i])
            par_cal_body_soft.append(datasheet['TabulatedHumanTissues']['body_fromHLUT'][i])
            par_cal_head_avgd_soft.append(datasheet['TabulatedHumanTissues']['head_avgd_fromHLUT'][i])
            par_cal_body_avgd_soft.append(datasheet['TabulatedHumanTissues']['body_avgd_fromHLUT'][i])
        elif indexlist[i] == 4:
            par_meas_bone.append(datasheet['TabulatedHumanTissues'][parameter][i])
            par_cal_head_bone.append(datasheet['TabulatedHumanTissues']['head_fromHLUT'][i])
            par_cal_body_bone.append(datasheet['TabulatedHumanTissues']['body_fromHLUT'][i])
            par_cal_head_avgd_bone.append(datasheet['TabulatedHumanTissues']['head_avgd_fromHLUT'][i])
            par_cal_body_avgd_bone.append(datasheet['TabulatedHumanTissues']['body_avgd_fromHLUT'][i])

    if datasheet['output_parameter'] == 'MD':
        par_cal_head_all = np.array(datasheet['TabulatedHumanTissues']['head_fromHLUT'])
        par_cal_body_all = np.array(datasheet['TabulatedHumanTissues']['body_fromHLUT'])
        par_meas_all = np.array(datasheet['TabulatedHumanTissues'][parameter])
    else:
        par_cal_head_all = np.concatenate((np.array(datasheet['PhantomInserts']['head_fromHLUT']),
                                           np.array(datasheet['TabulatedHumanTissues']['head_fromHLUT'])))
        par_cal_body_all = np.concatenate((np.array(datasheet['PhantomInserts']['body_fromHLUT']),
                                           np.array(datasheet['TabulatedHumanTissues']['body_fromHLUT'])))
        par_meas_all = np.concatenate((np.array(datasheet['PhantomInserts'][partype]),
                                       np.array(datasheet['TabulatedHumanTissues'][parameter])))

    # Calculate ME, MAE, RMSE for difference between HLUT and datapoints
    roundto = 2

    me_head_lung = round(100.0 *np.mean(np.subtract(np.array(par_cal_head_lung), np.array(par_meas_lung))), roundto)
    me_head_fat = round(100.0 *np.mean(np.subtract(np.array(par_cal_head_fat), np.array(par_meas_fat))), roundto)
    me_head_soft = round(100.0 *np.mean(np.subtract(np.array(par_cal_head_soft), np.array(par_meas_soft))), roundto)
    me_head_bone = round(100.0 *np.mean(np.subtract(np.array(par_cal_head_bone), np.array(par_meas_bone))), roundto)
    me_head_all = round(100.0 *np.mean(np.subtract(np.array(par_cal_head_all), np.array(par_meas_all))), roundto)

    me_body_lung = round(100.0 *np.mean(np.subtract(np.array(par_cal_body_lung), np.array(par_meas_lung))), roundto)
    me_body_fat = round(100.0 *np.mean(np.subtract(np.array(par_cal_body_fat), np.array(par_meas_fat))), roundto)
    me_body_soft = round(100.0 *np.mean(np.subtract(np.array(par_cal_body_soft), np.array(par_meas_soft))), roundto)
    me_body_bone = round(100.0 *np.mean(np.subtract(np.array(par_cal_body_bone), np.array(par_meas_bone))), roundto)
    me_body_all = round(100.0 *np.mean(np.subtract(np.array(par_cal_body_all), np.array(par_meas_all))), roundto)

    mae_head_lung = round(100.0 *mean_absolute_error(par_cal_head_lung, par_meas_lung), roundto)
    mae_head_fat = round(100.0 *mean_absolute_error(par_cal_head_fat, par_meas_fat), roundto)
    mae_head_soft = round(100.0 *mean_absolute_error(par_cal_head_soft, par_meas_soft), roundto)
    mae_head_bone = round(100.0 *mean_absolute_error(par_cal_head_bone, par_meas_bone), roundto)
    mae_head_all = round(100.0 *mean_absolute_error(par_cal_head_all, par_meas_all), roundto)

    mae_body_lung = round(100.0 *mean_absolute_error(par_cal_body_lung, par_meas_lung), roundto)
    mae_body_fat = round(100.0 *mean_absolute_error(par_cal_body_fat, par_meas_fat), roundto)
    mae_body_soft = round(100.0 *mean_absolute_error(par_cal_body_soft, par_meas_soft), roundto)
    mae_body_bone = round(100.0 *mean_absolute_error(par_cal_body_bone, par_meas_bone), roundto)
    mae_body_all = round(100.0 *mean_absolute_error(par_cal_body_all, par_meas_all), roundto)

    rmse_head_lung = round(100.0 *np.sqrt(mean_squared_error(par_cal_head_lung, par_meas_lung)), roundto)
    rmse_head_fat = round(100.0 *np.sqrt(mean_squared_error(par_cal_head_fat, par_meas_fat)), roundto)
    rmse_head_soft = round(100.0 *np.sqrt(mean_squared_error(par_cal_head_soft, par_meas_soft)), roundto)
    rmse_head_bone = round(100.0 *np.sqrt(mean_squared_error(par_cal_head_bone, par_meas_bone)), roundto)
    rmse_head_all = round(100.0 *np.sqrt(mean_squared_error(par_cal_head_all, par_meas_all)), roundto)

    rmse_body_lung = round(100.0 *np.sqrt(mean_squared_error(par_cal_body_lung, par_meas_lung)), roundto)
    rmse_body_fat = round(100.0 *np.sqrt(mean_squared_error(par_cal_body_fat, par_meas_fat)), roundto)
    rmse_body_soft = round(100.0 *np.sqrt(mean_squared_error(par_cal_body_soft, par_meas_soft)), roundto)
    rmse_body_bone = round(100.0 *np.sqrt(mean_squared_error(par_cal_body_bone, par_meas_bone)), roundto)
    rmse_body_all = round(100.0 *np.sqrt(mean_squared_error(par_cal_body_all, par_meas_all)), roundto)

    with open('{}/for_report/Eval_box_5_accuracy_head.txt'.format(datasheet['output']), 'w') as f:
        f.write('Metric    All tissues    Lung    Adipose    Soft tissue    Bone\n')
        f.write('Mean error (%)    {}    {}    {}    {}    {}\n'.format(
            me_head_all, me_head_lung, me_head_fat, me_head_soft, me_head_bone))
        f.write('Mean absolute error (%)    {}    {}    {}    {}    {}\n'.format(
            mae_head_all, mae_head_lung, mae_head_fat, mae_head_soft, mae_head_bone))
        f.write('RMSE (%)    {}    {}    {}    {}    {}\n'.format(
            rmse_head_all, rmse_head_lung, rmse_head_fat, rmse_head_soft, rmse_head_bone))

    with open('{}/for_report/Eval_box_5_accuracy_body.txt'.format(datasheet['output']), 'w') as f:
        f.write('Metric    All tissues    Lung    Adipose    Soft tissue    Bone\n')
        f.write('Mean error (%)    {}    {}    {}    {}    {}\n'.format(
            me_body_all, me_body_lung, me_body_fat, me_body_soft, me_body_bone))
        f.write('Mean absolute error (%)    {}    {}    {}    {}    {}\n'.format(
            mae_body_all, mae_body_lung, mae_body_fat, mae_body_soft, mae_body_bone))
        f.write('RMSE (%)    {}    {}    {}    {}    {}\n'.format(
            rmse_body_all, rmse_body_lung, rmse_body_fat, rmse_body_soft, rmse_body_bone))

    # Plot figures:
    fig, ax_1 = plt.subplots(figsize=(10, 4))

    xpos = [0.7, 0.9, 1.1, 1.3]
    colors = ['royalblue', 'powderblue', 'seagreen', 'yellowgreen']
    ax_1.axhline(0, color='black', linewidth=0.5)

    # Plot results for lung tisues:
    if len(par_meas_lung) < 5:
        ax_1.plot(xpos[0 ] *np.ones(len(par_meas_lung)), 100.0 *np.subtract(
            np.array(par_cal_head_lung), np.array(par_meas_lung)), 'o', color=colors[0],
                  label='CTN head, HLUT head')
        ax_1.plot(xpos[1 ] *np.ones(len(par_meas_lung)), 100.0 *np.subtract(
            np.array(par_cal_head_avgd_lung), np.array(par_meas_lung)), 'o', color=colors[1],
                  label='CTN head, HLUT avgd')
        ax_1.plot(xpos[2 ] *np.ones(len(par_meas_lung)), 100.0 *np.subtract(
            np.array(par_cal_body_lung), np.array(par_meas_lung)), 'o', color=colors[2],
                  label='CTN body, HLUT body')
        ax_1.plot(xpos[3 ] *np.ones(len(par_meas_lung)), 100.0 *np.subtract(
            np.array(par_cal_body_avgd_lung), np.array(par_meas_lung)), 'o', color=colors[3],
                  label='CTN body, HLUT avgd')
    else:
        bp0 = ax_1.boxplot([100.0 *np.subtract(np.array(par_cal_head_lung), np.array(par_meas_lung)),
                            100.0 *np.subtract(np.array(par_cal_head_avgd_lung), np.array(par_meas_lung)),
                            100.0 *np.subtract(np.array(par_cal_body_lung), np.array(par_meas_lung)),
                            100.0 *np.subtract(np.array(par_cal_body_avgd_lung), np.array(par_meas_lung))],
                           positions=list(map(lambda x: x + 0, xpos)), patch_artist=True, showmeans=True)
        for patch, color in zip(bp0['boxes'], colors):
            patch.set_facecolor(color)
        # Plot fake data to create a legend:
        ax_1.plot([], [], 'o', color=colors[0], label='CTN head, HLUT head')
        ax_1.plot([], [], 'o', color=colors[1], label='CTN head, HLUT avgd')
        ax_1.plot([], [], 'o', color=colors[2], label='CTN body, HLUT body')
        ax_1.plot([], [], 'o', color=colors[3], label='CTN body, HLUT avgd')

    # Plot results for adipose tisues:
    if len(par_meas_fat) < 5:
        ax_1.plot((xpos[0 ] +1 ) *np.ones(len(par_meas_fat)), 100.0 *np.subtract(
            np.array(par_cal_head_fat), np.array(par_meas_fat)), 'o', color=colors[0])
        ax_1.plot((xpos[1 ] +1 ) *np.ones(len(par_meas_fat)), 100.0 *np.subtract(
            np.array(par_cal_head_avgd_fat), np.array(par_meas_fat)), 'o', color=colors[1])
        ax_1.plot((xpos[2 ] +1 ) *np.ones(len(par_meas_fat)), 100.0 *np.subtract(
            np.array(par_cal_body_fat), np.array(par_meas_fat)), 'o', color=colors[2])
        ax_1.plot((xpos[3 ] +1 ) *np.ones(len(par_meas_fat)), 100.0 *np.subtract(
            np.array(par_cal_body_avgd_fat), np.array(par_meas_fat)), 'o', color=colors[3])
    else:
        bp1 = ax_1.boxplot([100.0 *np.subtract(np.array(par_cal_head_fat), np.array(par_meas_fat)),
                            100.0 *np.subtract(np.array(par_cal_head_avgd_fat), np.array(par_meas_fat)),
                            100.0 *np.subtract(np.array(par_cal_body_fat), np.array(par_meas_fat)),
                            100.0 *np.subtract(np.array(par_cal_body_avgd_fat), np.array(par_meas_fat))],
                           positions=list(map(lambda x: x + 1, xpos)), patch_artist=True, showmeans=True)
        for patch, color in zip(bp1['boxes'], colors):
            patch.set_facecolor(color)

    # Plot results for soft tisues:
    if len(par_meas_soft) < 5:
        ax_1.plot((xpos[0 ] +2 ) *np.ones(len(par_meas_soft)), 100.0 *np.subtract(
            np.array(par_cal_head_soft), np.array(par_meas_soft)), 'o', color=colors[0])
        ax_1.plot((xpos[1 ] +2 ) *np.ones(len(par_meas_soft)), 100.0 *np.subtract(
            np.array(par_cal_head_avgd_soft), np.array(par_meas_soft)), 'o', color=colors[1])
        ax_1.plot((xpos[2 ] +2 ) *np.ones(len(par_meas_soft)), 100.0 *np.subtract(
            np.array(par_cal_body_soft), np.array(par_meas_soft)), 'o', color=colors[2])
        ax_1.plot((xpos[3 ] +2 ) *np.ones(len(par_meas_soft)), 100.0 *np.subtract(
            np.array(par_cal_body_avgd_soft), np.array(par_meas_soft)), 'o', color=colors[3])
    else:
        bp2 = ax_1.boxplot([100.0 *np.subtract(np.array(par_cal_head_soft), np.array(par_meas_soft)),
                            100.0 *np.subtract(np.array(par_cal_head_avgd_soft), np.array(par_meas_soft)),
                            100.0 *np.subtract(np.array(par_cal_body_soft), np.array(par_meas_soft)),
                            100.0 *np.subtract(np.array(par_cal_body_avgd_soft), np.array(par_meas_soft))],
                           positions=list(map(lambda x: x + 2, xpos)), patch_artist=True, showmeans=True)
        for patch, color in zip(bp2['boxes'], colors):
            patch.set_facecolor(color)

    # Plot results for bone tisues:
    if len(par_meas_bone) < 5:
        ax_1.plot((xpos[0 ] +3 ) *np.ones(len(par_meas_bone)), 100.0 *np.subtract(
            np.array(par_cal_head_bone), np.array(par_meas_bone)), 'o', color=colors[0])
        ax_1.plot((xpos[1 ] +3 ) *np.ones(len(par_meas_bone)), 100.0 *np.subtract(
            np.array(par_cal_head_avgd_bone), np.array(par_meas_bone)), 'o', color=colors[1])
        ax_1.plot((xpos[2 ] +3 ) *np.ones(len(par_meas_bone)), 100.0 *np.subtract(
            np.array(par_cal_body_bone), np.array(par_meas_bone)), 'o', color=colors[2])
        ax_1.plot((xpos[3 ] +3 ) *np.ones(len(par_meas_bone)), 100.0 *np.subtract(
            np.array(par_cal_body_avgd_bone), np.array(par_meas_bone)), 'o', color=colors[3])
    else:
        bp3 = ax_1.boxplot([100.0 *np.subtract(np.array(par_cal_head_bone), np.array(par_meas_bone)),
                            100.0 *np.subtract(np.array(par_cal_head_avgd_bone), np.array(par_meas_bone)),
                            100.0 *np.subtract(np.array(par_cal_body_bone), np.array(par_meas_bone)),
                            100.0 *np.subtract(np.array(par_cal_body_avgd_bone), np.array(par_meas_bone))],
                           positions=list(map(lambda x: x + 3, xpos)), patch_artist=True, showmeans=True)
        for patch, color in zip(bp3['boxes'], colors):
            patch.set_facecolor(color)

    output_parameter = datasheet['output_parameter'] # For labeling purposes
    ax_1.set_title(f'{output_parameter} accuracy with different HLUTs')
    ax_1.set_xlabel('Tissue group')
    ax_1.set_ylabel(rf'${{{output_parameter}}}_{{HLUT}} - {{{output_parameter}}}_{{ref}}$ (%)')
    ax_1.yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3)  # vertical lines (major)

    ax_1.set_xticks((1, 2, 3, 4), ['Lung', 'Adipose', 'Soft tissues', 'Bones'],
                    rotation=0, horizontalalignment='center')

    ax_1.set_xlim([0.5, 4.5])

    ax_1.legend()

    plt.savefig("{}/for_report/svg/{}.svg".format(datasheet['output'] ,'Eval_endtoend_hlut_accuracy'))
    plt.savefig('{}/for_report/{}.pdf'.format(datasheet['output'] ,'Eval_endtoend_hlut_accuracy'), bbox_inches="tight", dpi=300)
    
    plt.clf()
    plt.cla()
    plt.close()