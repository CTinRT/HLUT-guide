# -*- coding: utf-8 -*-
"""
Control functions for input values

% SPDX-License-Identifier: MIT
"""

import argparse
import numpy as np


def check_parameters(output_parameter, recon_type):
    """
    Checks if the input variable "output_parameter" is valid.
    Valid options for output_parameter are:
    - 'MD' (photons only)
    - 'RED' (photons only)
    - 'SPR' (protons only)

    And check if the input variable "recon_type" is consistent with "output_parameter".
    output_parameter = 'SPR' and recon_type = 'DD' do not go together.

    Input:
        output_parameter - Input variable to be checked
        recon_type         - Reconstruction type

    Returns ValueError - If output_parameter is not one of the allowed values,
    or if output_parameter and recon_type do not match.
    """

    # Check the output parameter:
    valid_parameters = ['MD', 'RED', 'SPR']
    if output_parameter not in valid_parameters:
        raise ValueError(f"Invalid output_parameter '{output_parameter}'. "
                         f"Allowed values are: {', '.join(valid_parameters)}.")

    # Check the input variable recon_type:
    valid_parameters = ['regular', 'DD']
    if recon_type not in valid_parameters:
        raise ValueError(f"Invalid recon_type '{recon_type}'. "
                         f"Allowed values are: {', '.join(valid_parameters)}.")

    
def command_line_input(input_folder_name, file_name, output_parameter, recon_type, output_folder_name, e_prot):
    """
    Parse command line arguments, if used.
    Returns:
        args: Parsed command line arguments.
    """
    parser = argparse.ArgumentParser(description='HLUT generation and evaluation tool.')
    parser.add_argument('--input_folder_name', type=str, required=False, default=input_folder_name,
                        nargs='+',
                        help='Name of the input folder where the excel file with CT numbers is located.')
    parser.add_argument('--file_name', type=str, required=False, default=file_name, nargs='+',
                        help='Name of the excel file with CT numbers and phantom data.')
    parser.add_argument('--output_parameter', type=str, required=False, default=output_parameter,
                        nargs='+',
                        help='Output parameter for the HLUT. Options: MD, RED, SPR.')
    parser.add_argument('--recon_type', type=str, required=False, default=recon_type, nargs='+',
                        help='Type of HLUT to create. Options: regular, DD.')
    parser.add_argument('--output_folder_name', type=str, required=False, default=output_folder_name,
                        nargs='+',
                        help='Name of the output folder where results will be stored.')
    parser.add_argument('--e_prot', type=float, required=False, default=e_prot, nargs='+',
                        help='Initial energy of the proton beam (MeV). Only needed for SPR HLUTs.')

    # Check for multiple input
    return check_arguments(parser.parse_args())


def check_arguments(args):
    """
    Check if multiple arguments are provided and if their lengths match.
    If only single values are provided, convert them to lists for uniform processing.
    Args:
        args: Parsed command line arguments.
    Returns:
        args: Updated arguments with lists.
    """

    # Determine the number of values for each argument
    number_of_values = []
    for attribute in vars(args):
        value = getattr(args, attribute)
        if isinstance(value, list):
            number_of_values.append(len(value))
        else:
            number_of_values.append(1)

    # Determine the maximum number of values
    if len(np.unique(number_of_values)) == 1:
        max_values = number_of_values[0]
    elif (len(np.unique(number_of_values)) == 2) and (1 in number_of_values):
        max_values = max(number_of_values)
    else:
        raise ValueError("All input arguments must have the same number of values, "
                         "or only one value (which will be used for all).")

    # Convert single values to lists
    for attribute in vars(args):
        value = getattr(args, attribute)
        if isinstance(value, list) and len(value)==1:
            value = value[0]
        if not isinstance(value, list):
            setattr(args, attribute, [value] * max_values)

    return args
