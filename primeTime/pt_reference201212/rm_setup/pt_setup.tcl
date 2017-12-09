

### pt_setup.tcl file              ###




puts "RM-Info: Running script [info script]\n"
### Start of PrimeTime Runtime Variables ###

##########################################################################################
# PrimeTime Variables PrimeTime RM script
# Script: pt_setup.tcl
# Version: E-2010.12 (January 10, 2011)
# Copyright (C) 2008-2011 Synopsys All rights reserved.
##########################################################################################


######################################
# Report and Results directories
######################################


if {[info exists SEV(rpt_dir)]} {
  set REPORTS_DIR $SEV(rpt_dir)
} else {
  # Alternative null location is used only when directly running pt_setup.tcl for analysis
  set REPORTS_DIR "../rpts/null"
}
if {[info exists SEV(dst_dir)]} {
  set RESULTS_DIR $SEV(dst_dir)
} else {
  # Alternative null location is used only when directly running pt_setup.tcl for analysis
  set RESULTS_DIR "../work/null"
}

######################################
# Library & Design Setup
######################################


### Mode : PTVX, DMSA_MODE

set search_path ". $ADDITIONAL_SEARCH_PATH $search_path"

# Provide list of  Verilog netlist file. It can be compressed ---example "A.v B.v C.v"
set NETLIST_FILES               ""

# DESIGN_NAME will be checked for existence from common_setup.tcl
if {[string length $DESIGN_NAME] > 0} {
} else {
set DESIGN_NAME                   ""  ;#  The name of the top-level design
}






######################################
# DMSA File Section
######################################


set dmsa_corners      "";

## This is the PTVX Mode with DMSA_MODE

### Mode : PTVX, DMSA_MODE, MV_MODE


###
###
### This section is unified PT VX scaling library section
###
###


## Nominal Libraries
set ptvx_nominal_libraries(corner) ""

## Unified Libraries
set ptvx_unified_libraries(corner) ""

set ptvx_mv_voltage(corner)     "_1.09"
set ptvx_mv_process(corner)     "1"
set ptvx_mv_temperature(corner) "125"

###
###
### This section is correlation definition, parameter definition, and parameter mapping
###
###

### Correlations Types and the Corresponding Names

## This is a list of correlation types that are used during the PTVX run
## 0 (random), 1 (global), 0<x>1 (partial)
set correlation_types_used(corner)  ""

## Names for correlation type used - 0 : corr0, 1 : corr1, 0<x>1 pcorr
set correlation_types_names(corner)  ""


### Parameter Names and the Mapping to the Correlation Type

## This is a list of parameter names - par1  par2  par3 ...
set ptvx_parameter_names(corner)              ""


# Provide an array of parameters distribution types, mean_value, sigma value
#
# The syntax will be ptvx_parameter_distribution_definition(corner) "parameter distribution mean std_dev correlation_name

# set ptvx_parameter_distribution_definition(corner) "par1 normal 0 0.333 d2d par2 normal 0 0.333 d2d";

set ptvx_parameter_distribution_definition(corner) "";


# Provide UPF File
#
# The syntax will be:
#		1. dmsa_UPF_FILE

set dmsa_UPF_FILE                ""     ; # UPF File



# Provide a list of DMSA modes   : functional, test
#
# The syntax will be:
#		1.  set dmsa_modes "mode1 mode2 ..."

set dmsa_modes      "";

#
# Provide an array DMSA Modes Constraint File
#
# The syntax will be dmsa_mode_constraint_files(mode)
#		1. dmsa_mode_constraint_files(mode1)
#		2. dmsa_mode_constraint_files(mode2)
#

set dmsa_mode_constraint_files(mode1) "";
set dmsa_mode_constraint_files(mode2) "";


#
# Corner Based Back Annotation Section
#
# The syntax will be:
#		1. PARASITIC_FILES(corner1)
#		2. PARASITIC_PATHS(corner1)
#

#The path (instance name) and name of the parasitic file --- example "top.spef A.spef" 
#Each PARASITIC_PATH entry corresponds to the related PARASITIC_FILE for the specific block"   
#For a single toplevel PARASITIC file please use the toplevel design name in PARASITIC_PATHS variable."   
set PARASITIC_PATHS(corner1)	 "" 
set PARASITIC_FILES(corner1)	 "" 


#
# Provide Mode/Corner Specific Derates
#
# The syntax is
#		1. set dmsa_derate_clock_early_value(mode_corner) "_1.09"
#		2. set dmsa_derate_clock_late_value(mode_corner) "_1.09"
#		3. set dmsa_derate_data_early_value(mode_corner) "_1.09"
#		4. set dmsa_derate_data_late_value(mode_corner) "_1.09"
set dmsa_derate_clock_early_value(mode_corner) "_1.09"
set dmsa_derate_clock_late_value(mode_corner) "_1.09"
set dmsa_derate_data_early_value(mode_corner) "_1.09"
set dmsa_derate_data_late_value(mode_corner) "_1.09"

# Set the number of hosts and licenses to number of dmsa_corners * number of dmsa_modes
set dmsa_num_of_hosts [expr [llength $dmsa_corners] * [llength $dmsa_modes]]
set dmsa_num_of_licenses [expr [llength $dmsa_corners] * [llength $dmsa_modes]]





######################################
# DSTA Setup
######################################
##Information: PrimeTime Multicore currently is not supported in the DMSA Flow.

######################################
# Fix ECO DRC Setup
######################################
# specify a list of allowable buffers to use for fixing drc
# eg set eco_drc_buf_list "BUF4 BUF8 BUF12"
set eco_drc_buf_list ""

######################################
# Fix ECO Timing Setup
######################################
# specify a list of allowable buffers to use for fixing hold
# eg. set eco_hold_buf_list "DELBUF1 DELBUF2 DELBUF4"
set eco_hold_buf_list ""

######################################
# End
######################################

### End of PrimeTime Runtime Variables ###
puts "RM-Info: Completed script [info script]\n"
