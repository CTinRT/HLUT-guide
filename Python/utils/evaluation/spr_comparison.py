# -*- coding: utf-8 -*-
"""
Comparison of measured and calculated SPR for phantom inserts.

% SPDX-License-Identifier: MIT
"""

import numpy as np
import matplotlib.pyplot as plt


def main(datasheet):
    """
    Evaluation box 4: Consistency check of SPR determined experimentally:
    Compare the measured and theoretical SPR for the phantom inserts.
    Only performed when output_parameter is 'SPR'.
    """

    filename = 'Eval_box_4_spr_estimation'
    spr_digits = 3
    spr_meas = datasheet['PhantomInserts']['SPR Measured']
    spr_calc = datasheet['PhantomInserts']['SPR_calc']

    # Check if measured SPR data exists for the phantom inserts:
    if np.isnan(spr_meas[0]):
        print('No measured SPR for phantom provided. Calculated SPR was used.')
    else:
        # Calculate the difference between the measured and calculated SPR:
        diff = spr_meas - spr_calc
        name = datasheet['PhantomInserts']['Insert name']
        with open('{}/for_report/{}.txt'.format(datasheet['output'], filename), 'w') as f:
            f.write('Insert name    SPR measured    SPR calculated    Difference    Difference (%)\n')
            for line in range(0, len(spr_meas)):
                f.write(f'{name[line]}    ' + f'{np.round(spr_meas[line], spr_digits)}    ' +
                        f'{np.round(spr_calc[line], spr_digits)}    ' + f'{np.round(diff[line], spr_digits)}    ' +
                        f'{np.round(diff[line] * 100, 2)} \n')

        # Plot of SPR difference
        figx, axx = plt.subplots(figsize=(10, 4))

        xpos = np.arange(0, len(diff))
        plt.bar(xpos, diff * 100, 0.8, label='SPR difference', zorder=1000)

        axx.yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3, zorder=0)  # vertical lines (major)
        axx.axhline(0, color='black', zorder=5000)

        axx.set_xticks(xpos, datasheet['PhantomInserts']['Insert name'], rotation=45, horizontalalignment='right')

        axx.set_ylabel('$SPR_{meas} - SPR_{est}$ (%)')
        axx.set_title('Comparison measured vs calculated SPR')
        plt.legend()

        # Save the figure:
        plt.savefig("{}/for_report/svg/{}.svg".format(datasheet['output'], filename))
        plt.savefig('{}/for_report/{}.pdf'.format(datasheet['output'], filename), bbox_inches="tight", dpi=300)
        
        plt.clf()
        plt.cla()
        plt.close()