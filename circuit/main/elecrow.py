#!/usr/bin/env python
#
# kicadPcb2switchSciencePcb.py
#
# Author:   Hiromasa Ihara (miettal)
# Created:  2015-12-02
#

import os
import shutil
import zipfile

from pcbnew import *

layers = {
  "GTL":F_Cu,
  "GBL":B_Cu,
  "GTO":F_SilkS,
  "GBO":B_SilkS,
  "GTS":F_Mask,
  "GBS":B_Mask,
  "GML":Edge_Cuts,
}

def convert() :
  board = GetBoard()
  plot_controller = PLOT_CONTROLLER(board)
  plot_options = plot_controller.GetPlotOptions()
  excellon_writer = EXCELLON_WRITER(board)
  
  board_basename = os.path.basename(board.GetFileName()).split('.')[0]
  pcb_dirname = "{}_elecrow".format(board_basename)
  print "board_basename:", board_basename
  print "pcb_dirname:", pcb_dirname
  
  #GERBER OUTPUT
  # Options
  plot_options.SetFormat(PLOT_FORMAT_GERBER)
  plot_options.SetOutputDirectory(pcb_dirname)
  plot_options.SetPlotFrameRef(False)
  plot_options.SetPlotPadsOnSilkLayer(False)
  plot_options.SetPlotValue(True)
  plot_options.SetPlotReference(True)
  plot_options.SetPlotInvisibleText(False)
  plot_options.SetPlotViaOnMaskLayer(False)
  plot_options.SetExcludeEdgeLayer(True)
  plot_options.SetUseAuxOrigin(False)
  plot_options.SetLineWidth(FromMM(0.1))
  plot_options.SetUseGerberProtelExtensions(False)
  plot_options.SetUseGerberAttributes(False)
  plot_options.SetSubtractMaskFromSilk(False)
  # Export, Rename
  for (ext, sym) in layers.items() :
    plot_controller.OpenPlotfile("", PLOT_FORMAT_GERBER, "")
    plot_controller.SetLayer(sym)
    plot_controller.PlotLayer()
  
    pcb_dirpath = plot_controller.GetPlotDirName()
    gerber_raw_filepath = plot_controller.GetPlotFileName()
    gerber_filepath = os.path.join(pcb_dirpath, "{}.{}".format(board_basename, ext))
    print "gerber_filepath:", gerber_filepath
    shutil.move(gerber_raw_filepath, gerber_filepath)
  plot_controller.ClosePlot()
  
  #DRILL OUTPUT
  # Options
  excellon_writer.SetFormat(True, EXCELLON_WRITER.SUPPRESS_TRAILING, 3, 3)
  excellon_writer.SetOptions(False, False, wxPoint(0, 0), False)
  excellon_writer.CreateDrillandMapFilesSet(pcb_dirpath, True, False)
  # Export, Rename
  drill_raw_filepath = os.path.join(pcb_dirpath, "{}.drl".format(board_basename))
  drill_filepath = os.path.join(pcb_dirpath, "{}.TXT".format(board_basename))
  print "drill_filepath:", drill_filepath
  shutil.move(drill_raw_filepath, drill_filepath)
  
  #Build ZIP
  pcb_zipfilepath = "{}.zip".format(board_basename)
  print "pcb_zipfilepath:", pcb_zipfilepath
  with zipfile.ZipFile(pcb_zipfilepath, 'w') as zip_f :
    #GERBER
    for (ext, sym) in layers.items() :
      gerber_filepath = os.path.join(pcb_dirpath, "{}.{}".format(board_basename, ext))
      gerber_filename = os.path.join(pcb_dirname, "{}.{}".format(board_basename, ext))
      zip_f.write(gerber_filepath, gerber_filename)
  
    #DRILL
    drill_filepath = os.path.join(pcb_dirpath, "{}.TXT".format(board_basename))
    drill_filename = os.path.join(pcb_dirname, "{}.TXT".format(board_basename))
    zip_f.write(drill_filepath, drill_filename)
  
  print "success"
