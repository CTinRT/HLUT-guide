# -*- coding: utf-8 -*-
"""
Assessment of the size-dependent impact of beam hardening on CT numbers.

% SPDX-License-Identifier: MIT
"""


def main(datasheet):
    """
    Evaluation box 1: Size-dependent impact of beam hardening on CT numbers.
    """

    # Load CT numbers for the two phantom sizes:
    ctn_head = datasheet['CTnumbers']['CT number (Head)']
    ctn_body = datasheet['CTnumbers']['CT number (Body)']

    name = datasheet['PhantomInserts']['Insert name']
    diff = ctn_head - ctn_body

    # Write the results to a file:
    with open('{}/for_report/{}.txt'.format(datasheet['output'] ,'Eval_box_1_beamhardening'), 'w') as f:
        f.write('Insert name    CT number head    CT number body    Difference\n')
        for line in range(0, len(ctn_head)):
            f.write(f'{name[line]}    ' + f'{round(ctn_head[line])}    ' +
                    f'{round(ctn_body[line])}    ' + f'{round(diff[line])} \n')