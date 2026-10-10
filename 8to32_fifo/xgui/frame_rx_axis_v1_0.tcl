# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "FIFO_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FRAME_BYTES" -parent ${Page_0}


}

proc update_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to update FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to validate FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.FRAME_BYTES { PARAM_VALUE.FRAME_BYTES } {
	# Procedure called to update FRAME_BYTES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_BYTES { PARAM_VALUE.FRAME_BYTES } {
	# Procedure called to validate FRAME_BYTES
	return true
}


proc update_MODELPARAM_VALUE.FRAME_BYTES { MODELPARAM_VALUE.FRAME_BYTES PARAM_VALUE.FRAME_BYTES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_BYTES}] ${MODELPARAM_VALUE.FRAME_BYTES}
}

proc update_MODELPARAM_VALUE.FIFO_DEPTH { MODELPARAM_VALUE.FIFO_DEPTH PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_DEPTH}] ${MODELPARAM_VALUE.FIFO_DEPTH}
}

