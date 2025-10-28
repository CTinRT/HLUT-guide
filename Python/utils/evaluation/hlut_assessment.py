# -*- coding: utf-8 -*-
"""
Assessment of HLUTs created from averaged CT numbers against size-specific HLUTs.

% SPDX-License-Identifier: MIT
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import interpolate


def main(datasheet, recon_type):
    '''
    Evaluation box 5: Assessment of the need for body-site specific HLUTs:
    '''

    # Define value used:
    if datasheet['output_parameter'] == 'SPR':
        parameter = 'SPR_calc'
        y_axis = 'Stopping-power ratio'
    elif datasheet['output_parameter'] == 'RED':
        parameter = 'rhoe_calc'
        y_axis = 'Relative Electron Density'
    elif datasheet['output_parameter'] == 'MD':
        parameter = 'Density (g/cm3)'
        y_axis = 'Mass Density (g/cm³)'

    # Define HLUT functions:
    hlut_head = interpolate.interp1d(datasheet['HLUTs']['head']['ctn'],
                                     datasheet['HLUTs']['head'][datasheet['output_parameter']])
    hlut_body = interpolate.interp1d(datasheet['HLUTs']['body']['ctn'],
                                     datasheet['HLUTs']['body'][datasheet['output_parameter']])
    hlut_avgd = interpolate.interp1d(datasheet['HLUTs']['avgdCT']['ctn'],
                                     datasheet['HLUTs']['avgdCT'][datasheet['output_parameter']])

    # Create figure - subfigure 1 is used to visually evaluate the HLUTs:
    fig6, ax6 = plt.subplots(2, figsize=(10, 10))

    # Plot the datapoints for the phantom inserts and tabulated human tissues:
    if not (datasheet['output_parameter'] == 'MD'):
        ax6[0].plot(datasheet['CTnumbers']['CT number (Head)'],
                    datasheet['PhantomInserts'][parameter], 'o', color='blue')
        ax6[0].plot(datasheet['CTnumbers']['CT number (Body)'],
                    datasheet['PhantomInserts'][parameter], 'o', color='green')

    ax6[0].plot(datasheet['TabulatedHumanTissues']['ctn_calc_head'],
                datasheet['TabulatedHumanTissues'][parameter], 'o', color='blue')
    ax6[0].plot(datasheet['TabulatedHumanTissues']['ctn_calc_body'],
                datasheet['TabulatedHumanTissues'][parameter], 'o', color='green')

    ax6[0].plot(datasheet['HLUTs']['head']['ctn'], datasheet['HLUTs']['head'][datasheet['output_parameter']],
                label='HLUT head', color='steelblue')
    ax6[0].plot(datasheet['HLUTs']['body']['ctn'], datasheet['HLUTs']['body'][datasheet['output_parameter']],
                label='HLUT body', color='green')
    ax6[0].plot(datasheet['HLUTs']['avgdCT']['ctn'], datasheet['HLUTs']['avgdCT'][datasheet['output_parameter']],
                label='HLUT average CT numbers', color='black')

    if recon_type == 'regular':
        ax6[0].set_title('Size-specific HLUTs vs HLUT from averaged CT numbers')
        ax6[0].set_xlabel('CT numbers (HU)')
    elif recon_type == 'DD':
        ax6[0].set_title('Size-specific HLUTs vs HLUT from averaged DD CT numbers')
        ax6[0].set_xlabel('DD CT numbers (HU)')
    ax6[0].set_ylabel(y_axis)

    # Find maximum CT number:
    max_h = np.ceil(max(datasheet['CTnumbers']['CT number (Head)']) / 100) * 100
    if max_h - max(datasheet['CTnumbers']['CT number (Head)']) < 40:
        max_h = max_h + 100
    max_b = np.ceil(max(datasheet['CTnumbers']['CT number (Body)']) / 100) * 100
    if max_b - max(datasheet['CTnumbers']['CT number (Body)']) < 40:
        max_b = max_b + 100
    max_h_t = np.ceil(max(datasheet['TabulatedHumanTissues']['ctn_calc_head']) / 100) * 100
    if max_h_t - max(datasheet['TabulatedHumanTissues']['ctn_calc_head']) < 40:
        max_h_t = max_h_t + 100
    max_h_b = np.ceil(max(datasheet['TabulatedHumanTissues']['ctn_calc_body']) / 100) * 100
    if max_h_b - max(datasheet['TabulatedHumanTissues']['ctn_calc_body']) < 40:
        max_h_b = max_h_b + 100
    x_max = max(max_h, max_b, max_h_t, max_h_b)
    ax6[0].set_xlim([-1024, x_max])

    # Compute Output values at the maximum CT number:
    y_max = np.ceil(max(hlut_head(x_max), hlut_body(x_max)) * 10) / 10
    ax6[0].set_ylim([0, y_max])

    # Find the CT number for the second most dense phantom insert, and round it up:
    sort_head = np.sort(datasheet['CTnumbers']['CT number (Head)'])
    sort_body = np.sort(datasheet['CTnumbers']['CT number (Body)'])
    ctn_bone = np.ceil(max(sort_head[-2], sort_body[-2]) / 100) * 100
    if ctn_bone - 50 <= max(sort_head[-2], sort_body[-2]):
        ctn_bone = ctn_bone + 100

    # Compute Output values at ctn_bone:
    output_ctn_bone_head = hlut_head(ctn_bone)
    output_ctn_bone_body = hlut_body(ctn_bone)
    output_ctn_bone_average = hlut_avgd(ctn_bone)
    output_ctn_bone_min = min(hlut_head(ctn_bone - 50), hlut_body(ctn_bone - 50))
    output_ctn_bone_max = max(hlut_head(ctn_bone + 50), hlut_body(ctn_bone + 50))

    ax6[0].yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3)  # vertical lines (major)
    ax6[0].legend()

    # Plot inset for bone region - to show the curve differences:
    axins = ax6[0].inset_axes([0.55, 0.1, 0.4, 0.4])

    axins.plot(datasheet['HLUTs']['head']['ctn'], datasheet['HLUTs']['head'][datasheet['output_parameter']],
               label='HLUT head', color='steelblue')
    axins.plot(datasheet['HLUTs']['body']['ctn'], datasheet['HLUTs']['body'][datasheet['output_parameter']],
               label='HLUT body', color='green')
    axins.plot(datasheet['HLUTs']['avgdCT']['ctn'], datasheet['HLUTs']['avgdCT'][datasheet['output_parameter']],
               label='HLUT average CT numbers', color='black')

    # Deviations at ctn_bone:
    axins.plot([ctn_bone, ctn_bone], [output_ctn_bone_average, output_ctn_bone_head], color='steelblue')
    delta_y_head = output_ctn_bone_head - output_ctn_bone_average
    if delta_y_head < 0 and np.abs(delta_y_head) > output_ctn_bone_head - output_ctn_bone_min:
        axins.text(ctn_bone + 3, output_ctn_bone_head + np.abs(delta_y_head) / 2,
                   r'$\Delta = {:.1f}\%$'.format(delta_y_head * 100), fontsize=12, color='steelblue')
    elif delta_y_head < 0 and np.abs(delta_y_head) < output_ctn_bone_head - output_ctn_bone_min:
        axins.text(ctn_bone + 3, output_ctn_bone_head - (output_ctn_bone_head - output_ctn_bone_min) / 2,
                   r'$\Delta = {:.1f}\%$'.format(delta_y_head * 100), fontsize=12, color='steelblue')
    elif delta_y_head > 0 and delta_y_head > output_ctn_bone_max - output_ctn_bone_head:
        axins.text(ctn_bone + 3, output_ctn_bone_average + delta_y_head / 2,
                   r'$\Delta = +{:.1f}\%$'.format(delta_y_head * 100), fontsize=12, color='steelblue')
    elif delta_y_head > 0 and delta_y_head < output_ctn_bone_max - output_ctn_bone_head:
        axins.text(ctn_bone - 13, output_ctn_bone_head + (output_ctn_bone_max - output_ctn_bone_head) / 2,
                   r'$\Delta = +{:.1f}\%$'.format(delta_y_head * 100), fontsize=12, color='steelblue')

    axins.plot([ctn_bone, ctn_bone], [output_ctn_bone_average, output_ctn_bone_body], color='green')
    delta_y_body = output_ctn_bone_body - output_ctn_bone_average
    if delta_y_body < 0 and np.abs(delta_y_body) > output_ctn_bone_body - output_ctn_bone_min:
        axins.text(ctn_bone + 3, output_ctn_bone_body + np.abs(delta_y_body) / 2,
                   r'$\Delta = {:.1f}\%$'.format(delta_y_body * 100), fontsize=12, color='green')
    elif delta_y_body < 0 and np.abs(delta_y_body) < output_ctn_bone_body - output_ctn_bone_min:
        axins.text(ctn_bone + 3, output_ctn_bone_body - (output_ctn_bone_body - output_ctn_bone_min) / 2,
                   r'$\Delta = {:.1f}\%$'.format(delta_y_body * 100), fontsize=12, color='green')
    elif delta_y_body > 0 and delta_y_body > output_ctn_bone_max - output_ctn_bone_body:
        axins.text(ctn_bone + 3, output_ctn_bone_average + delta_y_body / 2,
                   r'$\Delta = +{:.1f}\%$'.format(delta_y_body * 100), fontsize=12, color='green')
    elif delta_y_body > 0 and delta_y_body < output_ctn_bone_max - output_ctn_bone_body:
        axins.text(ctn_bone - 13, output_ctn_bone_body + (output_ctn_bone_max - output_ctn_bone_body) / 2,
                   r'$\Delta = +{:.1f}\%$'.format(delta_y_body * 100), fontsize=12, color='green')

    axins.set_xlim(ctn_bone - 50, ctn_bone + 50)
    axins.set_ylim(output_ctn_bone_min, output_ctn_bone_max)
    axins.indicate_inset_zoom(axins, edgecolor="black")

    # Create difference plot bottom
    xlist = np.arange(-1024, x_max)
    y_value_head = hlut_head(xlist)
    y_value_body = hlut_body(xlist)
    y_value_average = hlut_avgd(xlist)

    ax6[1].plot(xlist, 100 * (y_value_head - y_value_average), '-', color='steelblue',
                label='HLUT head - HLUT average')
    ax6[1].plot(xlist, 100 * (y_value_body - y_value_average), '-', color='green',
                label='HLUT body - HLUT average')
    ax6[1].plot(xlist, 100 * (y_value_average - y_value_average), '-', color='black', linewidth=0.5)

    ax6[1].set_title('Difference of HLUTs: size-specific - averaged CT numbers')
    ax6[1].set_xlabel('CT numbers (HU)')
    ax6[1].set_ylabel(rf'$\Delta$ {y_axis} in %')

    ax6[1].yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3)  # vertical lines (major)

    ax6[1].set_xlim([-1024, x_max])
    ax6[1].legend()

    plt.savefig("{}/for_report/svg/Eval_box_5_hlut_comp.svg".format(datasheet['output']))
    plt.savefig('{}/for_report/Eval_box_5_hlut_comp.pdf'.format(datasheet['output']), bbox_inches="tight",
                dpi=300)
    
    plt.clf()
    plt.cla()
    plt.close()