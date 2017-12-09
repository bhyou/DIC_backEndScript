
#################################################################################
# PrimeTime Reference Methodology Script
# Script: pt.tcl
# Version: E-2010.12-SP2 (March 28, 2011)
# Copyright (C) 2009-2011 Synopsys All rights reserved.
#################################################################################

# Please do not modify the sdir variable.
# Doing so may cause script to fail.
set sdir "../../scripts_block" 

##################################################################
#    Source common and pt_setup.tcl File                         #
##################################################################
source $sdir/rm_setup/common_setup.tcl
source $sdir/rm_setup/pt_setup.tcl


# make REPORTS_DIR
file mkdir $REPORTS_DIR

# make RESULTS_DIR
file mkdir $RESULTS_DIR


##Information: PrimeTime Distributed Multicore currently is not supported in the PTVX with DMSA Flow.


##Information: PrimeTime PX Power Analysis currently is not supported in the PTVX with DMSA Flow.


##Information: Link To TetraMAX currently is not supported in the PTVX with DMSA Flow.


##Information: AOCVM (Advanced On-Chip Variation) is not supported in the PTVX default Flow.

# set the working directory and error files (delete the old work directory first)
file delete -force ./work
set multi_scenario_working_directory ./work
set multi_scenario_merged_error_log ./work/error_log.txt

# add search path for design scripts (scenarios will
# inherit the master's search_path)
set search_path "$search_path $sh_launch_dir $sh_launch_dir/$sdir/rm_pt_scripts"


# add slave workstation information
#
# NOTE: change this to your desired machine/add more machines!

# run processes on the local machine
set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4

# run processes on machine lm121
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 lm121

# run SSH processes on machine lm121 (per SolvNet article 023519)
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 \
   -submit_command "/usr/bin/ssh" lm121

# run processes using lsf (LSF compute farm)
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 \
  -submit_command "bsub -n 2" \
  -terminate_command "/lsf/bin/bkill"

# run processes using grd (Sun Grid compute farm)
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 \
  -submit_command "qsub -b y -P bnormal" \
  -terminate_command "/grd/bin/qdel"

# set license resource usage
#
# if this is less than the processor count, licenses will be
# dynamically moved around to maximize their usage
#
# this license count is only the ceiling;  licenses will only
# be pulled from the license server as they are needed
set_multi_scenario_license_limit -feature PrimeTime $dmsa_num_of_licenses
set_multi_scenario_license_limit -feature PrimeTime-SI $dmsa_num_of_licenses
set_multi_scenario_license_limit -feature PrimeTime-VX $dmsa_num_of_licenses



# create scenario at every corner, for every mode
#
# note that link command must be executed after library definitions
# in the common_data scripts before any constraints are applied!
#
# the search_path is used below to resolve the script location
foreach corner $dmsa_corners {
 foreach mode $dmsa_modes {
  create_scenario \
   -name ${mode}_${corner} \
   -specific_variables {mode corner } \
   -specific_data "$sdir/rm_setup/common_setup.tcl $sdir/rm_setup/pt_setup.tcl $sdir/rm_pt_scripts/ptvx_dmsa_comb_mc.tcl"
 }
}


# start processes on all remote machines
#
# if this hangs, check to make sure that you can run this version
# of PrimeTime on the specified machines/farm
start_hosts

# set session focus to all scenarios
current_session -all

# Produce report for all scenarios
source $sdir/rm_pt_scripts/ptvx_dmsa_comb_analysis.tcl


sproc_script_stop 

