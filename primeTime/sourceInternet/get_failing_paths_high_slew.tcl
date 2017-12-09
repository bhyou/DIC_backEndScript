#============================================================
# Gets the threshold node information that violates the path conversion time 
#============================================================
proc get_failing_paths_high_slew {Nworst_numb Path_type Tran_threshould}{
	set Nworst_numb $Nworst_numb;   # Violates the number of paths
	set Path_type $Path_type;       # analyze the type of violation path,such as hold-time or setup-time
	set Tran_threshould $Tran_threshould; #threshold that violates the path conversion time
	
	foreach_in_collection path [get_timing_paths -delay_type $Path_type -nworst $Nworst_numb]{
		foreach_in_collection itr $path { 
			set cnt 0;
			set Slack [get_attribute $itr slack]
			set StartPoint [get_object_name [get_attribute $itr startpoint]]
			set EndPoint [get_object_name [get_attribute $itr endpoint]]
			if{$slack < 0.0}}{
				if{$cnt == 0}{
					echo "Timing path fails:\t Start Point : $StartPoint \t End Point: $endpoint \t Slack: $slack"
					set $cnt [expr $cnt + 1]
				}
				foreach_in_collection point [get_attribute $path points]{
					set Object [get_attribute $point object]
					set Obj_name [get_object_name [get_attribute $point object]]
					set Obj_r_f [get_attribute $point rise_fall]
					set Slew_att [format "actual_%s_transition_%s" Obj_r_f $Path_type]
					set Slew_val [get_attribute $Object $Slew_att]
					set cell [get_cells -quiet -of_object $Object]
					if{[get_attribute -quiet $Object is_port] == "false"}{
						set Lib_cell [get_lib_cells -of_object $cell]
						set Ref_name [get_attribute $Lib_cell base_name]
					} else {
						set Ref_name $Object
					}
					if{$Slew_val > $Tran_threshould}{
						echo "has a $Obj_r_f slew = $Slew_val on pin $Obj_name \t Reference = $Ref_name"
					}
				}
			}else{
				continue
			}
		}
	}
	unset Slack Obj_name Obj_r_f Slew_att Slew_val Nworst_numb Path_type Tran_threshould
}
#=============================================================
# tihs function is used to get the clock information between cross clocks
#=============================================================
proc get_interclock_skew {args}{
	set results {-delay_type} {max}
	parse_proc_arguments -args $args results
	if {(![info exists results(-from)] || $results(-from) eq {} && (![info exists results(-to)] || $results(-to) eq {})}{
		echo "Error: at least one of -from, -to  must be specified."
		return {}
	}
	regexp {^(...)} $results(-delay_type) mm
	set command "get_timing_paths"
	if {[info exists results(-from)]}{
		append command "-from $results(-from)"
	}
	if {[info exists results(-to)]}{
		append command "-to $results(-to)"
	}
	eval set paths \[$command\]
	
	if {[sizeof_collection $paths] == 0 }{
		echo "No constrained paths"
		return 1
	}
	
	set startpoint_clock_latency [get_attribute $paths startpoint_clock_latency]
	set endpoint_clock_latency [get_attribute $paths endpoint_clock_latency]
	
	set crpr [get_attribute $paths common_path_pessimism]
	if {[$mm == "max"]}{
		set_interclock_skew [expr $startpoint_clock_latency -$endpoint_clock_latency -$crpr]
	} else {
		set_interclock_skew [expr $endpoint_clock_latency -$startpoint_clock_latency +$crpc]
	}
}

define_proc_attributes get_interclock_skew \
	-info "Report interclock skew for max path" \
	-define_args {\
	{-from "From pins or ports" from_list string}
	{-to "To pins or ports" tp_llist string}
	{-delay_type "Type of delay Default= max" type one_of_string {optional value_help {values {min max}}}}
	}

	
proc report_unlocked {args}{
	set procargs(-verbose) false
	parse_proc_arguments -args $args procargs
	set verbose $procaegs(-verbose) 
	set all_clock_pins [all_registers -clock_pins]
	
	if {$::synopsys_program_name == "pt_shell"}{
		set unclocked0 [filter_collection $all_clock_pins "defined(clocks)"]
		set unclocked [remove_from_collection $all_clock_pins $unclocked0]
		set constant {Logic([01])/output}
	} else {
		set unclocked [filter_collection $all_clock_pins is_on_clock_network==false]
		set constant {\*\*logic_([01])\*\*}
	}
	
	arrray unset uc_roots
	set uc_roots(LOGIC_0) {}
	set uc_roots(LOGIC_1) {}
	set c_root ""
	foreach_in_collection uc $unclocked {
		redirect -variable redir {set c_root [get_object_name [all_fanin -flat -startpoint_only -to $uc -trace_arcs all]]}
		
		if {$::synopsys_program_name == "icc_shell"&& $c_root==""}{
			set c_root $redir
			if{[regexp $constant $c_root m s]}{
				set c_root "LOGIC_$s"
			}
		}
		
		lappend uc_roots($c_root) [get_object_name $uc]
	}
	
	echo "List of clock drives and number of unclocked clock pins in their fanout:\n"
	set all_roots [concat [lminus [lsort [array name uc_roots]] {LOGIC_0 LOGIC_1}] {LOGIC_0 LOGIC_1}]
	
	foreach c_root $all_roots {
		echo [format "%-50s %d" $c_root [llength $uc_roots($c_root)]]
		if {$verbose}{
			foreach pin $uc_roots($c_root) {
				echo " $pin"
			}
		}
	}
}

define_proc_attributes report_unlocked \
	-info "Report unclocked registers" \
	-define_args {
		{-verbose "Before verbose." "" boolen optional}
	}
	
	
proc get_buffer {args}{
	parse_proc_arguments -args ${args} options
	
	if {[info exists(-library)]}{
		set lib_id $options(library)
	} else {
		set lib_id *
	}
	
	if {[info exists options(-pattern)]}{
		set pattern $options(-pattern)
	} else {
		set pattern *
	}
	
	set gen_inv [info exists options(-inverter)]
	set use_arc [info exists options(-use_arc_info)]
	set ver     [info exists options(-verbose)]
	
	if {${gen_inv}}{
		set req_arc negative_unate
		set typ inverter
 	} else {
		set req_arc positive_unate
		set typ buffer
	}
	
	set cell_coll ""
	set libs [get_libs ${lib_id}]
	
	foreach_in_collection lib ${libs}{
		set lcells [filter_collection [get_lib_cells -quiet [get_attr $lib extended_name]/*] "number_of_pins==2  && base_name==~${pattern}"]
		
		foreach_in_collection lcell ${lcells}{
			set opin [get_lib_pins -quiet -of_object ${lcell} -filter "pin_direction==out"]
			set ipin [get_lib_pins -quiet -of_object ${lcell} -filter "pin_direction==in"]
			
			if {[sizeof_coll ${opin}]==1 && [sizeof_collection ${ipin}]==1}{
				set opin_name [get_attribute -quiet ${opin} base_name]
				set ipin_name [get_attribute -quiet ${ipin} base_name]
				set cell_func [get_attribute -quiet ${opin function}]
				
				if {${gen_inv}}{
					set cond1 [string equal "!(${ipin_name})" ${cell_func}]
					set cond2 [string equal " (${ipin_name})'" ${cell_func}]
					set cond3 [string equal " (${opin_name})'" ${cell_func}]
					set cond4 [string equal " !(${opin_name})" ${cell_func}]
					
					if {$cond1 || $cond2 || $cond3 || $cond4}{
						set cell_coll [append_to_collection cell_coll ${lcell}]
						print $ver"Found ${typ} cell\' [get_object_name ${lcell}\' based on function] "
						continue
					}
				} else {
					set cond1 [string equal "(${ipin_name})" ${cell_func}]
					set cond2 [string equal "(${opin_name})" ${cell_func}]
					
					if {$cond1 || $cond2}{
						set cell_coll [append_to_collection cell_coll ${lcell}]
						print $ver"Found ${typ} cell \' [get_object_name ${lcell}]\' base on function..."
						continue
					}
				}
				
				if {${use_arc}}{
					set lib_arcs [get_lib_timing_arcs -quiet -from ${ipin} -to ${opin}];
					
					foreach_in_collection larc ${lib_arcs} {
						set arc_sns [get_attribute -quiet ${larc} sense]
						
						if {![string match ${arc_sns} ${req_arc}]}{
							break;
						} else {
							set cell_coll [append_to_collection cell_coll ${lcell}]
							print $var"Found $typ cell \'[get_object_name ${lcell}]\' base on arc information..."
						}
					}
				}
			}
		}
	}
	return [append_to_collection -unique cell_coll ""]
} 


proc print {ver msg}{
	if {$ver} {echo "$msg"}
}

define_proc_attributes get_buffer \
	-info "create a collection of buffer (or inverter) cells from library"\
	-hide_body \
	-define_arg {\
		{-library     "library from which get to buffer or inverter cells""lib_name" string optional}
		{-pattern     "name pattern for buffer or inverter cells""lib_name" string optional}
		{-inverter    "create a collection of inverter cells instead of buffers""" string optional}
		{-use_arc_info  "look at timing arc information to determine buffer/inverter""" string optional}
		{-verbose       "print detailed information """ boolen optional}
	}




