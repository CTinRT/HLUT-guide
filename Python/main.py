# -*- coding: utf-8 -*-
"""

Run file for the HLUT generation and evaluation.

HLUT calibration and evaluation code, Copyright (c) 2025, CT-in-RT working group.
 
This software (any code and/or associated documentation: the “Software”)
is distributed under the terms of the MIT license (the “License”).
Refer to the License for more details. You should have received a copy of
the License along with the code. If not, see 
https://choosealicense.com/licenses/mit/.
SPDX-License-Identifier: MIT

PLEASE NOTE THAT THIS SOFTWARE IS NOT PUBLISHED AS (AN ACCESSORY TO) A MEDICAL DEVICE!
Read the README file for more details.

"""

from utils import hlut_generation_and_evaluation, control_input
import numpy as np


if __name__ == "__main__":

    #################################################
    # PARAMETER DEFINITION ##########################
    #################################################

    # Define Excel file with CT numbers:
    # Input folder name:
    # EXAMPLE:
    #   Option 1 - one input: input_folder_name = 'Input_folder'
    #   Option 2 - multiple inputs: input_folder_name = ['Input_folder', 'Input_folder']
    input_folder_name = 'Input_folder'

    # File name of Excel file with CT numbers and phantom data:
    # EXAMPLE:
    #   Option 1 - one input: file_name = 'DataForCTCalibration_Siemens_goOpenPro_120kVp.xlsx'
    #   Option 2 - multiple inputs: file_name = ['DataForCTCalibration_Siemens_goOpenPro_120kVp.xlsx',
    #                                            'DataForCTCalibration_GE_Revolution_120kVp.xlsx']
    file_name = 'DataForCTCalibration_Siemens_goOpenPro_120kVp.xlsx'

    # Define the wanted output:
    # OPTIONS:
    # 1) 'MD' (photons only)
    # 2) 'RED' (photons only)
    # 3) 'SPR' (protons only)
    # NOTE:
    # If MD is chosen, a direct MD-HLUT is obtained - this is NOT recommended for protons
    # (see explanation in the guide).
    # EXAMPLE:
    #   Option 1 - one input: output_parameter = 'SPR'
    #   Option 2 - multiple inputs: output_parameter = ['MD', 'RED']
    output_parameter = 'SPR'

    # recon_type - reconstruction type:
    # Indicate which type of HLUTs should be created.
    #
    # OPTIONS:
    # 1) 'regular' - HLUTs for regular CT number reconstructions
    # 2) 'DD'      - HLUTs for DirectDensity reconstructions
    # EXAMPLE:
    #   Option 1 - one input: recon_type = 'regular'
    #   Option 2 - multiple inputs: recon_type = ['regular', 'regular']
    recon_type = 'regular'


    # Folder name to save the results to:
    # EXAMPLE:
    #   Option 1 - one input: output_folder_name = 'Results'
    #   Option 2 - multiple inputs: output_folder_name = ['Results', 'Results']
    output_folder_name = 'Results'

    # Initial energy of proton beam (MeV):
    # This value is only needed for SPR. But for the code to run smoothly, 
    # don't delete this even if an MD or RED HLUT is needed. In this case, the 
    # parameter is just ignored.
    # EXAMPLE:
    #   Option 1 - one input: e_prot = 100
    #   Option 2 - multiple inputs: e_prot = [100, 100]
    e_prot = 100

    #################################################
    # Run script ####################################
    #################################################

    # Parse command line arguments, if available:
    input_parameters = control_input.command_line_input(input_folder_name, 
                                            file_name, output_parameter, recon_type,
                                            output_folder_name, e_prot)

    # Run the HLUT generation and evaluation for each set of input parameters:
    note = "\n{}\n{} {}\n{}\n{}\n".format('###############################',
                                        'Welcome to the HLUT generation and validation tool. The tool',
                                        'follows the guide described in DOI: 10.1016/j.radonc.2023.109675',
                                        'Please check that all data in the excel sheet matches your setup.',
                                        '###############################')
    print(note)
    del note
        
    results = []
    for i in np.arange(len(input_parameters.recon_type)):
        print('\nRunning HLUT number {}/{}:'.format(i + 1, len(input_parameters.recon_type)))
        results.append({'file_name': input_parameters.file_name[i],
                        'output_parameter': input_parameters.output_parameter[i],
                        'results': hlut_generation_and_evaluation.main(input_parameters.input_folder_name[i], 
                                                input_parameters.file_name[i],
                                                input_parameters.output_parameter[i], 
                                                input_parameters.recon_type[i],
                                                input_parameters.output_folder_name[i], 
                                                input_parameters.e_prot[i])})

    del i, input_parameters