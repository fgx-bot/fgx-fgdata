##
## environment.nas
##
##  Nasal code for implementing environment-specific functionality.

##
# Handler.  Increase visibility by one step
#
var increaseVisibility = func {
	adjustVisibility(1.1);
}

##
# Handler.  Decrease visibility by one step
#
var decreaseVisibility = func {
	adjustVisibility(0.9);
}

var adjustVisibility = func( factor ) {
    var val = visibilityProp.getValue() * factor;
    if( val < 1.0 ) val = getprop("/environment/visibility-m");
    if( val > 30 ) {
        visibilityProp.setDoubleValue(val);
	    visibilityOverrideProp.setBoolValue(1);
        gui.popupTip(sprintf("Visibility: %.0f m", val));
    }
}

##
# Handler.  Reset visibility to default.
#
var resetVisibility = func {
    visibilityProp.setDoubleValue(0);
    visibilityOverrideProp.setBoolValue(0);
}


var visibilityProp = nil;
var visibilityOverrideProp = nil;

_setlistener("/sim/signals/nasal-dir-initialized", func {
	visibilityProp = props.globals.initNode("/environment/config/presets/visibility-m", 0, "DOUBLE" );
	visibilityOverrideProp = props.globals.initNode("/environment/config/presets/visibility-m-override", 0, "BOOL" );
});
