# Model a radar senser pointed forward on the vehicle.  A typical real
# world sensor might have about 450' range with about a 12 degree
# field of view.


var heading_node = props.globals.getNode("/orientation/heading-deg", 1);
var radar_fov = 6.0;     # +/- radar_fov (so 12 degrees total)
var radar_limit = 0.075; # about 450' in nm's
var radar_dist = 1000.0;
var radar_callsign = "";
var radar_callsign_node = props.globals.getNode("/me5286/radar/callsign", 1);
var radar_dist_m_node = props.globals.getNode("/me5286/radar/dist_m", 1);


# initialize variables and values
var radarInit = func {
    # set initial values
    radar_callsign_node.setValue("");
    radar_dist_m_node.setDoubleValue(0.0);
}


var radarUpdate = func {
    var heading = heading_node.getValue();
    radar_dist = 1000.0;
    radar_callsign = "";

    var ai_models_node = props.globals.getNode("/ai/models", 1);
    foreach ( var c; ai_models_node.getChildren("aircraft") ) {
        var radar_node = c.getChild("radar");
        if ( radar_node.getChild("in-range").getValue() ) {
            var offset = radar_node.getChild("h-offset").getValue();
            var range = radar_node.getChild("range-nm").getValue();
            var range_factor = (0.06 - range) * 200;
            if ( range_factor < 0 ) { range_factor = 0; }
            if ( abs(offset) <= radar_fov + range_factor ) {
                if ( range < radar_limit and range < radar_dist ) {
                    radar_dist = range;
                    radar_callsign = c.getChild("callsign").getValue();
                }
            }
        }
    }
    foreach ( var c; ai_models_node.getChildren("multiplayer") ) {
        var radar_node = c.getChild("radar");
        if ( radar_node.getChild("in-range").getValue() ) {
            var offset = radar_node.getChild("h-offset").getValue();
            var range = radar_node.getChild("range-nm").getValue();
            var range_factor = (0.06 - range) * 200;
            if ( range_factor < 0 ) { range_factor = 0; }
            if ( abs(offset) <= radar_fov + range_factor ) {
                if ( range < radar_limit and range < radar_dist ) {
                    radar_dist = range;
                    radar_callsign = c.getChild("callsign").getValue();
                }
            }
        }
    }

    # print( "callsign = ", ,min_callsign, " range = ", min_dist );
    radar_callsign_node.setValue( radar_callsign );
    if ( radar_callsign == "" ) {
        radar_dist_m_node.setDoubleValue( 0.0 );
    } else {
        radar_dist_m_node.setDoubleValue( radar_dist * 6000 * 0.3048 );
    }
}
