###############################################################################
##
## Nasal for controling an MP Carrier Radar
##
##  Copyright (C) 2009  Vivian Meazza
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

var radar=nil;

var init_radar = func {

	radar = RADAR.new();

	print (" ... MP Radar Initialized");

} # end intitialization

var RADAR = {
	new : func(){
		var m = { parents : [RADAR] };

		me.RADAR_target_callsign = props.globals.initNode("instrumentation/radar/target-callsign"," ","STRING");
		me.RADAR_target_id = props.globals.initNode("instrumentation/radar/target-id");
		me.RADAR_target_alt = props.globals.initNode("instrumentation/radar/target-alt",0.0,"DOUBLE");
		me.RADAR_target_range = props.globals.initNode("instrumentation/radar/target-range",0.0,"DOUBLE");
		me.RADAR_target_brg = props.globals.initNode("instrumentation/radar/target-brg",0.0,"DOUBLE");
		me.RADAR_target_speed = props.globals.initNode("instrumentation/radar/target-kt",0.0,"DOUBLE");
		me.RADAR_target_hdg = props.globals.initNode("instrumentation/radar/target-hdg",0.0,"DOUBLE");
		me.RADAR_rangering = props.globals.initNode("instrumentation/radar/compass",1,"BOOL");
		me.RADAR_text = props.globals.initNode("instrumentation/radar/screen-text",1,"BOOL");
		me.RADAR_num =props.globals.initNode("instrumentation/radar/target-number",0."INT");

		me.RADAR_range =props.globals.initNode("instrumentation/radar/range");
		me.RADAR_sel_id =props.globals.initNode("instrumentation/radar/selected-id");
		me.RADAR_rotate =props.globals.initNode("instrumentation/radar/display-controls/rotate",1,"BOOL");
		me.RADAR_background =props.globals.initNode("instrumentation/radar/display-controls/background",1,"BOOL");

		me.mag_offset = 0;
		me.index = 0;
		me.current = nil;

		return me;
	},

	is_valid_target:func(target) {
		return target.getNode("valid").getValue() and target.getNode("radar/in-range").getValue();
	},

	get_target_chat_prefix: func() {
		tgt = me.RADAR_target_callsign.getValue();
		if(tgt != "")
		   val = sprintf("%s: ",tgt);
		else val = "";
		return val;
	},

	step_radar_range:func(dir) {
		var range = me.RADAR_range.getValue();
		range *= dir > 0 ? 2 : 0.5;
		if (range < 1) range = 1;
		if(range>128)range=128;
		me.RADAR_range.setValue(range);
	},

    update_target:func() {

#	    print("updating RADAR ", me.RADAR_num.getValue());

	    if(me.current == nil)
		    return;

	    var number = me.RADAR_num.getValue();

	    if(number <= -1){
		    me.RADAR_target_callsign.setValue("");
		    me.RADAR_target_id.setValue(0);
		    me.RADAR_target_range.setValue(0);
		    me.RADAR_target_brg.setValue(0);
		    me.RADAR_target_speed.setValue(0);
		    me.RADAR_target_hdg.setValue(0);
		    return;
	    }

	    var target_callsign = me.current;

	    foreach (var mp; multiplayer.model.list) {
		    var n = mp.node;
		    var callsign = n.getNode("callsign").getValue();

		    if(callsign == target_callsign){
			    me.RADAR_target_callsign.setValue(callsign);
			    me.RADAR_target_id.setValue(n.getNode("id").getValue());
			    me.RADAR_target_alt.setValue(n.getNode("position/altitude-ft").getValue());
			    me.RADAR_target_range.setValue(n.getNode("radar/range-nm").getValue());
			    me.RADAR_target_brg.setValue(n.getNode("radar/bearing-deg").getValue());
			    me.RADAR_target_speed.setValue(n.getNode("velocities/true-airspeed-kt").getValue());
			    me.RADAR_target_hdg.setValue(n.getNode("orientation/true-heading-deg").getValue());
			    me.RADAR_sel_id.setValue(n.getNode("id").getValue());
		    }

	}

	settimer(func { me.update_target() }, 1);

	},

	step_target:func(step) {
		var mp_list = multiplayer.model.list;

		if (size(mp_list) == 0){
			me.RADAR_num.setValue(-1);
			me.RADAR_sel_id.setValue(-1);
			return;
		}

		var i = me.index;

		i += step;

		if (i > size(mp_list)-1)
			i = -1;
		elsif (i <= -2)
			i = size(mp_list) - 1;

		if( i >= 0 and i < size(mp_list) - 1)
			me.current = mp_list[i].callsign;

		me.RADAR_num.setValue(i);
		me.index = i;

		me.update_target();

		return nil;
	},
};

############################################

setlistener("sim/signals/fdm-initialized", func {
	print("Initializing MP Radar ...");
	init_radar();
});

setlistener("sim/signals/reinit", func(n) {
	n.getBoolValue() and return;
	init_radar();
});


var select_font_callback = func(n) { 
	var font = n.getValue();
	setprop("/instrumentation/radar/font/name", font);
}

var select_RADAR_font = func {
	var font = getprop("/instrumentation/radar/font");
	var dir = getprop("/sim/fg-root") ~ "/Fonts";
	var file = "";
	if (font != nil and size(font) > 0) {
		file = font;
		for(var i = size(font) - 2; i >= 0; i -= 1) {
			if (font[i] == `/`) {
				dir = substr(font, 0, i);
				file = substr(font, i + 1);
				break;
			}
		}
	}
	var selector = gui.FileSelector.new(select_font_callback, "Select RADAR radar font", "Select", nil, dir, file);
	selector.open();
}
