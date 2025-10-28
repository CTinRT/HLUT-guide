# -*- coding: utf-8 -*-
"""
Assessment of position dependency of CT numbers

% SPDX-License-Identifier: MIT
"""

from scipy import interpolate


def main(datasheet):
    """
    Step 6: Evaluation of HLUT specification - End-to-end test.
    Evaluation of position dependency of CT numbers.
    """

    # CT number variation between bone insert in center and periphery of large phantom:
    datasheet['CTnumbers']['CT number (eval - body)'] = (
            datasheet['CTnumbers']['CT number (Body)'] - datasheet['CTnumbers']['CT number (Evaluation - Body)'])

    with open('{}/for_report/Eval_ctn_positiondependency.txt'.format(datasheet['output']), 'w') as f:
        f.write('Insert name    CTN middle (HU)    CTN outer (HU)    Difference (HU) \n')
        for i in range(0, len(datasheet['CTnumbers']['CT number (Body)'])):
            if str(datasheet['CTnumbers']['CT number (Evaluation - Body)'][i]) != 'nan':
                f.write('{}    {}    {}    {}\n'.format(
                    datasheet['CTnumbers']['Insert name'][i],
                    round(datasheet['CTnumbers']['CT number (Body)'][i]),
                    round(datasheet['CTnumbers']['CT number (Evaluation - Body)'][i]),
                    round(datasheet['CTnumbers']['CT number (eval - body)'][i])))

    # Parameter estimation accuracy for bone insert in center and periphery of large phantom:
    # Define HLUT functions:
    hlut_body = interpolate.interp1d(datasheet['HLUTs']['body']['ctn'],
                                     datasheet['HLUTs']['body'][datasheet['output_parameter']])
    # Define value used:
    if datasheet['output_parameter'] == 'SPR':
        parameter = 'SPR_calc'
    elif datasheet['output_parameter'] == 'RED':
        parameter = 'rhoe_calc'
    elif datasheet['output_parameter'] == 'MD':
        parameter = 'Density (g/cm3)'
    with open('{}/for_report/Eval_parameter_positiondependency.txt'.format(datasheet['output']), 'w') as f:
        f.write(
            'Insert name    Reference ' + datasheet['output_parameter'] + '    Est. ' + datasheet['output_parameter'] + \
            ' middle    Dev. middle (%)    Est. ' + datasheet['output_parameter'] + ' outer    Dev. outer (%)\n')
        for i in range(0, len(datasheet['CTnumbers']['CT number (Body)'])):
            if str(datasheet['CTnumbers']['CT number (Evaluation - Body)'][i]) != 'nan':
                ref_value = datasheet['PhantomInserts'][parameter][i]
                par_bone_center = hlut_body(datasheet['CTnumbers']['CT number (Body)'][i])
                par_bone_peri = hlut_body(datasheet['CTnumbers']['CT number (Evaluation - Body)'][i])
                f.write('{}    {}    {}    {}%    {}    {}%\n'.format(
                    datasheet['CTnumbers']['Insert name'][i],
                    round(ref_value, 3),
                    round(float(par_bone_center), 3),
                    round((float(par_bone_center) - ref_value) * 100, 2),
                    round(float(par_bone_peri), 3),
                    round((float(par_bone_peri) - ref_value) * 100, 2)))