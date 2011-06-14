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
    heading.setDoubleValue(0.0);
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


var angleUpdate = func {
    var error = course - heading.getValue();
    if ( error < -180.0 ) {
        error += 360.0;
    } elsif ( error > 180.0 ) {
        error -= 360.0;
    }

    target_steer_angle = error / 4.0;
    if ( target_steer_angle < -20.0 ) {
        target_steer_angle = -20.0;
    } elsif ( target_steer_angle > 20.0 ) {
        target_steer_angle = 20.0;
    }

    # print( "course = ", course, " hdg = ", heading, " err = ", error );
}


var servoUpdate = func( dt ) {
    var mode = control_node.getValue();
    if ( mode == 0 ) {
        # autonomous control off
        return;
    }

    var angle = steer_angle_node.getValue();

    var target_steer = target_steer_angle / 20.0;
    var error = target_steer - angle;

    #var volts = steer_volt_node.getValue();
    var volts = error * 16.0;
    if ( volts < -4.0 ) {
        volts = -4.0;
    } elsif ( volts > 4.0 ) {
        volts = 4.0;
    }
    if ( volts > 0.001 ) {
        volts += 1.0;
    } elsif ( volts < 0.001 ) {
        volts -= 1.0;
    }

    # 0.33 = 6 seconds to drive the wheels from one extreme to the other
    if ( volts >= 1.0 ) {
        rate = ((volts - 1.0) / 4.0) * 0.33 * dt;
    } elsif ( volts <= -1.0 ) {
        rate = ((volts + 1.0) / 4.0) * 0.33 * dt;
    } else {
        rate = 0.0;
    }

    angle += rate;
    steer_angle_node.setValue( angle );
}


# update steering controller
var steeringUpdate = func( dt ) {
    angleUpdate();
    servoUpdate( dt );
}
