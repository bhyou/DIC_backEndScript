puts "RM-Info: Running script [info script]\n"

#################################################################################
# PrimeTime Reference Methodology Script
# Script: ptvx_dmsa_comb_mc.tcl
# Version: E-2010.12-SP2 (March 28, 2011)
# Copyright (C) 2009-2011 Synopsys All rights reserved.
#################################################################################

# make REPORTS_DIR
file mkdir $REPORTS_DIR

# make RESULTS_DIR
file mkdir $RESULTS_DIR


set variation_enable_analysis true 
set si_enable_analysis true 
set sh_source_uses_search_path true 
set si_xtalk_double_switching_mode clock_network 

# Under normal circumstances, when executing a script with source, Tcl
# errors (syntax and semantic) cause the execution of the script to terminate.
# Uncomment the following line to set sh_continue_on_error to true to allow
# processing to continue when errors occur.
#set sh_continue_on_error true

set timing_report_use_worst_parallel_cell_arc true 
set pba_exhaustive_endpoint_path_limit 100         
set timing_remove_clock_reconvergence_pessimism true 
set sh_source_uses_search_path true
set report_default_significant_digits 3



echo "Checking $ptvx_unified_libraries($corner)"

set link_path "* $ptvx_unified_libraries($corner) $link_path"

read_verilog $NETLIST_FILES

current_design $DESIGN_NAME
link

define_scaling_lib_group "$ptvx_unified_libraries($corner) $ptvx_nominal_libraries($corner) "

set plibs [get_libs *]

foreach_in_collection pp $plibs {
 set ename [get_attribute $pp extended_name]
 if { [regexp $ptvx_unified_libraries($corner) $ename ] == 1 } {
    set libstring $ename
 }
}


create_operating_conditions -name ptvx_$ptvx_mv_voltage($corner)_oc -library $libstring -process $ptvx_mv_process($corner) -temperature $ptvx_mv_temperature($corner) -volt $ptvx_mv_voltage($corner)

set_operating_conditions ptvx_$ptvx_mv_voltage($corner)_oc




##################################################################
#    Define Create Variation                                     #
##################################################################


if [info exists ptvx_parameter_distribution_definition($corner)] {

foreach {parameter dist mean_value sigma_value corr_name} $ptvx_parameter_distribution_definition($corner) {

echo "Setting Parameter Variation : $parameter : Distribution Type $dist : Min Value $mean_value : Sigma Value $sigma_value : Correlation Name $corr_name"

set_variation [create_variation -name $parameter -parameter_name $parameter -type $dist -values "[expr {$mean_value}] [expr {$sigma_value}] " ]

}
}



##################################################################
#    Define Set Correlations                                     #
##################################################################

# set correlation


foreach ctype_name $correlation_types_names($corner) ctype $correlation_types_used($corner) {
create_correlation -name $ctype_name -constant $ctype
}


set index 0

if [info exists ptvx_parameter_distribution_definition($corner)] {

foreach {parameter dist mean_value sigma_value corr_name} $ptvx_parameter_distribution_definition($corner) {

incr index
set_variation_correlation -name var_${corr_name}_${index} -correlation $corr_name [get_variations $parameter]

}
}


##################################################################
#    UPF Section                                                 #
##################################################################


load_upf $dmsa_UPF_FILE




##################################################################
#    Back Annotation Section                                     #
##################################################################

if { [info exists PARASITIC_PATHS] && [info exists PARASITIC_FILES] } {
foreach para_path $PARASITIC_PATHS($corner) para_file $PARASITIC_FILES($corner) {
   if {[string compare $para_path $DESIGN_NAME] == 0} {
      read_parasitics -increment -keep_variations -keep_capacitive_coupling -format spef $para_file
   } else {
      read_parasitics -path $para_path -keep_variations -keep_capacitive_coupling -format spef $para_file
   }
}
report_annotated_parasitics -check > $REPORTS_DIR/${DESIGN_NAME}_report_annotated_parasitics.report
}



######################################
# reading design constraints
######################################

if {[info exists dmsa_mode_constraint_files($mode)]} {
        foreach dmcf $dmsa_mode_constraint_files($mode) {
                if {[file extension $dmcf] eq ".sdc"} {
                        read_sdc -echo $dmcf
                } else {
                        source -echo $dmcf
                }
        }
}



##################################################################
#    DMSA Derate Section - Based on Mode and Corner		 #
##################################################################

## Assign Correct Value from pt_setup.tcl file for the current mode and corner.

        if {[info exists dmsa_derate_clock_early_value(${mode}_${corner})]} {
                echo "clock early: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_clock_early_value(${mode}_${corner})"
                set_timing_derate $dmsa_derate_clock_early_value(${mode}_${corner}) -clock -early
        }
        if {[info exists dmsa_derate_clock_late_value(${mode}_${corner})]} {
                echo "clock late: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_clock_late_value(${mode}_${corner})"
                set_timing_derate $dmsa_derate_clock_late_value(${mode}_${corner}) -clock -late
        }
        if {[info exists dmsa_derate_data_early_value(${mode}_${corner})]} {
                echo "data early: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_data_early_value(${mode}_${corner})"
                set_timing_derate $dmsa_derate_data_early_value(${mode}_${corner}) -data -early
        }
        if {[info exists dmsa_derate_data_late_value(${mode}_${corner})]} {
                echo "data late: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_data_late_value(${mode}_${corner})"
                set_timing_derate $dmsa_derate_data_late_value(${mode}_${corner}) -data -late
        }


##################################################################
#    Clock Tree Synthesis Section                                #
##################################################################

set_propagated_clock [all_clocks] 

puts "RM-Info: Running script [info script]\n"
