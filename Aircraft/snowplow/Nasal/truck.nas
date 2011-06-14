var control_node = props.globals.getNode("/me5286/control-mode", 1);
var dialog = gui.Dialog.new("/sim/gui/dialogs/snowplow/config/dialog",
                            "Aircraft/snowplow/Dialogs/config.xml");
var last_time = 0.0;


# initialize variables and values
var truckInit = func {
    # set initial values
    control_node.setBoolValue(0);

    # initialize other modules
    speedInit();
    steerInit();
    radarInit();
    routeInit();
}


# master truck update function
truckUpdate = func {
    # compute "dt"
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    last_time = time;

    # print("truck update ", dt);
    radarUpdate();
    speedUpdate(dt);
    routeUpdate(dt);
    steeringUpdate(dt);

    settimer(truckUpdate, 0.0);
}


# the following code runs when this file is loaded at startup
truckInit();
truckUpdate();
