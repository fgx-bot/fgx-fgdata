#############################################################################
#
# Bendix-King KFC-200 Flight Director.
#
# Written by Curtis Olson
# Started 15 Dec 2005.
#
#############################################################################

#############################################################################
# Global shared variables
#############################################################################

# major modes are:
#
# off - Off: v-bars hidden
# fd - Flight Director: v-bars appear and command level wings + pitch at the
#      time mode was activated.
# hdg - Heading: v-bars command a turn to the heading bug
# appr - Approach: bank and pitch commands capture and track LOC and GS
#        (or just bank if VOR/RNAV)
# bc - Reverse Localizer: bank command to capture and track a reverse LOC
#      course.  GS is locked out.
# arm - Standby mode to compute capture point for nav, appr, or bc.
# cpld - Coupled: Active mode for nav, appr, or bc.
# ga - Go Around: commands wings level and missed approach attitude.
# alt - Altitude hold: commands pitch to hold altitude
# vertical trim - pitch command to adjust altitude at 500 fpm while in alt hold
#                 or pitch attitude at rate of 1 deg/sec when not in alt hold
# ap - Autopilot Engage: AP will attempt to track FD.
# pitch synchronization: manual flight maneuvering without the need to 
#                        disengage/engage the AP/FD, AP maintains pitch axis.
# yd - Yaw Damper: system senses motion around ayw axis and moves rudder to
#                  oppose yaw.

# initialize nasal values
fdmode = 0;
hdgmode = "";
bcmode = 0;
altmode = "";
fdmode_last = 0;
hdgmode_last = hdgmode;
altmode_last = altmode;
target_alt = 0;
vbar_bank = 0.0;
vbar_pitch = -180.0;
last_time = 0.0;
ap_enable = 0;

# initialize property values
setprop("/instrumentation/kfc200/fdmode", fdmode);
setprop("/instrumentation/kfc200/hdgmode", hdgmode);
setprop("/instrumentation/kfc200/altmode", altmode);
setprop("/instrumentation/kfc200/vbar-pitch", vbar_pitch);
setprop("/instrumentation/kfc200/vbar-roll", vbar_bank);
setprop("/instrumentation/kfc200/ap-enable", ap_enable);


#############################################################################
# Use tha nasal timer to call the initialization function once the sim is
# up and running
#############################################################################

INIT = func {
    # put any onetime initialization code here that needs to run after
    # everythiing else is fully initialized.
    setprop("/instrumentation/kfc200/inputs/trim-up-btn", 0);
    setprop("/instrumentation/kfc200/inputs/trim-down-btn", 0);
}
settimer(INIT, 0);


#############################################################################
# handle KC 290 Mode Controller inputs, and compute correct mode/settings
#############################################################################

handle_inputs = func {
}


#############################################################################
# track and update mode
#############################################################################

update_mode = func {
    hdgmode = getprop("/instrumentation/kfc200/hdgmode");
    bcmode = getprop("/instrumentation/nav/back-course-btn");
    altmode = getprop("/instrumentation/kfc200/altmode");

    fdNode = props.globals.getNode("/instrumentation/kfc200/fdmode");
    fdmode = fdNode.getBoolValue();
    if ( !fdmode ) {
        return;
    }

    if ( hdgmode == "nav-arm" or hdgmode == "appr-arm" ) {
        # logic to determine when to switch from arm to coupled mode in time
        # to prevent overshoot

        curhdg = getprop("/orientation/heading-magnetic-deg");
        tgtrad = getprop("/instrumentation/nav/radials/selected-deg");
        time_to_int_sec = getprop("/instrumentation/nav/time-to-intercept-sec");
        if ( tgtrad == nil or tgtrad == "" ) {
            tgtrad = 0.0;
        }
        diff = tgtrad - curhdg;
        if ( diff < -180.0 ) {
            diff += 360.0;
        } elsif ( diff > 180.0 ) {
            diff -= 180.0;
        }

        # standard rate turn is 3 dec/sec
        time_to_hdg_sec = abs(diff) / 3.0;
        time_to_hdg_sec = time_to_hdg_sec + 10; # 5 seconds to roll in, 5 out

        # print("tti = ", time_to_int_sec, " hdgdiff = ", diff,
        #       " rollout = ", time_to_hdg_sec );

        if ( time_to_hdg_sec >= abs(time_to_int_sec) ) {
            # switch from arm to cpld
            if ( hdgmode == "nav-arm" ) {
                hdgmode = "nav-cpld";
            } elsif ( hdgmode == "appr-arm" ) {
                hdgmode = "appr-cpld";
            }
        }

        # logic to determine if we are close enough to go straight to coupled
        # mode

        aircraft_bank = getprop("/orientation/roll-deg");
        if ( aircraft_bank >= -4 and aircraft_bank <= 4 ) {
            cdi = getprop("/instrumentation/nav/heading-needle-deflection");
            if ( cdi >= -3 and cdi <= 3 ) {
                if ( hdgmode == "nav-arm" ) {
                    hdgmode = "nav-cpld";
                } elsif ( hdgmode == "appr-arm" ) {
                    hdgmode = "appr-cpld";
                }
            }
        }

    }

    if ( hdgmode == "appr-arm" or hdgmode == "appr-cpld" ) {
        # logic to capture the glide slope when in approach mode
        has_gsNode = props.globals.getNode("/instrumentation/nav/has-gs");
        if ( has_gsNode.getBoolValue() ) {
            gs_needle = getprop("/instrumentation/nav/gs-needle-deflection");
            if ( gs_needle > -2.5 and gs_needle < 2.5 ) {
                # capture the glide slope if within 0.5 degrees by switching
                # to gs altitude mode.  (2.5 = 0.5 * 5, FG has an odd 5x factor
                # that came from some unknown place but it hard to get rid of
                # because so many instruments are build with this converstion
                # factor
                altmode = "glide-slope";
            }
        }
    } else {
        # BC mode (can only be active in appr mode)
        bcmode = 0;
    }

    setprop("/instrumentation/kfc200/hdgmode", hdgmode);
    setprop("/instrumentation/nav/back-course-btn", bcmode);
    setprop("/instrumentation/kfc200/altmode", altmode);
}


#############################################################################
# update the FD vbar position for the various modes
#############################################################################

update_vbar = func {
    # compute elapsed time since last iteration
    current_time = getprop("/sim/time/elapsed-sec");
    dt = current_time - last_time;
    last_time = current_time;

    aircraft_bank = getprop("/orientation/roll-deg");
    if ( aircraft_bank == nil ) { aircraft_bank = 0; }
    aircraft_pitch = getprop("/orientation/pitch-deg");
    if ( aircraft_pitch == nil ) { aircraft_pitch = 0; }

    if ( !fdmode ) {
        # fd off
        # hide vbars, no autopilot modes, disable autopilot
        vbar_bank = 0.0;
        vbar_pitch= -180.0;
        setprop("/autopilot/locks/heading", "");
        setprop("/autopilot/locks/altitude", "");
        setprop("/autopilot/locks/passive-mode", 0);
    } else {
        # handle heading modes
        if ( hdgmode == "hdg" or hdgmode == "nav-arm" 
             or hdgmode == "appr-arm" ) {
            # track heading bug
            if ( hdgmode == "hdg" and hdgmode_last != "hdg" ) {
                setprop("/autopilot/settings/target-pitch-deg", aircraft_pitch);
            }
            if ( hdgmode == "nav-arm" and hdgmode_last != "nav-arm" ) {
                setprop("/autopilot/settings/target-pitch-deg", aircraft_pitch);
            }
            if ( hdgmode == "appr-arm" and hdgmode_last != "appr-arm" ) {
                setprop("/autopilot/settings/target-pitch-deg", aircraft_pitch);
            }
            setprop("/autopilot/locks/heading", "dg-heading-hold");
        } elsif ( hdgmode == "nav-cpld" or hdgmode == "appr-cpld" ) {
            # track nav1 cdi
            setprop("/autopilot/locks/heading", "nav1-hold");
        } elsif ( hdgmode == "go-around" ) {
            # go around mode (wing leveler with fixed pitch up)

            # WAG, pitch up to 5 degrees?  We want a conservative
            # value I think.
            setprop("/autopilot/settings/target-pitch-deg", 5);
            setprop("/autopilot/internal/target-roll-deg", 0);
            setprop("/autopilot/locks/heading", "wing-leveler");
        } else {
            # wing leveler with fixed pitch
            if ( hdgmode_last != "" ) {
                setprop("/autopilot/settings/target-pitch-deg", aircraft_pitch);
            }
            setprop("/autopilot/internal/target-roll-deg", 0);
            setprop("/autopilot/locks/heading", "wing-leveler");
        }

        # handle vertical modes

        # read trim button
        trim_up_node = props.globals.getNode("/instrumentation/kfc200/inputs/trim-up-btn", 1);
        trim_up_btn = trim_up_node.getBoolValue();
        trim_down_node = props.globals.getNode("/instrumentation/kfc200/inputs/trim-down-btn", 1);
        trim_down_btn = trim_down_node.getBoolValue();

        if ( altmode == "alt" ) {
            if ( altmode_last != "alt" ) {
                current_alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
                if ( current_alt == nil ) { current_alt = 0.0; }
                setprop("/autopilot/settings/target-altitude-ft", current_alt);
            }
            setprop("/autopilot/locks/altitude", "altitude-hold");
        } elsif ( altmode == "glide-slope" ) {
            setprop("/autopilot/locks/altitude", "gs1-hold");
        } else {
            setprop("/autopilot/locks/altitude", "pitch-hold");
            if ( trim_up_btn ) {
                target_pitch = getprop("/autopilot/settings/target-pitch-deg");
                if ( target_pitch == nil ) { target_pitch = 0; }
                target_pitch += dt; # 1 deg per second
                setprop("/autopilot/settings/target-pitch-deg", target_pitch);
            } elsif ( trim_down_btn ) {
                target_pitch = getprop("/autopilot/settings/target-pitch-deg");
                if ( target_pitch == nil ) { target_pitch = 0; }
                target_pitch -= dt; # 1 deg per second
                setprop("/autopilot/settings/target-pitch-deg", target_pitch);
            }
        }

        # configure flightgear AP
        apNode = props.globals.getNode("/instrumentation/kfc200/ap-enable");
        ap_enable = apNode.getBoolValue();
        if ( ap_enable ) {
            setprop("/autopilot/locks/passive-mode", 0);
        } else {
            setprop("/autopilot/locks/passive-mode", 1);
        }

        vbar_bank = getprop("/autopilot/internal/target-roll-deg");
        if ( vbar_bank == nil ) { vbar_bank = 0; }
        vbar_pitch = getprop("/autopilot/settings/target-pitch-deg");
        if ( vbar_pitch == nil ) { vbar_pitch = 0; }
    }

    fdmode_last = fdmode;
    hdgmode_last = hdgmode;
    altmode_last = altmode;

    # set vbar position properties
    setprop("/instrumentation/kfc200/vbar-roll", aircraft_bank - vbar_bank);
    setprop("/instrumentation/kfc200/vbar-pitch", vbar_pitch - aircraft_pitch);
}


#############################################################################
# main update function to be called each frame
#############################################################################

update = func {
    # return;

    # print("kfc-200 update");

    handle_inputs();
    update_mode();
    update_vbar();

    registerTimer();
}


#############################################################################
# Use tha nasal timer to call ourselves every frame
#############################################################################

registerTimer = func {
    settimer(update, 0);
}
registerTimer();
