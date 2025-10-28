# -*- coding: utf-8 -*-
"""
Evaluation of CT number estimation

% SPDX-License-Identifier: MIT
"""

import numpy as np
import matplotlib.pyplot as plt


def main(datasheet):
    """
    Evaluation box 3: Check of estimated CT numbers:
    Checking the accuracy of the CT number estimation method, by evaluating it
    based on the phantom inserts.
    """

    # Load the CT numbers:
    for i in ['head', 'body']:
        filename = 'Eval_box_3_ctnumber_estimation_{}'.format(i)

        if i == 'head':
            ctn_meas = datasheet['CTnumbers']['CT number (Head)']
            ctn_calc = datasheet['PhantomInserts']['ctn_calc_head']
        elif i == 'body':
            ctn_meas = datasheet['CTnumbers']['CT number (Body)']
            ctn_calc = datasheet['PhantomInserts']['ctn_calc_body']

        name = datasheet['PhantomInserts']['Insert name']

        # Calculate the difference between the measured and estimated CT numbers:
        diff = ctn_meas - ctn_calc

        # Save the results to a file:
        with open('{}/for_report/{}.txt'.format(datasheet['output'] ,filename), 'w') as f:
            f.write('Insert name    CT number measured    CT number calculated    Difference\n')
            for line in range(0, len(ctn_meas)):
                f.write(f'{name[line]}    ' + f'{round(ctn_meas[line])}    ' +
                        f'{round(ctn_calc[line])}    ' + f'{round(diff[line])} \n')

    # Plot of CT number difference:
    fig, ax = plt.subplots(figsize=(10, 4))

    diff_head = (datasheet['CTnumbers']['CT number (Head)'] -
                 datasheet['PhantomInserts']['ctn_calc_head'])
    diff_body = (datasheet['CTnumbers']['CT number (Body)'] -
                 datasheet['PhantomInserts']['ctn_calc_body'])

    xpos = np.arange(0, len(diff_head))
    plt.bar(xpos - 0.2, diff_head, 0.4, label='Head phantom', zorder=1000)
    plt.bar(xpos + 0.2, diff_body, 0.4, label='Body phantom', zorder=1000)

    ax.yaxis.grid(which='major', color='gray', linestyle='-', alpha=0.3, zorder=0)  # vertical lines (major)
    ax.axhline(0, color='black', zorder=5000, linewidth=0.5)

    ax.set_xticks(xpos, datasheet['PhantomInserts']['Insert name'], rotation=45, horizontalalignment='right')

    ax.set_ylabel('$CTN_{meas} - CTN_{est}$ (HU)')
    ax.set_title('Check of estimated CT numbers')
    plt.legend()

    plt.savefig("{}/for_report/svg/Eval_box_3_ctnumber_estimation.svg".format(datasheet['output']),
                bbox_inches="tight")
    plt.savefig('{}/for_report/Eval_box_3_ctnumber_estimation.pdf'.format(datasheet['output']),
                bbox_inches="tight", dpi=300)
    
    plt.clf()
    plt.cla()
    plt.close()