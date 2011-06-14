init_fuel = func {

    props.globals.getNode("/consumables/fuel/tank[1]/level-gal_us", 1).setDoubleValue(0.0);
    props.globals.getNode("/consumables/fuel/tank[1]/level-lbs", 1).setDoubleValue(0.0);

    props.globals.getNode("/consumables/fuel/tank[2]/level-gal_us", 1).setDoubleValue(0.0);
    props.globals.getNode("/consumables/fuel/tank[2]/level-lbs", 1).setDoubleValue(0.0);

}

setlistener("/sim/signals/fdm-initialized",init_fuel);

