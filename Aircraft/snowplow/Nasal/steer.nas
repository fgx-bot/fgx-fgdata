# inner steering control loop.  Given a target wheel angle, run the
# steering servo motor to achieve that angle.

var steer_angle_node = props.globals.getNode("/controls/flight/aileron", 1);
var steer_volt_node = props.globals.getNode("/me5286/servo/steer/volts", 1);
var heading = props.globals.getNode("/orientation/heading-deg", 1);
var target_steer_angle = 0.0;

# initialize variables and values
var steerInit = func {
    # set initial values
    steer_angle_node.setDoubleValue(0.0);
    steer_volt_node.setDoubleValue(0.0);
}


# set the steering servo voltage outpu
var setSteeringVoltage = func( voltage ) {
    if ( voltage < -5 ) {
        voltage = -5;
    }
    if ( voltage > 5 ) {
        voltage = 5;
    }
    steer_volt_node.setValue( voltage );
}


var servoUpdate = func( dt ) {
    var mode = control_node.getValue();
    if ( mode == 0 ) {
        # autonomous control off
        return;
    }

    var angle = steer_angle_node.getValue();

    #
    # Insert code here to compute course error, compute a desired steer
    # angle, and use the steering servo to drive the wheels to that steer
    # angle.
    #

    steer_angle_node.setValue( angle );
}


# update steering controller
var steeringUpdate = func( dt ) {
    servoUpdate( dt );
}
