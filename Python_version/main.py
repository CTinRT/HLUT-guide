# -*- coding: utf-8 -*-
"""

Run file for the HLUT generation and evaluation.
Python implementation: Nils Peters
Matlab implementation: Vicki Taasti
Version 1.0, 05/08/2023

% HLUT calibration and evaluation code, Copyright (c) 2023, MAASTRO.
% 
% This software (any code and/or associated documentation: the “Software”)
% is distributed under the terms of the MIT license (the “License”).
% Refer to the License for more details. You should have received a copy of
% the License along with the code. If not, see 
% https://choosealicense.com/licenses/mit/.
% SPDX-License-Identifier: MIT
%
% PLEASE NOTE THAT THIS SOFTWARE IS NOT PUBLISHED AS (AN ACCESSORY TO) A 
# MEDICAL DEVICE!
% Read the README file for more details.
%

"""

import os
import pandas as pd
import calculations  # module containing the calculation functions
import evaluation  # module containing HLUT export and plot of results
import report  # module containing the pdf report creation
import logger  # to print potential error messages

  
if __name__ == "__main__":
    
    #################################################
    #################################################
    # PARAMETER DEFINITION ##########################
    # Define path for data input ####################
    excelfile = 'input/DataForCTCalibration_Siemens_goOpenPro_120kVp.xlsx'
    E_prot = 100  # proton beam energy in MeV
    ##############################################################
    ##############################################################

    note = "{}\n{} {}\n{}\n{}\n".format('###############################',
                                        'Welcome to the HLUT generation and validation tool. The tool',
                                        'follows the guide described in DOI: 10.1016/j.radonc.2023.109675',
                                        'Please check that all data in the excel sheet matches your setup.',
                                        '###############################')
    print(note)
    
    print('Start of HLUT generation...')
    # Initialize output folders
    if not os.path.exists('Results/for_report/svg'):
        os.makedirs('Results/for_report/svg')

    # Load data from excel file
    print('Loading CT number and measured SPR values from excel sheet...')
    datasheet = {}
    xls = pd.ExcelFile(excelfile)
    for sheet_name in xls.sheet_names:
        datasheet[sheet_name] = xls.parse(sheet_name)
    
    # Import parameters for water, elemental composition and constant values
    rho_w, Zi_w, Ai_w, Wi_w, Ii_w, E_0, m_e, elements = (calculations.import_initialdata())
    
    # Calculate SPR for phantom inserts and tabulated human tissues    
    print('Calculate CT number and SPR for tabulated human tissues...')
    (datasheet['TabulatedHumanTissues']['SPR_calc'], datasheet['TabulatedHumanTissues']['rhoe_calc'],
     datasheet['TabulatedHumanTissues']['Zeff_calc'], datasheet['TabulatedHumanTissues']['I_calc']) = (
        calculations.spr_calculation(datasheet, E_prot, 'TabulatedHumanTissues'))
          
    (datasheet['PhantomInserts']['SPR_calc'], datasheet['PhantomInserts']['rhoe_calc'],
     datasheet['PhantomInserts']['Zeff_calc'], datasheet['PhantomInserts']['I_calc']) = (
        calculations.spr_calculation(datasheet, E_prot, 'PhantomInserts'))

    # Add averaged CT numbers to CT number input sheet
    ctn_head = datasheet['CTnumbers']['CT number (Head)'] 
    ctn_body = datasheet['CTnumbers']['CT number (Body)'] 
    datasheet['CTnumbers']['CT number (averaged)'] = 0.5*(ctn_head+ctn_body)

    #
    # Calculate k values for stoichiometric calibration
    k_head = calculations.k_value_fit(datasheet, 'CT number (Head)')['x']
    k_body = calculations.k_value_fit(datasheet, 'CT number (Body)')['x']
    k_avgCT = calculations.k_value_fit(datasheet, 'CT number (averaged)')['x']

    # Calculate CT numbers for the tabulated human tissues
    datasheet['TabulatedHumanTissues']['ctn_calc_head'] = ( 
        calculations.ctn_calculation(datasheet, 'TabulatedHumanTissues', k_head))
    datasheet['TabulatedHumanTissues']['ctn_calc_body'] = ( 
        calculations.ctn_calculation(datasheet, 'TabulatedHumanTissues', k_body))
    datasheet['TabulatedHumanTissues']['ctn_calc_avgCT'] = ( 
        calculations.ctn_calculation(datasheet, 'TabulatedHumanTissues', k_avgCT))
    
    # Calculate CT numbers for the phantom inserts (for quality check)
    datasheet['PhantomInserts']['ctn_calc_head'] = ( 
        calculations.ctn_calculation(datasheet, 'PhantomInserts', k_head))
    datasheet['PhantomInserts']['ctn_calc_body'] = ( 
        calculations.ctn_calculation(datasheet, 'PhantomInserts', k_body))
    datasheet['PhantomInserts']['ctn_calc_avgCT'] = ( 
        calculations.ctn_calculation(datasheet, 'PhantomInserts', k_avgCT))

    #
    # Initiate datasheet for HLUTs
    print('Fit HLUT in different tissue regions and set connection points...')
    datasheet['HLUTs'] = {}
    
    # Initiate loop parameters for HLUT generation
    hluttype = ['head', 'body', 'avgdCT']  # the three parameter sets
    phantomtype = ['CT number (Head)', 'CT number (Body)', 'CT number (averaged)']  # respective phantom CT numbers
    ctnumbertype = ['ctn_calc_head', 'ctn_calc_body', 'ctn_calc_avgCT']  # respective calculated CT numbers

    # Fit CT numbers and generate HLUT
    for i in range(0, len(hluttype)):
        print('\nGeneration of HLUT for CT numbers from {}'.format(hluttype[i]))
        datasheet['HLUTs'][hluttype[i]] = {}
        (datasheet['HLUTs'][hluttype[i]]['ctn'], datasheet['HLUTs'][hluttype[i]]['spr'], sprtype) = (
            calculations.hlut_fit(datasheet, phantomtype[i], ctnumbertype[i]))
               
    print('Export final HLUTs for different body sites...')
    # Export HLUTs to txt files, saved in output folder
    evaluation.hlut_export(datasheet, hluttype)
        
    print('\nStart evaluation of the created HLUT.')
    # Plot results, saved in output folder
    evaluation.plot_hlut(datasheet, hluttype)
    
    # Evaluation steps, saved in output folder
    evaluation.evaluation_steps(datasheet)

    # Create report pdf
    try:
        report.rep_main(excelfile, sprtype)
    # except:
    except BaseException as e:
        logger.error('Failed to do something: ' + str(e))
        print('Something went wrong in the report creation. \n'
              'Everything else worked. Individual results are stored as figures '
              'or .txt files in the Results folder.')

    print('\n###############################\nFinished.\n###############################')
