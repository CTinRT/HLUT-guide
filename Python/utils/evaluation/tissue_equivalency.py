# -*- coding: utf-8 -*-
"""
Assessment of tissue equivalency of phantom materials.

% SPDX-License-Identifier: MIT
"""

import matplotlib.pyplot as plt


def main(datasheet):
    """
    Evaluation box 2: Tissue equivalency:
    Creating figures to evaluate the tissue equivalency of the phantom inserts.
    """

    # Load the data for the tabulated human tissues and phantom inserts:
    density_tissues = datasheet['TabulatedHumanTissues']['Density (g/cm3)']
    rhoe_tissues = datasheet['TabulatedHumanTissues']['rhoe_calc']
    zeff_tissues = datasheet['TabulatedHumanTissues']['Zeff_calc']
    i_tissues = datasheet['TabulatedHumanTissues']['I_calc']

    density_phantom = datasheet['PhantomInserts']['Density (g/cm3)']
    rhoe_phantom = datasheet['PhantomInserts']['rhoe_calc']
    zeff_phantom = datasheet['PhantomInserts']['Zeff_calc']
    i_phantom = datasheet['PhantomInserts']['I_calc']

    # Number of subplots:
    if datasheet['output_parameter'] == 'SPR':
        i = 3
    elif datasheet['output_parameter'] == 'RED':
        i = 1
    elif datasheet['output_parameter'] == 'MD':
        i = 2
    fig, axs = plt.subplots(i, figsize=(6, 6* i))
    alphavalue = 0.2

    # Plot of Zeff vs rhoe
    if datasheet['output_parameter'] == 'RED':
        # Only one figure to be plotted, thus no subfigure routine:
        axs.plot(rhoe_tissues, zeff_tissues, 'o', color='steelblue', label='Tabulated human tissues')
        axs.plot(rhoe_phantom, zeff_phantom, 'o', color='darkred', label='Phantom inserts')
        axs.set_title('X-ray attenuation')
        axs.legend()
        axs.set_xlabel('Relative electron density')
        axs.set_ylabel('Effective atomic number')
        axs.grid(alpha=alphavalue)
    else:
        axs[0].plot(rhoe_tissues, zeff_tissues, 'o', color='steelblue', label='Tabulated human tissues')
        axs[0].plot(rhoe_phantom, zeff_phantom, 'o', color='darkred', label='Phantom inserts')
        axs[0].set_title('X-ray attenuation')
        axs[0].legend()
        axs[0].set_xlabel('Relative electron density')
        axs[0].set_ylabel('Effective atomic number')
        axs[0].grid(alpha=alphavalue)

    if datasheet['output_parameter'] == 'MD':
        # Plot of MD vs rhoe:
        axs[1].plot(density_tissues, rhoe_tissues, 'o', color='steelblue', label='Tabulated human tissues')
        axs[1].plot(density_phantom, rhoe_phantom, 'o', color='darkred', label='Phantom inserts')
        axs[1].set_title('X-ray attenuation')
        axs[1].legend()
        axs[1].set_xlabel('Mass density (g/cm³)')
        axs[1].set_ylabel('Relative electron density')
        axs[1].grid(alpha=alphavalue)
        # Make inset for zoom in the soft tissue region:
        axins = axs[1].inset_axes([0.6, 0.09, 0.35, 0.35])
        axins.plot(density_tissues, rhoe_tissues, 'o', color='steelblue')
        axins.plot(density_phantom, rhoe_phantom, 'o', color='darkred')
        axins.set_xlim(0.88, 1.25)
        axins.set_ylim(0.9, 1.2)

    if datasheet['output_parameter'] == 'SPR':
        # Plot of I-value vs Zeff
        axs[1].plot(zeff_tissues, i_tissues, 'o', color='steelblue', label='Tabulated human tissues')
        axs[1].plot(zeff_phantom, i_phantom, 'o', color='darkred', label='Phantom inserts')
        axs[1].set_title('X-ray attenuation vs proton stopping power')
        axs[1].legend()
        axs[1].set_xlabel('Effective atomic number')
        axs[1].set_ylabel('Mean excitation energy (eV)')
        axs[1].grid(alpha=alphavalue)

        # Plot of I-value vs rhoe
        axs[2].plot(rhoe_tissues, i_tissues, 'o', color='steelblue', label='Tabulated human tissues')
        axs[2].plot(rhoe_phantom, i_phantom, 'o', color='darkred', label='Phantom inserts')
        axs[2].set_title('Proton stopping power')
        axs[2].legend()
        axs[2].set_xlabel('Relative electron density')
        axs[2].set_ylabel('Mean excitation energy (eV)')
        axs[2].grid(alpha=alphavalue)

    # Save the figures:
    plt.savefig("{}/for_report/svg/Eval_box_2_tissue_equivalence.svg".format(datasheet['output']), bbox_inches="tight")
    plt.savefig('{}/for_report/Eval_box_2_tissue_equivalence.pdf'.format(datasheet['output']), bbox_inches="tight",
                dpi=300)
    
    plt.clf()
    plt.cla()
    plt.close()