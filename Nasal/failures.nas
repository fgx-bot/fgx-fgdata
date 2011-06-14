# failures.nas a manager for failing systems based on MTBF/MCBF

# Time between MTBF checks
var dt = 10;

# Root property for failure information
var failure_root = "/sim/failure-manager";

# Enumerations
var type = { MTBF : 1, MCBF: 2 };
var fail = { SERVICEABLE : 1, JAM : 2, ENGINE: 3};

# This hash contains a mapping from property entry to a failure object
# containing the following members:
# type: MTBF|MCBF      Mean Time Between Failures/Mean Cycle Between Failures
# desc: <description>  Description of property for screen output
# failure: SERVICEABLE Property has a "serviceable" child that can be set to false
# failure: JAM         Property is failed by marking as Read-Only
# failure: ENGINE      Special case for engines, where a variety of properties are set.
# failure: <prop>      Property is failed by setting another property to false
var breakHash = {
    "/instrumentation/adf"                : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "ADF" },
    "/instrumentation/dme"                : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "DME" },
    "/instrumentation/airspeed-indicator" : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "ASI" },
    "/instrumentation/altimeter"          : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Altimeter" },
    "/instrumentation/attitude-indicator" : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Attitude Indicator" },
    "/instrumentation/heading-indicator"  : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Heading Indicator" },
    "/instrumentation/magnetic-compass"   : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Magnetic Compass" },
    "/instrumentation/nav[0]/gs"          : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Nav 1 Glideslope" },
    "/instrumentation/nav[0]/cdi"         : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Nav 1 CDI" },
    "/instrumentation/nav[1]/gs"          : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Nav 2 Glideslope" },
    "/instrumentation/nav[1]/cdi"         : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Nav 2 CDI" },
    "/instrumentation/slip-skid-ball"     : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Slip/Skid Ball" },
    "/instrumentation/turn-indicator"     : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Turn Indicator" },
    "/instrumentation/vertical-speed-indicator" : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "VSI" },
    "/systems/electrical"                 : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Electrical system" },
    "/systems/pitot"                      : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Pitot system" },
    "/systems/static"                     : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Static system" },
    "/systems/vacuum"                     : { type: type.MTBF, failure: fail.SERVICEABLE, desc: "Vacuum system" },
    "/controls/gear/gear-down"            : { type: type.MCBF, failure: "/gear/serviceable", desc: "Gear" },
    "/controls/flight/aileron"            : { type: type.MTBF, failure: fail.JAM, desc: "Aileron" },
    "/controls/flight/elevator"           : { type: type.MTBF, failure: fail.JAM, desc: "Elevator" },
    "/controls/flight/rudder"             : { type: type.MTBF, failure: fail.JAM, desc: "Rudder" },
    "/controls/flight/flaps"              : { type: type.MCBF, failure: fail.JAM, desc: "Flaps" },
    "/controls/flight/speedbrake"         : { type: type.MCBF, failure: fail.JAM, desc: "Speed Brake" }
};

# Return the failure entry for a given property
var getFailure = func (prop) {
    var o = breakHash[prop];

    if (o.failure == fail.SERVICEABLE) {
        return prop ~ "/serviceable";
    } elsif (o.failure == fail.ENGINE) {
        return failure_root ~ prop ~ "/serviceable";
    } elsif (o.failure == fail.JAM) {
        return failure_root ~ prop ~ "/serviceable";
    } else {
        return o.failure;
    }
}

# Fail a given property, either using a serviceable flag, or by jamming the property
var failProp = func(prop) {

    var o = breakHash[prop];
    var p = getFailure(prop);

    if (getprop(p) == 1) {
        setprop(p, 0);

        # We always print to the console
        print(getprop("/sim/time/gmt-string") ~ " : " ~ o.desc ~ " failed");
        
        if (getprop(failure_root ~ "/display-on-screen")) {
            # Display message to the screen in red
            screen.log.write(o.desc ~ " failed", 1.0, 0.0, 0.0);
        }
    }
}

# Unfail a given property, used for resetting a failure state.
var unfailProp  = func(prop)
{
    var p = getFailure(prop);
    setprop(p, 1);
}

# Unfail all the failed properties
var unfail = func {
    foreach(var prop; keys(breakHash)) {
        unfailProp(prop);
    }
}

# Listener to jam a property. Note that the property to jam is
# encoded within the property name
var jamListener = func(p) {
    var jamprop = string.replace(p.getParent().getPath(), failure_root, "");
#jamprop = string.replace(jamprop, "/serviceable", "");
    var prop = props.globals.getNode(jamprop);
    if (p.getValue()) {
        prop.setAttribute("writable", 1);
    } else {
        prop.setAttribute("writable", 0);
    }
}

# Listener for an engine property. Note that the engine to set is
# encoded within the property name. We set both the magnetos and
# cutoff to handle different engine models.
var engineListener = func(p) {
    var e = string.replace(p.getParent().getPath(), failure_root, "");
    var prop = props.globals.getNode(e);
    if (p.getValue()) {
        # Enable the properties, but don't set the magnetos, as they may
        # be off for a reason.
        var magnetos = props.globals.getNode("/controls/" ~ e ~ "/magnetos", 1);
        var cutoff = props.globals.getNode("/controls/" ~ e ~ "/cutoff", 1);
        magnetos.setAttribute("writable", 1);
        cutoff.setAttribute("writable", 1);
        cutoff.setValue(0);
    } else {
        # Switch off the engine, and disable writing to it.
        var magnetos = props.globals.getNode("/controls/" ~ e ~ "/magnetos", 1);
        var cutoff = props.globals.getNode("/controls/" ~ e ~ "/cutoff", 1);
        magnetos.setValue(0);
        cutoff.setValue(1);
        magnetos.setAttribute("writable", 0);
        cutoff.setAttribute("writable", 0);
    }
}

# Perform a MCBF check against a failure property.
var checkMCBF = func(prop) {
    var mcbf = getprop(failure_root ~ prop.getPath() ~ "/mcbf");
    # mcbf == mean cycles between failures
    # hence 2*mcbf is the number of _half-cycles_ between failures,
    # which is relevant because we do this check on each half-cycle:
    if ((mcbf > 0) and !int(2 * mcbf * rand())) {
        # Get the property information.
        failProp(prop.getPath());
    }
}

# Timer based loop to check MTBF properties
var checkMTBF = func {
    foreach(var prop; keys(breakHash)) {
        var o = breakHash[prop];
        if (o.type == type.MTBF) {
            var mtbf = getprop(failure_root ~ prop ~ "/mtbf");
            if (mtbf and !int(rand() * mtbf / dt)) {
                failProp(prop);
            }
        }
    }
    settimer(checkMTBF, dt);
}

# Function to set all MTBF failures to a give value. Mainly for testing.
var setAllMTBF = func(mtbf) {
    foreach(var prop; keys(breakHash)) {
        var o = breakHash[prop];
        if (o.type == type.MTBF) {
            setprop(failure_root ~ prop ~ "/mtbf", mtbf);
        }
    }
}

# Function to set all MCBF failures to a give value. Mainly for testing.
var setAllMCBF = func(mcbf) {
    foreach(var prop; keys(breakHash)) {
        var o = breakHash[prop];
        if (o.type == type.MCBF) {
            setprop(failure_root ~ prop ~ "/mcbf", mcbf);
        }
    }
}


# Initialization, called once Nasal and the FDM are loaded properly.
_setlistener("/sim/signals/fdm-initialized", func {
    srand();

    # Engines are added dynamically because there may be an arbritary number
    var i = 1;
    foreach (var e; props.globals.getNode("/engines").getChildren("engine")) {
        breakHash[e.getPath()] = { type: type.MTBF, failure: fail.ENGINE, desc : "Engine " ~ i };
        i = i+1;
    }

    # Set up serviceable, MCBF and MTBF properties.
    foreach(var prop; keys(breakHash)) {
        var o = breakHash[prop];
        var t = "/mcbf";
        
        if (o.type == type.MTBF) {
            t = "/mtbf";
        }

        # Set up the MTBF/MCFB properties to 0. Note that they are in a separate
        # subtree, as there's no guarantee that the property isn't a leaf.
        props.globals.initNode(failure_root ~ prop ~ t, 0);

        if (o.failure == fail.SERVICEABLE) {
            # If the property has a serviceable property, set it if appropriate.
            props.globals.initNode(prop ~ "/serviceable", 1, "BOOL");
        } elsif (o.failure == fail.JAM) {
            # In the JAM case, we actually have a dummy serviceable property for the GUI.
            props.globals.initNode(failure_root ~ prop ~ "/serviceable", 1, "BOOL");
            setlistener(failure_root ~ prop ~ "/serviceable", jamListener);
        } elsif (o.failure == fail.ENGINE) {
            # In the JAM case, we actually have a dummy serviceable property for the GUI.
            props.globals.initNode(failure_root ~ prop ~ "/serviceable", 1, "BOOL");
            setlistener(failure_root ~ prop ~ "/serviceable", engineListener);
        } else {
            # If the serviceable property is actually defined, check it is set.
            props.globals.initNode(o.failure, 1, "BOOL");
        }

        if (o.type == type.MCBF) {
            # Set up listener for MCBF properties, only when the value changes.
            setlistener(prop, checkMCBF, 0, 0);
        }
    }

    # Start checking for failures.
    checkMTBF();
});

