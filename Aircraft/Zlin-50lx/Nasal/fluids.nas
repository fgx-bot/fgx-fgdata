var oil_press = props.globals.getNode("/instrumentation/engine/oil-press", 1);
var oil_temp = props.globals.getNode("/instrumentation/engine/oil-temp", 1);
var fuel_press = props.globals.getNode("/instrumentation/engine/fuel-press", 1);
#var cht = props.globals.getNode("/instrumentation/engine/cht-degf", 1);

var initialize = func {
    #make wing tanks empty
    props.globals.getNode("/consumables/fuel/tank[1]/level-gal_us", 1).setDoubleValue(0.0);
    props.globals.getNode("/consumables/fuel/tank[1]/level-lbs", 1).setDoubleValue(0.0);
    props.globals.getNode("/consumables/fuel/tank[2]/level-gal_us", 1).setDoubleValue(0.0);
    props.globals.getNode("/consumables/fuel/tank[2]/level-lbs", 1).setDoubleValue(0.0);

    # all pressures initialized to 0.0
    oil_press.setDoubleValue(0.0);
    fuel_press.setDoubleValue(0.0);

    #all temperatures initialized to environment temperature
    var oatf = getprop("/environment/temperature-degf");
    oil_temp.setDoubleValue(oatf);
    setprop("/instrumentation/engine/cht-degf",oatf);

    #settimer(update_press, 0);
    settimer(update_temp, 0);
    if (getprop("/sim/model/path") == "Aircraft/Zlin-50lx/Models/z50lx-IFR.xml")
	settimer(update_IFRspecs, 0);
    print ("fluids system initialized");
}

update_temp = func {
    if(getprop("/engines/engine/running") != 0){
        interpolate("/instrumentation/engine/cht-degf", getprop("/engines/engine/oil-temperature-degf")+100, 10);
        interpolate("/instrumentation/engine/oil-temp", getprop("/engines/engine/oil-temperature-degf"), 30);
    } else {
        interpolate("/instrumentation/engine/cht-degf", getprop("/environment/temperature-degf"), 100);
        interpolate("/instrumentation/engine/oil-temp", getprop("/environment/temperature-degf"), 1000);
    }
    settimer(update_temp,0);
}

update_IFRspecs = func {
    setprop("/instrumentation/nav[0]/radials/selected-deg", int(getprop("/instrumentation/kcs55/ki525/selected-course-deg")));
    setprop("/autopilot/settings/heading-bug-deg", getprop("/instrumentation/kcs55/ki525/selected-heading-deg"));

    var density_ppg = getprop("/consumables/fuel/tank[0]/density-ppg");

    setprop("/consumables/fuel/tank[0]/level-liters", getprop("/consumables/fuel/tank[0]/level-gal_us") / 0.264);
    setprop("/consumables/fuel/tank[0]/level-lbs", getprop("/consumables/fuel/tank[0]/level-gal_us") * density_ppg); 

    setprop("/consumables/fuel/tank[1]/level-liters", getprop("/consumables/fuel/tank[1]/level-gal_us") / 0.264);
    setprop("/consumables/fuel/tank[1]/level-lbs", getprop("/consumables/fuel/tank[1]/level-gal_us") * density_ppg); 

    setprop("/consumables/fuel/tank[2]/level-liters", getprop("/consumables/fuel/tank[2]/level-gal_us") / 0.264);
    setprop("/consumables/fuel/tank[2]/level-lbs", getprop("/consumables/fuel/tank[2]/level-gal_us") * density_ppg); 
    settimer(update_IFRspecs, 0);
}

setlistener("/sim/signals/fdm-initialized",initialize);
