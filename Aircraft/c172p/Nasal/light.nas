# strobes ===========================================================
var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/c172p/lighting/strobes", [0.015, 1.985], strobe_switch);


# beacons ===========================================================
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/c172p/lighting/beacon-top", [0.10, 0.90], beacon_switch);

# Control both panel and instrument light intensity with one property

var instrumentsNorm = props.globals.getNode("controls/lighting/instruments-norm", 1);
var instrumentLightFactor = props.globals.getNode("sim/model/material/instruments/factor", 1);
var panelLights = props.globals.getNode("controls/lighting/panel-norm", 1);

var update_intensity = func {

    instrumentLightFactor.setDoubleValue(instrumentsNorm.getValue());
    panelLights.setDoubleValue(instrumentsNorm.getValue());

    settimer(update_intensity, 0);
}

# Setup listener call to start update loop once the fdm is initialized
#
setlistener("sim/signals/fdm-initialized", update_intensity);

# Make sure that update_intensity is called when the sim is reset
setlistener("sim/signals/reset", update_intensity);

