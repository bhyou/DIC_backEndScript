#set_app_var verification_set_underiven_signals synthesis
#Uncomment the next line to revert back to the more conservative default seting:

set_app_var verification_set_underiven_signals BINARY:X
#set_app_var verification_set_underiven_signals synthesis



#############################################################################
#  setup for simulation/synthesis mismatch messaging
#############################################################################

set_app_var hdlin_error_on_mismatch_message false
set_app_var hdlin_warn_on_mismatch_message FMR_ELAB-147



#############################################################################
#  Setup for Clock-gating
#############################################################################

#the synopsys auto setup mode, along with the SVF file, will appropriately set the clock-gating variable.
# otherwise, the user will need to notify Formality of clock-gating by uncommenting the next line:

set_app_var verification_clock_gate_hold_mode low

###############################################################################
#    setup for verification mode
###############################################################################

set_app_var verification_passing_mode  consistency

################################################################################
#   setup for instantiated DesignWare or function-inferred DesignWare components
################################################################################

#set this variable ONLY if you design contains instantiated DW or function-inferred DW.

#Use this variable to let Formality know the location of the Synopsys tree that contains the DesignWare components   \
into the tool

#

#################################################################################
#  set the timeout limit
#################################################################################
set verification_timeout_limit 36:00:00

#################################################################################
#  set the non-eq limit
#################################################################################
set verification_falling_point_limit 1000

#################################################################################
#  Read in the SVF file
#################################################################################
#
#Set this variable to point to individual SVF files or  to a directory containing SVF files. 
#

set index 0
foreach svfFile [split ../syn/data/DCSyn.svf :] {
	if [file exists $svfFile] {
		if { $index ==0 } {
			set_svf $svfFile
			set index 1
		} else {
			set_svf -append $svfFile
		}
	} else {
		echo "Svf file : $svfFile is missing please make sure that DC generate this file"
	}
}

set_svf ../syn/data/DCSyn.svf
report_guidance -summary

######################################################################################
#  Read in the libraries
######################################################################################

# set library_interface_only "hdcdc cdceninxss cdcbfxss"

source ../../script/formal/tune/STARGET_NAME.before.readlib.tcl


read_db -technology_library [list \



]


###########################################################################################
#  Read in the reference design as verilog /vhdl source  code
############################################################################################
source ../../script/formal/tune/STARGET_NAME.before.readdesign.tcl

read_verilog -r -f ../../../design/soc_rtl.lst -05 -define {DCSYN} -work_library FMWORK_REF_soc_top_pad

set_top r:/FMWORK_REF_soc_top_pad/soc_top_pad
write_container -r data/ref_soc_top_pad
#read_container -r data/ref_soc_top_pad.fsc
##############################################################################################
#Read in the Implementation Design from DC_RM result
#
#chose the format that is used in your flow
##############################################################################################



#For verilog
read_verilog -i -netlist ../syn/data_6_21/DCSyn.compile.pass2.gv -work_library FMWORK_REF_soc_top_pad
set_top i:/FMWORK_REF_soc_top_pad/soc_top_pad

write_container -i data/ref_soc_top_pad

report_libraries -default all > rpt/lib_RPTS_DEF.rpt
report_libraries > lib_RPTS.rpt

###############################################################################################
#  report any blak boxes in the reference and the implementation
###############################################################################################
report_black_boxes > bbox.rpt

################################################################################################
#  report any loops in the reference and the implementation
################################################################################################
report_loops -ref -unfold
report_loops -impl -unfold

#################################################################################################
# Configure constant port
#
# When using the Synopsys Auto Setup mode, the SVF file will convey information
# automatically to Formality about how to disable scan.
#
# otherwise, manually define chose ports whose inputs should be assumed constant
# during verification.
#
# Example command format:
#      set_constant -type port i:work/${DESIGN_NAME}/<port_name> <constant_value>
##################################################################################################
############################################################################################################
#   Report design statistics, design read warning message,and user specified setup.
############################################################################################################

#report_setup_status will create a report showing all design statistics,
# design read warning message, and all user specified setup. this will allow
# the user to check all setup before proceeding to run the more time consuming
# command "match" and "verify".

#report_setup_status

################################################################################################################
#  match compare points and report unmatched points
################################################################################################################
source ../../../script/formal/tune/STARGET_NAME_before.match.tcl

match 

###########################################################################################
# Verify and report 
#
# if the verification is most successful, the session will be saved and reports
# will be generated to help debug the failed or inconclusive verification.
############################################################################################
report_matched_points > rpt/MatchED_POINTS.rpt
report_unmatched_points > rpt/UNMATCHED_POINTS.rpt
report_undriven_nets > rpt/UNDRIVED_NET.rpt

report_svf_operation -c reg_merging  -status rejected > rpt/REG_MERGING.rpt
report_svf_operation -c reg_constant -status rejected > rpt/REG_CONSTANT.rpt
report_svf_operation -c inv_push     -status rejected > rpt/INV_PUSH.rpt
report_svf_operation -c datapath     -status rejected > rpt/datapath.rpt
report_svf_operation -c multiplier   -status rejected > rpt/multiplier.rpt
report_svf_operation -c merge        -status rejected > rpt/merge.rpt
report_svf_operation -c replace      -status rejected > rpt/replace.rpt
report_svf_operation -c change_name  -status rejected > rpt/change_name.rpt

source ../../script/formal/tune/STARGET_NAME.before.verify.tcl
if { ![verify] } {
	echo "Error: Formality run FmEqvSynthesizeVsSynRtl Failed: Have Fun time to debug :) \n"
	save_session -replace dara/FmEqvSynthesizeVsSynRtl_failed
	report_matched_points > rpt/MatchED_POINTS.rpt
	report_falling_points >
	report_aborted >
	report_unverified_points >
	report_status 
	
	# Use analyze_points to help determine the next step in resolving verification
	# issues, it runs heuristic analysis to determine if there are potential causes
	# other than logical differences for falling or hard verification points.
	analyze_points -all > rpts/ANALYZE_POINTS.rpt
	set exitVal 1
} else {
	echo "Info: Life is good Formality run FmEqvSynthesizeVsSynRtl Passed, Time to celebrate an enjoy :) \n"
	echo "Info: The run pass: please make sure to review the black box list \n"
	echo "Info: THe run pass: please make sure ro review your Formality constants \n"
	report_status > rpt/FmEqvSynthesizeVsSynRtl.rpt
	set_exitVal 0
}

# generate equivalence file
report_equivalences > rpt/FmEqvSynthesizeVsSynRtl/equivalence_soc_top_pad_fm.out

# generate multi-driven nets report
report_multidriven_nets > rpt/FmEqvSynthesizeVsSynRtl/FmEqvSynthesizeVsSynRtl_MULTIDRIVEN_NETS.rpt


