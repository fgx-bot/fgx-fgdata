# speed controller: uses a combination of throttle and brake to
# achieve the desired speed.  This is a simple proportionaly
# controller so depending on hills and wind and surface conditions, it
# will probably never quite hit the target, but it should usually be
# pretty close.


var ground_speed_node = props.globals.getNode("/velocities/groundspeed-kt", 1);
var target_speed_node = props.globals.getNode("/me5286/target-speed-kt", 1);
var left_brake_node = props.globals.getNode("/controls/gear/brake-left", 1);
var right_brake_node = props.globals.getNode("/controls/gear/brake-right", 1);
var throttle_node = props.globals.getNode("/controls/engines/engine/throttle", 1);


# initialize variables and values
var speedInit = func {
    # set initial values
    ground_speed_node.setDoubleValue(0.0);
    target_speed_node.setDoubleValue(0.0);
}


var speedUpdate = func {
    var gs = ground_speed_node.getValue();
    var ts = target_speed_node.getValue();

    var alt_min_ts = ts;
    if ( radar_dist < 1.0 ) {
        alt_min_ts = (radar_dist - 0.020) * 550;
        if ( alt_min_ts < 0.0 ) { alt_min_ts = 0.0; }
    }
    if ( alt_min_ts < ts ) { ts = alt_min_ts; }

    var error = ts - gs;

    var throttle = error / 2.0;
    if ( throttle > 1.0 ) { throttle = 1.0; }
    if ( throttle < 0.0 ) { throttle = 0.0; }
    throttle_node.setValue( throttle );

    var brake = -error / 25.0;
    if ( brake > 0.5 ) { brake = 0.5; }
    if ( brake < 0.0 ) { brake = 0.0; }
    left_brake_node.setValue( brake );
    right_brake_node.setValue( brake );
}
