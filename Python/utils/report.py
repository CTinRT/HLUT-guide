# -*- coding: utf-8 -*-
"""
PDF creation

% SPDX-License-Identifier: MIT
"""

from datetime import datetime
from textwrap import wrap
import numpy as np
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from reportlab.platypus import Table, TableStyle
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPDF


def scale(drawing, scaling_factor):
    drawing.width *= scaling_factor
    drawing.height *= scaling_factor
    drawing.scale(scaling_factor, scaling_factor)
    return drawing

def add_text(pdf, text, x, y, font, font_size, max_width):
    pdf.setFont(font, font_size)
    wrapped_text = "\n".join(wrap(text, max_width))
    text_object = pdf.beginText(x, y)
    text_object.textLines(wrapped_text)
    pdf.drawText(text_object)
    return y - (12 * len(wrapped_text.splitlines()))  # Adjust for line height

def add_table(pdf, data, x, y, available_height, max_width):
    row_heights = 13
    required_height = len(data) * row_heights
    if required_height > available_height:
        pdf.showPage()
        y = A4[1] - 50  # Reset to top of new page with margin
    table = Table(data, style=TableStyle([
        ('FONTNAME', (0, 0), (-1, 0), 'Times-Bold'),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER')
    ]), rowHeights=row_heights)
    table.wrapOn(pdf, max_width, required_height)
    table.drawOn(pdf, x, y - required_height)
    return y - required_height - 20  # Adjust for spacing

def add_image(pdf, image_path, y, scale_factor, max_height):
    drawing = svg2rlg(image_path)
    drawing = scale(drawing, scale_factor)
    image_height = drawing.height
    if y - image_height < 50:  # Check if it fits with bottom margin
        pdf.showPage()
        y = A4[1] - 50  # Reset to top of new page with margin
    # Dynamically compute x-coordinate for center alignment
    x_center = (A4[0] - drawing.width) / 2  # A4[0] is the page width
    renderPDF.draw(drawing, pdf, x_center, y - image_height)
    return y - image_height - 20  # Adjust for spacing

def pagedesign(title, pagenumber,datasheet):
    toplineh = h-40
    bottomlineh = 50
    linel = 0.1*w
    titleh = h-75
    
    # Number of pages:
    report_lenght = '10'
    
    pdf.line(linel, toplineh, 0.9*w, toplineh)
    pdf.line(linel, bottomlineh, 0.9*w, bottomlineh)
    pdf.drawCentredString(w/2, 30, '{}/{}'.format(pagenumber,report_lenght))

    pdf.setFont('abc_b', 22)
    tp = titleh
    
    pdf.drawString(0.1*w, tp, title)
    
    return linel, tp

def rep_main(file_name, datasheet, recon_type):
    global h, w, pdf
    print('\nInitiate creation of PDF report.')

    ts1 = 11
    ts2 = 15

    today = datetime.now().strftime("%Y%m%d_%H%M%S")

    # Initialize pdf
    if recon_type == 'regular':
        pdf = canvas.Canvas('{}/{}_HLUT_evaluation_{}.pdf'.format(datasheet['output'],
                                                                  datasheet['output_parameter'], today),
                            pagesize=A4)
    elif recon_type == 'DD':
        pdf = canvas.Canvas('{}/DD_{}_HLUT_evaluation_{}.pdf'.format(datasheet['output'],
                                                                     datasheet['output_parameter'], today),
                            pagesize=A4)
    w, h = A4
    pdf.setTitle("HLUT evaluation")

    pdfmetrics.registerFont(TTFont('abc', 'Vera.ttf'))
    pdfmetrics.registerFont(TTFont('abc_b', 'VeraBd.ttf'))
    char_per_line = 80
    margin = 50
    y_position = h - margin

    # PAGE 1
    y_position -= 50
    pdf.setFont('abc_b', 22)
    pdf.drawCentredString(w / 2, y_position, 'Hounsfield Look-Up Table (HLUT)')
    y_position -= 25
    pdf.drawCentredString(w / 2, y_position, 'generation and evaluation')
    y_position -= 25
    tissue_text = {
        'MD': 'Mass density (MD)',
        'RED': 'Relative electron density (RED)',
        'SPR': 'Stopping-power ratio (SPR)'
    } 
    if recon_type == 'DD':
        pdf.drawCentredString(w / 2, y_position, 'DirectDensity (DD)')
        y_position -= 25
    pdf.drawCentredString(w / 2, y_position, '{} curve'.format(tissue_text.get(datasheet['output_parameter'], '')))
    y_position -= 50
    pdf.setFillColorRGB(1, 0, 0)  # Sets text color to red (RGB: Red, Green, Blue)
    pdf.drawCentredString(w / 2, y_position, 'The user is responsible for confirming')
    y_position -= 25
    pdf.drawCentredString(w / 2, y_position, 'the results prior to use')
    pdf.setFillColorRGB(0, 0, 0)    #Change font color back to black
    
    # Print image (exemplary HLUT)
    y_position -= 10
    image_path = "{}/for_report/svg/hlut_head.svg".format(datasheet['output'])
    y_position = add_image(pdf, image_path, y_position, 0.65, y_position - margin)

    pdf.setFont('abc', 14)  #Decrease the font size
    pdf.drawCentredString(w / 2, y_position, 'HLUT generation and evaluation tool')
    y_position -= 20
    pdf.drawCentredString(w / 2, y_position, 'following the HLUT generation guide')
    y_position -= 20
    pdf.drawCentredString(w / 2, y_position, 'DOI: 10.1016/j.radonc.2023.109675')
    y_position -= 50
    pdf.drawCentredString(w / 2, y_position, 'Report based on data stored in Excel sheet:')
    y_position -= 25
    pdf.drawCentredString(w / 2, y_position, '{}'.format(file_name))
    pdf.setFont('abc', 12)  #Change the font size
    y_position -= 50
    pdf.drawCentredString(w / 2, y_position, 'Date of creation:')
    y_position -= 25
    pdf.drawCentredString(w / 2, y_position, '{}'.format(today))

    pdf.showPage()

    # PAGE 2
    page = 1
    linel, y_position = pagedesign('Generated HLUTs', page,datasheet)
    
    y_position -= 10   
    text = 'To be visually evaluated regarding the proximity of the datapoints to the curve and the need for a' +\
           ' body size-specific HLUT, see Supplementary Material Evaluation Box 5.'
    y_position = add_text(pdf, text, margin, y_position - 50, 'abc', ts1, char_per_line)
    
    #Insert table with the HLUT for head:
    y_position = add_text(pdf, 'HLUT for head phantom', margin, y_position - 50, 'abc_b', ts2, char_per_line)
    y_position -= 10 
    hlut_head = np.genfromtxt('{}/{}_HLUT_head.txt'.format(datasheet['output'], 
                                                           datasheet['output_parameter']), dtype=str, delimiter='\t')
    hlut_head_list = hlut_head.tolist()
    y_position = add_table(pdf, hlut_head_list, margin, y_position, y_position - margin, w - 2 * margin)

    text = 'Please note: The highest point is set arbitrarily to ' + hlut_head_list[-1][0] + \
        ' HU. Please check the guide for the different options to extend the HLUT beyond this point.'
    y_position = add_text(pdf, text, margin, y_position - 7, 'abc', ts1, char_per_line)

    #Add figure of the HLUT:
    image_path = "{}/for_report/svg/hlut_head.svg".format(datasheet['output'])
    y_position = add_image(pdf, image_path, y_position-10, 0.65, y_position - margin)

    pdf.showPage()
    

    # PAGE 3
    #Add page header and page number:
    page += 1
    linel, y_position = pagedesign(' ', page,datasheet) 
    
    #HLUT for body:
    y_position -= 10
    y_position = add_text(pdf, 'HLUT for body phantom', margin, y_position, 'abc_b', ts2, char_per_line)
    
    hlut_body = np.genfromtxt('{}/{}_HLUT_body.txt'.format(datasheet['output'], 
                                                           datasheet['output_parameter']), dtype=str, delimiter='\t')
    hlut_body_list = hlut_body.tolist()
    y_position = add_table(pdf, hlut_body_list, margin, y_position, y_position - margin, w - 2 * margin)

    text = 'Please note: The highest point is set arbitrarily to ' + hlut_body_list[-1][0] + \
        ' HU. Please check the guide for the different options to extend the HLUT beyond this point.'    
    y_position = add_text(pdf, text, margin, y_position - 7, 'abc', ts1, char_per_line)

    #Add figure of the HLUT:
    image_path = "{}/for_report/svg/hlut_body.svg".format(datasheet['output'])
    y_position = add_image(pdf, image_path, y_position-10, 0.65, y_position - margin)

    pdf.showPage()
    

    # PAGE 4
    #Add page header and page number:
    page += 1
    linel, y_position = pagedesign(' ', page,datasheet) 
    
    #HLUT for averaged CT numbers:
    y_position -= 10
    y_position = add_text(pdf, 'HLUT for averaged CT numbers', margin, y_position, 'abc_b', ts2,
                          char_per_line)

    hlut_avg = np.genfromtxt('{}/{}_HLUT_avgdCT.txt'.format(datasheet['output'], 
                                                            datasheet['output_parameter']), dtype=str, delimiter='\t')
    hlut_avg_list = hlut_avg.tolist()
    y_position = add_table(pdf, hlut_avg_list, margin, y_position, y_position - margin, w - 2 * margin)

    text = 'Please note: The highest point is set arbitrarily to ' + hlut_avg_list[-1][0] + \
         ' HU. Please check the guide for the different options to extend the HLUT beyond this point.'    
    y_position = add_text(pdf, text, margin, y_position - 7, 'abc', ts1, char_per_line)

    #Add figure of the HLUT:
    image_path = "{}/for_report/svg/hlut_avgdCT.svg".format(datasheet['output'])
    y_position = add_image(pdf, image_path, y_position-10, 0.65, y_position - margin)

    pdf.showPage()
    

    # PAGE 5
    page += 1
    linel, y_position = pagedesign('HLUT evaluation results', page,datasheet)
    
    y_position -= 50
    y_position = add_text(pdf, 'Evaluation box 1: Size-dependent impact of beam hardening',
                          margin, y_position, 'abc_b', ts2, 50)
    
    #Add table:
    eval_1 = np.genfromtxt('{}/for_report/Eval_box_1_beamhardening.txt'.format(datasheet['output']), dtype=str,
                           delimiter='    ')
    eval_1_list = eval_1.tolist()
    y_position = add_table(pdf, eval_1_list, margin, y_position, y_position - margin, w - 2 * margin)

    pdf.showPage()
    

    # PAGE 6
    #Add page header and page number:
    page += 1
    linel, y_position = pagedesign(' ', page,datasheet) 
    
    
    y_position = add_text(pdf, 'Evaluation box 2: Tissue equivalency of phantom inserts', margin,
                          y_position+3, 'abc_b', ts2, 50)
    tissue_text = {
        'MD': 'Tissue equivalency for photon therapy and mass density.',
        'RED': 'Tissue equivalency for photon therapy and relative electron density.',
        'SPR': 'Tissue equivalency for proton therapy and stopping-power ratio.'
    }
    y_position = add_text(pdf, tissue_text.get(datasheet['output_parameter'], ''), margin, y_position - 25,
                          'abc', ts1, char_per_line)

    image_path = "{}/for_report/svg/Eval_box_2_tissue_equivalence.svg".format(datasheet['output'])
    y_position = add_image(pdf, image_path, y_position, 0.45, y_position - margin)

    pdf.showPage()
    

    # PAGE 7
    page += 1
    linel, y_position = pagedesign(' ', page,datasheet) 
    
    y_position = add_text(pdf, 'Evaluation box 3: Check of estimated CT numbers', margin, y_position+3,
                          'abc_b', ts2, 50)

    #Add tables:
    y_position = add_text(pdf, 'Head phantom', margin, y_position-10, 'abc_b', ts1, char_per_line)
    eval_3 = np.genfromtxt('{}/for_report/Eval_box_3_CTnumber_estimation_head.txt'.format(datasheet['output']),
                           dtype=str, delimiter='    ')
    eval_3_list = eval_3.tolist()
    y_position = add_table(pdf, eval_3_list, margin, y_position, y_position - margin, w - 2 * margin)
    
    y_position = add_text(pdf, 'Body phantom', margin, y_position+3, 'abc_b', ts1, char_per_line)
    eval_3_body = np.genfromtxt('{}/for_report/Eval_box_3_CTnumber_estimation_body.txt'.format(datasheet['output']),
                                dtype=str, delimiter='    ')
    eval_3_body_list = eval_3_body.tolist()
    y_position = add_table(pdf, eval_3_body_list, margin, y_position+3, y_position - margin, w - 2 * margin)

    image_path = "{}/for_report/svg/Eval_box_3_ctnumber_estimation.svg".format(datasheet['output'])
    y_position = add_image(pdf, image_path, y_position, 0.55, y_position - margin)

    pdf.showPage()
    

    # PAGE 8
    if datasheet['output_parameter'] == 'SPR' and not(np.isnan(datasheet['PhantomInserts']['SPR Measured'][0])):
        page += 1
        linel, y_position = pagedesign(' ', page,datasheet)
        
        y_position = add_text(pdf, 'Evaluation box 4: Consistency of SPR values', margin, y_position+3,
                              'abc_b', ts2, 50)
        
        #Add table:
        eval_spr = np.genfromtxt('{}/for_report/Eval_box_4_spr_estimation.txt'.format(datasheet['output']),
                                 dtype=str, delimiter='    ')
        eval_spr_list = eval_spr.tolist()
        y_position = add_table(pdf, eval_spr_list, margin, y_position, y_position - margin, w - 2 * margin)
        #Add figure:
        image_path = "{}/for_report/svg/Eval_box_4_spr_estimation.svg".format(datasheet['output'])
        y_position = add_image(pdf, image_path, y_position, 0.6, y_position - margin)

        pdf.showPage()
    
    elif datasheet['output_parameter'] == 'SPR' and np.isnan(datasheet['PhantomInserts']['SPR Measured'][0]):
        page += 1
        linel, y_position = pagedesign(' ', page,datasheet)
        
        y_position = add_text(pdf, 'Evaluation box 4: No measured SPR values have been provided. ' +\
                              'This evaluation is therefore skipped.',
                              margin, y_position+3, 'abc_b', ts2, 50)
        pdf.showPage()
    else:
        page += 1
        linel, y_position = pagedesign(' ', page,datasheet)
        
        y_position = add_text(pdf, 'Evaluation box 4: This evaluation is only relevant for SPR HLUTs. ' +\
                              'This evaluation is therefore skipped.',
                              margin, y_position+3, 'abc_b', ts2, 50)
        pdf.showPage()
        

    # PAGE 9
    page += 1
    linel, y_position = pagedesign(' ', page,datasheet)
    
    y_position = add_text(pdf, 'Evaluation box 5: HLUT comparison', margin, y_position+3, 'abc_b',
                          ts2, 50)
    image_path = "{}/for_report/svg/Eval_box_5_hlut_comp.svg".format(datasheet['output'])
    y_position = add_image(pdf, image_path, y_position, 0.6, y_position - margin)

    pdf.showPage()
    

    # PAGE 10
    page += 1
    linel, y_position = pagedesign(' ', page,datasheet)
    
    y_position = add_text(pdf, 'End-to-end testing: Evaluation of the generated HLUT', margin, y_position+3,
                          'abc_b', ts2, char_per_line)
    y_position = add_text(pdf, 'Evaluation of the HLUT fitting accuracy', margin, y_position-6, 'abc_b',
                          ts1, char_per_line)
    str_i = 'Difference between the reference' +\
            ' {} values and those predicted using the HLUTs.'.format(datasheet['output_parameter'])
    y_position = add_text(pdf, str_i, margin, y_position-3, 'abc', ts1, char_per_line)
  
    # Print image (HLUT comparison)
    image_path = "{}/for_report/svg/Eval_endtoend_hlut_accuracy.svg".format(datasheet['output'])
    y_position = add_image(pdf, image_path, y_position, 0.6, y_position - margin)
    
    #Tables:
    y_position = add_text(pdf, 'HLUT fitting accuracy for head and body with' +\
                          ' respective HLUT (fit vs individual datapoints):',
                          margin, y_position+3, 'abc', ts1, char_per_line)
    y_position = add_text(pdf, 'Head phantom:', margin, y_position-3, 'abc_b', ts1, char_per_line)
    accuracy_head = np.genfromtxt('{}/for_report/eval_box_6_accuracy_head.txt'.format(datasheet['output']),
                                  dtype=str, delimiter='    ')
    accuracy_head_list = accuracy_head.tolist()
    y_position = add_table(pdf, accuracy_head_list, margin, y_position, y_position - margin, w - 2 * margin)
    y_position = add_text(pdf, 'Body phantom:', margin, y_position+3, 'abc_b', ts1, char_per_line)
    accuracy_body = np.genfromtxt('{}/for_report/eval_box_6_accuracy_body.txt'.format(datasheet['output']),
                                  dtype=str, delimiter='    ')
    accuracy_body_list = accuracy_body.tolist()
    y_position = add_table(pdf, accuracy_body_list, margin, y_position, y_position - margin, w - 2 * margin)

    

    pdf.showPage()
    

    # PAGE 11
    page += 1
    linel, y_position = pagedesign(' ', page,datasheet)
    
    y_position = add_text(pdf, 'CT number location dependency', margin, y_position+3, 'abc_b', ts2,
                          char_per_line)

    #Table with CT number difference between bone inserts in the center and periphery of large phantom:
    ct_dependency = np.genfromtxt('{}/for_report/Eval_CTN_positiondependency.txt'.format(datasheet['output']),
                                  dtype=str, delimiter='    ')
    ct_dependency_list = ct_dependency.tolist()
    y_position = add_table(pdf, ct_dependency_list, margin, y_position, y_position - margin, w - 2 * margin)

    #Parameter estimates for bone inserts in the center and periphery of large phantom:
    ct_dependency = np.genfromtxt('{}/for_report/Eval_parameter_positiondependency.txt'.format(datasheet['output']),
                                  dtype=str, delimiter='    ')
    ct_dependency_list = ct_dependency.tolist()
    y_position = add_table(pdf, ct_dependency_list, margin, y_position, y_position - margin, w - 2 * margin)

    pdf.showPage()
    

    # Finalize PDF
    pdf.save()
    print('\nPDF generation completed.')
