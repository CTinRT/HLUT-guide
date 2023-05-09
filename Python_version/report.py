# -*- coding: utf-8 -*-
"""
Run file for the HLUT generation and evaluation.
Python implementation: Nils Peters
Matlab implementation: Vicki Taasti
Version 1.0, 05/01/2023

% SPDX-License-Identifier: MIT
"""

from datetime import date
from textwrap import wrap
import numpy as np

from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4

from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from reportlab.platypus import Table, TableStyle  # for tables

from svglib.svglib import svg2rlg
from reportlab.graphics import renderPDF


def scale(drawing, scaling_factor):
    """
    scale a reportlab.graphics.shapes.drawing()
    object while maintaining the aspect ratio
    """
    scaling = scaling_factor

    drawing.width = drawing.width * scaling
    drawing.height = drawing.height * scaling
    drawing.scale(scaling, scaling)
    return drawing


def pagedesign(title, pagenumber):
    toplineh = h-40
    bottomlineh = 50
    linel = 0.1*w
    titleh = h-75
    
    pdf.line(linel, toplineh, 0.9*w, toplineh)
    pdf.line(linel, bottomlineh, 0.9*w, bottomlineh)
    pdf.drawCentredString(w/2, 30, '{}/10'.format(pagenumber))

    pdf.setFont('abc', 22)
    tp = titleh
    
    pdf.drawString(0.1*w, tp, title)
    
    return linel, tp


def rep_main(excelfile, sprtype):
    global h, w, pdf
    print('Initiate creation of PDF report')

    ts1 = 12
    today = date.today()

    # Initialize pdf
    pdf = canvas.Canvas('results/HLUT_evaluation_{}.pdf'.format(today), pagesize=A4)
    w, h = A4
    pdf.setTitle("HLUT evaluation")
    
    # registering an external font in python
    pdfmetrics.registerFont(TTFont('abc', 'times.ttf'))
    pdfmetrics.registerFont(TTFont('abc_b', 'timesbd.ttf'))

    #
    # PAGE 1
    #
    pdf.setFont('abc', 22)
    tp = h-75
    pdf.drawCentredString(w/2, tp, 'Hounsfield Look-Up Table (HLUT)')
    tp = tp - 25
    pdf.drawCentredString(w/2, tp, 'generation and evaluation')
        
    pdf.setFillColorRGB(255, 0, 0)
    tp = tp - 50    
    pdf.drawCentredString(w/2, tp, 'Intended for research use only')
    
    # Print image (exemplary HLUT)
    drawing = svg2rlg("Results/for_report/svg/hlut_head.svg")
    drawing = scale(drawing, 0.65)
    renderPDF.draw(drawing, pdf, 10, 400)    
    
    pdf.setFillColorRGB(0, 0, 0)    
    tp = tp - 400
    pdf.drawCentredString(w/2, tp, 'HLUT generation and evaluation tool')
    pdf.drawCentredString(w/2, tp-25, 'following the HLUT generation guide')
    pdf.drawCentredString(w/2, tp-50, 'DOI: 10.1016/j.radonc.2023.109675')
    pdf.drawCentredString(w/2, tp-75, 'Report based on data stored in Excel sheet')
    pdf.drawCentredString(w/2, tp-100, '{}'.format(excelfile))
    
    pdf.drawCentredString(w/2, tp-175, 'Date of creation:')
    pdf.drawCentredString(w/2, tp-200, '{}'.format(today))
    
    pdf.showPage()
    print('Page 1 done')
    
    #
    # PAGE 2
    #
    page = 1
    linel, tp = pagedesign('Generated HLUTs', page)

    # Page content
    # Front text    
    pdf.setFont('abc', ts1)
    text = '{} {}'.format('To be visually evaluated regarding the proximity of the datapoints to the curve and the',
                          'need for a body size-specific HLUT, see Supplementary Material Evaluation Box 5.')
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-25)
    t.textLines(text_wrapped)
    pdf.drawText(t)

    pdf.setFont('abc_b', ts1)
    pdf.drawString(0.15*w, tp-75, 'HLUT for head phantom')
    pdf.setFont('abc', ts1)

    # Print first HLUT
    hlut_head = np.genfromtxt('Results/HLUT_head.txt', dtype=str, delimiter='    ')
    hlut_head_list = hlut_head.tolist()

    grid = [('FONTNAME', (0, 0), (-1, 0), 'Times-Bold'),  # makes the first row bold
            ('ALIGN', (0, 0), (0, -1), 'CENTRE')]  # makes both columns aligned centrally
    
    t1 = Table(hlut_head_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 75 - len(hlut_head)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)
    
    # Print disclaimer for highest value
    text = '{} {}'.format('Please note: The highest point is set arbitrarily to 2000 HU. Please check the guide for',
                          'the different options to extend the HLUT beyond this point.')
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-275)
    t.textLines(text_wrapped)
    pdf.drawText(t)

    # Print image (head HLUT)
    drawing = svg2rlg("Results/for_report/svg/hlut_head.svg")
    drawing = scale(drawing, 0.60)
    renderPDF.draw(drawing, pdf, 30, 200)    
    
    pdf.showPage()
    print('Page {} done'.format(page + 1))
    
    #
    # PAGE 3
    #
    # load page header and define title
    page += 1
    linel, tp = pagedesign(' ', page) 

    pdf.setFont('abc_b', ts1)
    pdf.drawString(0.15*w, tp-75, 'HLUT for body phantom')
    pdf.setFont('abc', ts1)

    # Print second HLUT
    hlut_head = np.genfromtxt('Results/HLUT_body.txt', dtype=str, delimiter='    ')
    hlut_head_list = hlut_head.tolist()

    grid = [('FONTNAME', (0, 0), (-1, 0), 'Times-Bold'),  # makes the first row bold
            ('ALIGN', (0, 0), (0, -1), 'CENTRE')]  # makes both columns aligned centrally
    
    t1 = Table(hlut_head_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 75 - len(hlut_head)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)

    # Print disclaimer for highest value
    text = '{} {}'.format('Please note: The highest point is set arbitrarily to 2000 HU. Please check the guide for',
                          'the different options to extend the HLUT beyond this point.')
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-275)
    t.textLines(text_wrapped)
    pdf.drawText(t)

    # Print image (body HLUT)
    drawing = svg2rlg("Results/for_report/svg/hlut_body.svg")
    drawing = scale(drawing, 0.60)
    renderPDF.draw(drawing, pdf, 30, 200)     

    pdf.showPage()
    print('Page {} done'.format(page + 1))

    #
    # PAGE 4
    #
    page += 1
    # load page header and define title
    linel, tp = pagedesign(' ', page) 

    pdf.setFont('abc_b', ts1)
    pdf.drawString(0.15*w, tp-75, 'HLUT for averaged CT numbers')
    pdf.setFont('abc', ts1)

    # Print second HLUT
    hlut_head = np.genfromtxt('Results/HLUT_avgdCT.txt', dtype=str, delimiter='    ')
    hlut_head_list = hlut_head.tolist()

    grid = [('FONTNAME', (0, 0), (-1, 0), 'Times-Bold'),  # makes the first row bold
            ('ALIGN', (0, 0), (0, -1), 'CENTRE')]  # makes both columns aligned centrally
    
    t1 = Table(hlut_head_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 75 - len(hlut_head)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)

    # Print disclaimer for highest value
    text = '{} {}'.format('Please note: The highest point is set arbitrarily to 2000 HU. Please check the guide for',
                          'the different options to extend the HLUT beyond this point.')
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-275)
    t.textLines(text_wrapped)
    pdf.drawText(t)

    # Print image (avgd HLUT)
    drawing = svg2rlg("Results/for_report/svg/HLUT_avgdCT.svg")
    drawing = scale(drawing, 0.60)
    renderPDF.draw(drawing, pdf, 30, 200)       
    
    pdf.showPage()
    print('Page {} done'.format(page + 1))

    #
    # PAGE 5
    #
    page += 1
    # load page header and define title
    linel, tp = pagedesign('HLUT evaluation results', page)

    # Page content
    # Front text    
    pdf.setFont('abc_b', ts1)
    text = 'Evaluation box 1: Size-dependent impact of beam hardening on CT numbers'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-25)
    t.textLines(text_wrapped)
    pdf.drawText(t)

    # Print evaluation 1 from table
    eval_1 = np.genfromtxt('Results/for_report/Eval_box_1_beamhardening.txt', dtype=str, delimiter='    ')
    eval_1_list = eval_1.tolist()

    grid = [('FONTNAME', (0, 0), (-1, 0), 'Times-Bold'),  # makes the first row bold
            ('ALIGN', (1, 0), (-1, -1), 'CENTRE')]  # makes both columns aligned centrally
    
    t1 = Table(eval_1_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 50 - len(hlut_head)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)

    pdf.showPage()
    print('Page {} done'.format(page + 1))

    #
    # PAGE 6
    #
    page += 1
    # load page header and define title
    linel, tp = pagedesign(' ', page)
    
    # Page content
    # Front text    
    pdf.setFont('abc_b', ts1)
    text = 'Evaluation box 2: Tissue-equivalency of phantom inserts'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-25)
    t.textLines(text_wrapped)
    pdf.drawText(t)

    # Print image (tissue equivalency)
    drawing = svg2rlg("Results/for_report/svg/Eval_box_2_tissue_equivalence.svg")
    drawing = scale(drawing, 0.45)
    renderPDF.draw(drawing, pdf, 120, 75)       
    
    pdf.showPage()
    print('Page {} done'.format(page + 1))
    
    #
    # PAGE 7
    #
    page += 1
    # load page header and define title
    linel, tp = pagedesign(' ', page)
    
    # Page content
    # Front text    
    pdf.setFont('abc_b', ts1)
    text = 'Evaluation box 3: Check of estimated CT numbers'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-25)
    t.textLines(text_wrapped)
    pdf.drawText(t)

    pdf.setFont('abc', ts1)
    text = 'Comparison of measured and estimated CT numbers for the phantom inserts'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-50)
    t.textLines(text_wrapped)
    pdf.drawText(t)

    pdf.setFont('abc_b', ts1)
    pdf.drawString(0.15*w, tp-75, 'Head phantom:')
    pdf.setFont('abc', ts1)

    # Print evaluation 3 from table
    eval_3 = np.genfromtxt('Results/for_report/Eval_box_3_CTnumber_estimation_head.txt', dtype=str, delimiter='    ')
    eval_3_list = eval_3.tolist()

    grid = [('FONTNAME', (0, 0), (-1, 0), 'Times-Bold'),  # makes the first row bold
            ('ALIGN', (1, 0), (-1, -1), 'CENTRE')]  # makes both columns aligned centrally
    
    t1 = Table(eval_3_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 90 - len(hlut_head)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)

    pdf.setFont('abc_b', ts1)
    pdf.drawString(0.15*w, tp-285, 'Body phantom:')
    pdf.setFont('abc', ts1)

    eval_3_2 = np.genfromtxt('Results/for_report/Eval_box_3_CTnumber_estimation_body.txt', dtype=str, delimiter='    ')
    eval_3_2_list = eval_3_2.tolist()

    t1 = Table(eval_3_2_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 300 - len(hlut_head)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)

    # Print image (CT number difference)
    drawing = svg2rlg("Results/for_report/svg/Eval_box_3_ctnumber_estimation.svg")
    drawing = scale(drawing, 0.60)
    renderPDF.draw(drawing, pdf, 65, 55)        

    pdf.showPage()
    print('Page {} done'.format(page + 1))

    #
    # PAGE 8
    #
    page += 1
    # load page header and define title
    linel, tp = pagedesign(' ', page)    

    # Page content
    # Front text    
    pdf.setFont('abc_b', ts1)
    text = 'Evaluation box 4: Consistency check of measured and calculated SPR values'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-25)
    t.textLines(text_wrapped)
    pdf.drawText(t)    

    if sprtype == 'SPR Measured':
        file = 'Results/for_report/Eval_box_4_spr_estimation.txt'
        pdf.setFont('abc', ts1)
        text = 'Comparison of measured and calculated stopping power ratio values for the phantom inserts.'
        text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
        t = pdf.beginText(linel, tp-50)
        t.textLines(text_wrapped)
        pdf.drawText(t)
        
        # Print Diff table
        eval_spr = np.genfromtxt(file, dtype=str, delimiter='    ')
        eval_spr_list = eval_spr.tolist()
    
        grid = [('FONTNAME', (0, 0), (-1, 0), 'Times-Bold'),  # makes the first row bold
                ('ALIGN', (1, 0), (-1, -1), 'CENTRE')]  # makes both columns aligned centrally
        
        t_spr = Table(eval_spr_list, style=TableStyle(grid), rowHeights=13)
        x, y = 0.16*w, tp - 90 - len(hlut_head)*14 
        width, height = 400, 100
        t_spr.wrapOn(pdf, width, height)
        t_spr.drawOn(pdf, x, y)        

        # Print image (SPR difference)
        drawing = svg2rlg("Results/for_report/svg/Eval_box_4_spr_estimation.svg")
        drawing = scale(drawing, 0.60)
        renderPDF.draw(drawing, pdf, 35, 200)    

    else:
        pdf.setFont('abc', ts1)
        pdf.drawString(0.1*w, tp-50, 'No measured SPR values provided. The evaluation is therefore skipped.')

    pdf.showPage()
    print('Page {} done'.format(page + 1))

    #
    # PAGE 9
    #
    page += 1
    # load page header and define title
    linel, tp = pagedesign(' ', page)    

    # Page content
    # Front text    
    pdf.setFont('abc_b', ts1)
    text = 'Evaluation box 5: Assessment of body-region specific HLUTs'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-25)
    t.textLines(text_wrapped)
    pdf.drawText(t) 

    pdf.setFont('abc', ts1)

    pdf.drawString(0.1*w, tp-50, 'Comparison of head & body HLUTs with HLUT generated from averaged CT numbers.')

    # Print image (HLUT comparison)
    drawing = svg2rlg("Results/for_report/svg/Eval_box_5_hlut_comp.svg")
    drawing = scale(drawing, 0.60)
    renderPDF.draw(drawing, pdf, 40, 100)       

    pdf.showPage()
    print('Page {} done'.format(page + 1))

    #
    # PAGE 10
    #
    page += 1
    # load page header and define title
    linel, tp = pagedesign(' ', page)    

    # Page content
    # Front text    
    pdf.setFont('abc_b', ts1)
    text = 'End-to-end testing: Evaluation of the generated HLUT'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-25)
    t.textLines(text_wrapped)
    pdf.drawText(t) 

    pdf.setFont('abc_b', ts1)
    pdf.drawString(0.1*w, tp-50, 'Evaluation of the HLUT fitting accuracy (fit vs individual datapoints)')

    pdf.setFont('abc', ts1)
    text = '{} {}'.format('Difference of reference values to those predicted using the HLUTs generated with',
                          'the head, body and averaged CT numbers.')
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-75)
    t.textLines(text_wrapped)
    pdf.drawText(t) 

    # Print image (HLUT comparison)
    drawing = svg2rlg("Results/for_report/svg/Eval_endtoend_HLUT_accuracy.svg")
    drawing = scale(drawing, 0.60)
    renderPDF.draw(drawing, pdf, 30, 475) 

    pdf.setFont('abc', ts1)
    text = 'HLUT accuracy for head and body with respective HLUT:'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-325)
    t.textLines(text_wrapped)
    pdf.drawText(t) 

    # Print first table
    table1 = np.genfromtxt('Results/for_report/eval_box_5_accuracy_head.txt', dtype=str, delimiter='    ')
    table1_list = table1.tolist()

    pdf.setFont('abc_b', ts1)
    pdf.drawString(0.15*w, tp-350, 'Head phantom:')
    pdf.setFont('abc', ts1)
    
    t1 = Table(table1_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 360 - len(table1)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)

    # Print second table
    table1 = np.genfromtxt('Results/for_report/eval_box_5_accuracy_body.txt', dtype=str, delimiter='    ')
    table1_list = table1.tolist()

    pdf.setFont('abc_b', ts1)
    pdf.drawString(0.15*w, tp-450, 'Body phantom:')
    pdf.setFont('abc', ts1)
    
    t1 = Table(table1_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 460 - len(table1)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)

    pdf.showPage()
    print('Page {} done'.format(page + 1))

    #
    # PAGE 11
    #
    page += 1
    # load page header and define title
    linel, tp = pagedesign(' ', page)    

    # Page content
    # Front text    
    pdf.setFont('abc_b', ts1)
    text = 'Influence of insert location on CT number for bone phantom inserts:'
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-25)
    t.textLines(text_wrapped)
    pdf.drawText(t) 

    pdf.setFont('abc', ts1)
    text = '{} {}'.format('CT numbers measured in the middle (CTN middle) vs CT numbers measured in the outer ring',
                          'of the phantom (CTN outer):')
    text_wrapped = "\n".join(wrap(text, 90))  # 90 is line width
    t = pdf.beginText(linel, tp-50)
    t.textLines(text_wrapped)
    pdf.drawText(t) 

    # Print  table
    table1 = np.genfromtxt('Results/for_report/Eval_CTN_positiondependency.txt', dtype=str, delimiter='    ')
    table1_list = table1.tolist()

    t1 = Table(table1_list, style=TableStyle(grid), rowHeights=13)
    x, y = 0.16*w, tp - 75 - len(table1)*14 
    width, height = 400, 100
    t1.wrapOn(pdf, width, height)
    t1.drawOn(pdf, x, y)

    pdf.showPage()
    print('Page {} done'.format(page + 1))
    
    #
    # Save final pdf
    #
    pdf.save()    
