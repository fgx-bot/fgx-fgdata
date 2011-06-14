# Properties under /consumables/fuel/tank[n]:
# + level-lbs       - Current fuel load.  Can be set by user code.
# + selected        - boolean indicating tank selection.
# + capacity-gal_us - Tank capacity
#
# Properties under /engines/engine[n]:
# + fuel-consumed-lbs - Output from the FDM, zeroed by this script
# + out-of-fuel       - boolean, set by this code.


var UPDATE_PERIOD = 0.3;


var update = func {
	if (fuel_freeze)
		return;

	var consumed_fuel = 0;
	foreach (var e; engines) {
		var fuel = e.getNode("fuel-consumed-lbs");
		consumed_fuel += fuel.getValue();
		fuel.setDoubleValue(0);
	}

	if (!consumed_fuel)
		return;

	var selected_tanks = [];
	foreach (var t; tanks) {
		var cap = t.getNode("capacity-gal_us",0).getValue();
		if (cap > 0.01 and t.getNode("selected").getBoolValue())
			append(selected_tanks, t);
	}

	# Subtract fuel from tanks, set auxilliary properties.  Set out-of-fuel
	# when any one tank is dry.
	var out_of_fuel = 0;
	if (size(selected_tanks) == 0) {
		out_of_fuel = 1;
	} else {
		var fuel_per_tank = consumed_fuel / size(selected_tanks);
		foreach (var t; selected_tanks) {
			var lbs = t.getNode("level-lbs").getValue();
			lbs = lbs - fuel_per_tank;
			t.getNode("level-lbs").setDoubleValue(lbs);
			if( t.getNode("empty").getBoolValue() ) {
				# Kill the engines if we're told to, otherwise simply
				# deselect the tank.
				if (t.getNode("kill-when-empty", 1).getBoolValue())
					out_of_fuel = 1;
				else
					t.getNode("selected").setBoolValue(0);
			}
		}
	}

	foreach (var e; engines)
		e.getNode("out-of-fuel").setBoolValue(out_of_fuel);
}


var loop = func {
	update();
	settimer(loop, UPDATE_PERIOD);
}

var tanks = [];
var engines = [];
var fuel_freeze = nil;

_setlistener("/sim/signals/fdm-initialized", func {
	setlistener("/sim/freeze/fuel", func(n) { fuel_freeze = n.getBoolValue() }, 1);

	engines = props.globals.getNode("engines", 1).getChildren("engine");
	foreach (var e; engines) {
		e.getNode("fuel-consumed-lbs", 1).setDoubleValue(0);
		e.getNode("out-of-fuel", 1).setBoolValue(0);
	}

	foreach (var t; props.globals.getNode("/consumables/fuel", 1).getChildren("tank")) {
		if (!t.getAttribute("children"))
			continue;           # skip native_fdm.cxx generated zombie tanks

		append(tanks, t);
		t.initNode("selected", 1, "BOOL");
	}

	loop();
});


