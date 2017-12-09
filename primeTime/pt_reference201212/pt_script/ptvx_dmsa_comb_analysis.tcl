puts "RM-Info: Running script [info script]\n"

#################################################################################
# PrimeTime Reference Methodology Script
# Script: ptvx_dmsa_comb_analysis.tcl
# Version: E-2010.12-SP2 (March 28, 2011)
# Copyright (C) 2009-2011 Synopsys All rights reserved.
#################################################################################


#################################################################################
# 
# This file will produce the reports for the DMSA mode based on the options
# used within the GUI.
#
# The output files will reside within the work/scenario subdirectories.
#
#################################################################################


# send some non-merged reports to our slave processes

##################################################################
#    Fix ECO Variable Setup                                      #
##################################################################
remote_execute {
set timing_save_pin_arrival_and_slack true
}

##################################################################
#    Update_timing and check_timing Section                      #
##################################################################

remote_execute {
# Ensure design is properly constrained
update_timing -full
check_timing -verbose > $REPORTS_DIR/${DESIGN_NAME}_check_timing.report
}

##################################################################
#    Save_Session Section                                        #
##################################################################

remote_execute {
save_session ${DESIGN_NAME}_ss
}



##################################################################
#    Report_timing Section                                       #
##################################################################
report_timing -slack_lesser_than 0.0 -pba_mode exhaustive -delay min_max -nosplit -input -net -sign 4 > $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_timing_pba.report
report_analysis_coverage > $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_analysis_coverage.report 
remote_execute {
report_clock -skew -attribute > $REPORTS_DIR/${DESIGN_NAME}_report_clock.report
}

##################################################################
#    Fix ECO DRC Section                                         #
##################################################################
# fix max transition 
fix_eco_drc -type max_transition -method { size_cell insert_buffer } -verbose -buffer_list $eco_drc_buf_list 

##################################################################
#    Fix ECO Timing Section                                      #
##################################################################
# fix setup 
# setup timing eco is not supported in distributed multicore mode 
# fix hold 
fix_eco_timing -type hold -verbose -buffer_list $eco_hold_buf_list -slack_lesser_than 0 -hold_margin 0 -setup_margin 0 

##################################################################
#    Fix ECO Output Section                                      #
##################################################################
# write netlist changes
remote_execute {
write_changes -format icctcl -output $RESULTS_DIR/eco_changes.tcl
}




puts "RM-Info: Completed script [info script]\n"
