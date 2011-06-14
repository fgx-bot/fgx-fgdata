#####################################################################################
#                                                                                   #
#  this script contains utilities for use with Rain                                 #
#                                                                                   #
#####################################################################################

# ================================ Initalize ====================================== 
# Make sure all needed properties are present and accounted 
# for, and that they have sane default values.

view_number_Node = props.globals.getNode("sim/current-view/view-number",1);
view_number_Node.setDoubleValue(0);

view_name_Node = props.globals.getNode("sim/current-view/name",1);

view_internal_Node = props.globals.getNode("sim/current-view/internal",1);
view_internal_Node.setBoolValue(1);

rainingNode = props.globals.getNode("sim/model/rain/raining", 1);
rainingNode.setValue(0);

precipitationenabledNode = props.globals.getNode("sim/rendering/precipitation-aircraft-enable", 1);
precipitationenabledNode.setBoolValue(0);

precipitationcontrolNode = props.globals.getNode("sim/rendering/precipitation-gui-enable", 1);
precipitationcontrolNode.setBoolValue(0);

flow = nil;

var time = 0;
var dt = 0;
var last_time = 0.0;
var raining = 0;

initialize = func {

	print("Initializing Rain utilities ...");
	flow = Flow.new();
#	var lp = aircraft.lowpass.new(5);

	#set listeners

	setlistener("sim/rendering/precipitation-gui-enable", func (n){
		var enabled = n.getValue();
		var rain = getprop("environment/metar/rain-norm");
		var internal = view_internal_Node.getValue();
		print("rain gui ", rain, " gui enabled ", enabled );
		if(enabled and internal){
			rainingNode.setValue(rain);
			precipitationenabledNode.setBoolValue(0);
		} elsif (enabled){
			rainingNode.setValue(rain);
			precipitationenabledNode.setBoolValue(1);
		} else {
			rainingNode.setValue(0);
			precipitationenabledNode.setBoolValue(0);
		}

	},
	1,
	0);

	setlistener("sim/current-view/internal", func (n){
		var internal = n.getValue();
		enabled = precipitationcontrolNode.getValue();
		var rain = getprop("environment/metar/rain-norm");
		print("precipitation-control-gui-internal",enabled, " internal ", internal, " rain ",rain );
		if(internal){
			precipitationenabledNode.setBoolValue(0);
		} elsif(enabled) {
			precipitationenabledNode.setBoolValue(1);
			rainingNode.setValue(rain);
		}

	},
	1,
	0);


	# set it running on the next update cycle
	settimer(update, 0);
	print("running Rain utilities");

} # end func

###
# ==== this is the Main Loop which keeps everything updated ========================
##
var update = func {

	time = getprop("sim/time/elapsed-sec");
	dt = time - last_time;
	last_time = time;

	flow.updateFlow(dt);


	settimer(update, 0); 

}# end main loop func

# ============================== end Main Loop ===============================

# ============================================================================
# Class that specifies raindrop flow rate functions
#

Flow = {
	new : func ()
	{
		var obj = {parents : [Flow] };
		obj.name = "flow";
		obj.ias = props.globals.getNode("velocities/airspeed-kt", 1);
		obj.elapsed_time = props.globals.getNode("sim/time/elapsed-sec", 1);
		obj.flow = props.globals.getNode("sim/model/rain/flow", 1);
		obj.precipation_level = props.globals.getNode("environment/params/precipitation-level-ft", 1);
		obj.altitude = props.globals.getNode("position/altitude-ft", 1);
		obj.rain = props.globals.getNode("environment/metar/rain-norm", 1);
		obj.flow.setDoubleValue(0);
#		print (obj.name, " ", number, " ", obj.old_n1);
		return obj;
	},

	updateFlow: func (dt){
#		print("updating: ", me.name," dt ",dt );
		
		var ias = me.ias.getValue();
		var elapsed_time = me.elapsed_time.getValue();
		var altitude = me.altitude.getValue();
		var precipation_level = me.precipation_level.getValue();
		var rain = me.rain.getValue();
		var enabled = precipitationcontrolNode.getValue();

		if (ias < 15){
			me.flow.setDoubleValue(0);
		} else {
			me.flow.setDoubleValue((elapsed_time * 0.5) + (ias * 1852 * dt/(60*60)));
		}
		
		if (altitude > precipation_level or !enabled){
			rainingNode.setValue(0);
		} else {
			rainingNode.setValue(rain);
		}
#		print("updating: ", me.name," dt ",dt, " flow ", me.flow.getValue() );
		return ias;

	 }, # end function

	 }; #

# =============================== end rain stuff ================================

# Fire it up

setlistener("sim/signals/fdm-initialized", initialize);

# end 
