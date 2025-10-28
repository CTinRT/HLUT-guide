# -*- coding: utf-8 -*-
"""
HLUT export and plot functions for the HLUT definition

% SPDX-License-Identifier: MIT
"""

from utils import report, control_input

from utils.calculation import fit_and_estimate_ctnumbers
from utils.calculation import fit_and_plot_hluts
from utils.calculation import initialize_data

from utils.evaluation import estimation_ctnumber
from utils.evaluation import hlut_accuracy
from utils.evaluation import hlut_assessment
from utils.evaluation import position_dependency_ctnumber
from utils.evaluation import size_dependency_ctnumber
from utils.evaluation import spr_comparison
from utils.evaluation import tissue_equivalency

import os
import matplotlib.pyplot as plt

def main(input_folder_name, file_name, output_parameter, recon_type, output_folder_name, e_prot):
    ##############################################################
    # CODE INITIALIZATION ########################################
    ##############################################################

    #Close figures from last loop:
    plt.close('all')

    print('Start of HLUT generation.')

    # Set working directory to the script location of main.py
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    # Check if output_parameter is valid
    control_input.check_parameters(output_parameter, recon_type)

    # Initialize the data:
    datasheet = initialize_data.main(output_folder_name, output_parameter, input_folder_name,
                                     file_name, e_prot)

    # Make fits based on the CT numbers for the phantom inserts and estimate CT numbers for tabulated human tissues
    fit_and_estimate_ctnumbers.main(datasheet, recon_type)

    # Fit HLUTs, write them to text files and plot the curves
    fit_and_plot_hluts.main(datasheet, recon_type)

    ##############################################################
    # Evaluate HLUTs #############################################
    ##############################################################

    print('\nStart evaluation of the created HLUT.')

    # Evaluation box 1: CT number dependence on phantom size
    size_dependency_ctnumber.main(datasheet)

    # Evaluation box 2: Tissue equivalency of phantom inserts
    tissue_equivalency.main(datasheet)

    # Evaluation box 3: Check of CT number estimation method
    estimation_ctnumber.main(datasheet)

    # Evaluation box 4: Comparison of measured and theoretical SPR values
    if datasheet['output_parameter'] == 'SPR':
        spr_comparison.main(datasheet)

    # Evaluation box 5: Check the need for body-site specific HLUTs
    hlut_assessment.main(datasheet, recon_type)

    # End-to-end testing: Evaluation of HLUT accuracy
    hlut_accuracy.main(datasheet)

    # End-to-end testing: Evaluation of position dependency of CT numbers
    position_dependency_ctnumber.main(datasheet)

    ##############################################################
    # Create report pdf ##########################################
    ##############################################################

    try:
        report.rep_main(file_name, datasheet, recon_type)
    except:
        print('Something went wrong in the PDF report creation. \n'
              'Everything else worked. Individual results are stored as figures '
              'or .txt files in the Results folder.')

    print('\n###############################\nFinished.\n###############################')
    
    return datasheet
