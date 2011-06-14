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
# bc - Reverse Localizer: bank command to caputre and track a reverse LOC
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

fdmode = "off";
setprop("/instrumentation/kfc200/fdmode", fdmode);
fdmode_last = "off";
vbar_roll = 0.0;
vbar_pitch = 0.0;
vbar_rol_propl = 0.0;
vbar_pitch_prop = 0.0;
nav_dist = 0.0;
last_nav_dist = 0.0;
last_nav_time = 0.0;
tth_filter = 0.0;
alt_select = 0.0;
current_alt=0.0;
alt_offset = 0.0;
kfcmode="";
ap_on = 0.0;
alt_alert = 0.0;


#############################################################################
# Use tha nasal timer to call the initialization function once the sim is
# up and running
#############################################################################

INIT = func {
    # default values
    print("Initializing Flight Director");
    setprop("/instrumentation/kfc200/fdmode", "off");
    setprop("/instrumentation/kfc200/vbar-pitch", 0.0);
    setprop("/instrumentation/kfc200/vbar-roll", 0.0);
    setprop("/instrumentation/kfc200/alt-offset", 0.0);
    setprop("/instrumentation/kfc200/autopilot-on",0.0);
    setprop("/instrumentation/kfc200/alt-alert", alt_alert);
    setprop("/autopilot/settings/heading-bug-deg",0);
    setprop("/autopilot/settings/target-altitude-ft",0);
current_alt = getprop("/instrumentation/altimer/indicated-altitude-ft");
alt_select = getprop("/autopilot/settings/target-altitude-ft");

}
settimer(INIT, 0);


#############################################################################
# handle KC 290 Mode Controller inputs, and compute correct mode/settings
#############################################################################

handle_inputs = func {
# Autopilot  activate
    fdmode = getprop("/instrumentation/kfc200/fdmode");
   ap_on = getprop("/instrumentation/kfc200/autopilot-on");

if(ap_on==1){
if(fdmode == "fd" or fdmode == "off"){setprop("autopilot/locks/heading","wing-leveler");}
if(fdmode == "hdg"){setprop("autopilot/locks/heading","dg-heading-hold");}
if(fdmode == "alt"){setprop("autopilot/locks/altitude","altitude-hold");}
}
if(ap_on == 0){
setprop("autopilot/locks/heading","");
setprop("autopilot/locks/altitude","");
setprop("autopilot/locks/speed","");
  }
}


#############################################################################
# track and update mode
#############################################################################

update_mode = func {
    fdmode = getprop("/instrumentation/kfc200/fdmode");

    # compute elapsed time since last iteration
    nav_time = getprop("/sim/time/elapsed-sec");
    nav_dt = nav_time - last_nav_time;
    last_nav_time = nav_time;

    inrange = getprop("/instrumentation/nav/in-range");
    if ( inrange ) {
        # compute distance to nav heading intercept
        nav_dist = getprop("/instrumentation/nav/crosstrack-error-m");

        # compute time to heading (tth)
        nav_rate = (last_nav_dist - nav_dist) / nav_dt;
        if ( abs(nav_rate) > 0.00001 ) {
            tth = nav_dist / nav_rate;
        } else {
            tth = 9999.9;
        }
      #  print("nav-dist = ", nav_dist, " tth = ", tth);

        tth_filter = 0.9 * tth_filter + 0.1 * tth;
        last_nav_dist = nav_dist;
    }        

    if ( fdmode == "nav-arm" ) {
        curhdg = getprop("/orientation/heading-magnetic-deg");
        tgtrad = getprop("/instrumentation/nav/radials/selected-deg");
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
        roll_out_time_sec = abs(diff) / 3.0;

      #  print("tth = ", tth_filter, " hdgdiff = ", diff, " rollout = ", roll_out_time_sec );
        if ( roll_out_time_sec >= abs(tth_filter) ) {
            # switch from arm to cpld
            fdmode = "nav-cpld";
        }

    }

    setprop("/instrumentation/kfc200/fdmode", fdmode);
}

#############################################################################
#get pitch from autopilot altitude setting
#############################################################################

get_altpitch = func(){
alt_offset = 0.0;
alt_select = getprop("/autopilot/settings/target-altitude-ft");
if ( alt_select == nil or alt_select == "" ){ alt_select = 0.0;return (alt_select);}
current_alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
if(current_alt == nil){current_alt = 0.0;}
alt_offset = (alt_select-current_alt);
setprop("/instrumentation/kfc200/alt-alert",alt_offset);
if(alt_offset > 500.0){alt_offset = 500.0;}
if(alt_offset < -500.0){alt_offset = -500.0;}
vbar_pitch = alt_offset * 0.01;
}


#############################################################################
# update the FD vbar position for the various modes
#############################################################################

update_vbar = func {
    if ( fdmode == "fd" ) {
        # wings level maintain pitch at time of mode activation
        if ( fdmode_last != "fd" ) {
            vbar_roll = 0.0;
           # vbar_pitch = getprop("/orientation/pitch-deg");
}
    } elsif ( fdmode == "hdg" or fdmode == "nav-arm" ) {
        # FIXME: at what angle off of the hdg bug do we start the rollout?
        # bank to track heading bug
vbar_pitch =  get_altpitch();

        if ( fdmode_last != "hdg" ) {

        }
        tgtrad = getprop("/autopilot/settings/heading-bug-deg");
        if ( tgtrad == nil or tgtrad == "" ) {
            tgtrad = 0.0;
        }
        curhdg = getprop("/orientation/heading-magnetic-deg");
        diff = tgtrad - curhdg;
        if ( diff < -180.0 ) {
            diff += 360.0;
        } elsif ( diff > 180.0 ) {
            diff -= 180.0;
        }
        # max bank = 30, so this means roll out begins at 15 dgs off target hdg
        bank = 2 * diff;
        if ( bank < -30.0 ) {
            bank = -30.0;
        }
        if ( bank > 30.0 ) {
            bank = 30.0;
        }
        vbar_roll = bank;
#        print("diff = ", diff);
    } elsif ( fdmode == "nav-cpld" ) {
        curhdg = getprop("/orientation/heading-magnetic-deg");
        tgtrad = getprop("/instrumentation/nav/radials/selected-deg");
        toflag = getprop("/instrumentation/nav/to-flag");
        actrad = 0.0;
        offset = 0.0;
        if ( toflag ) {
            actrad = getprop("/instrumentation/nav/radials/reciprocal-radial-deg");
            offset = 3 * (actrad - tgtrad);
        } else {
            actrad = getprop("/instrumentation/nav/radials/actual-deg");
            offset = 3 * (tgtrad - actrad);
        }

        if ( offset < -90.0 ) { offset = -90.0; }
        if ( offset > 90.0 ) { offset = 90.0; }
        tgthdg = tgtrad + offset;

        diff = tgthdg - curhdg;
        if ( diff < -180.0 ) {
            diff += 360.0;
        } elsif ( diff > 180.0 ) {
            diff -= 180.0;
        }
       # print("* offset = ", offset, " tgthdg = ", tgthdg, " diff = ", diff);

        # max bank = 30, so this means roll out begins at 15 dgs off target hdg
        bank = 2 * diff;
        if ( bank < -30.0 ) {
            bank = -30.0;
        }
        if ( bank > 30.0 ) {
            bank = 30.0;
        }
        vbar_roll = bank;

    } else {
        # assume off if nothing else specified, and hide vbars
        vbar_roll = 0.0;
get_altpitch();
    }


    fdmode_last = fdmode;
vbar_pitch_prop = (vbar_pitch-getprop("/orientation/pitch-deg"));
vbar_roll_prop = (getprop("/orientation/roll-deg") - vbar_roll);
if(vbar_roll_prop > 30.0){vbar_roll_prop = 30.0;}
if(vbar_roll_prop < -30.0){vbar_roll_prop = -30.0;}
if(vbar_pitch_prop > 5.0){vbar_pitch_prop = 5.0;}
if(vbar_pitch_prop < -5.0){vbar_pitch_prop = -5.0;}


setprop("/instrumentation/kfc200/vbar-pitch",vbar_pitch_prop);
setprop("/instrumentation/kfc200/vbar-roll", vbar_roll_prop);
setprop("/instrumentation/kfc200/alt-offset", alt_offset);
setprop("/instrumentation/kfc200/current-alt", current_alt);
}


#############################################################################
# main update function to be called each frame
#############################################################################

update = func {
#    print("kfc-200 update");

    handle_inputs();
    update_mode();
    update_vbar();

#    print( "vbar roll = ", vbar_roll, "(", getprop("/orientation/roll-deg"),
 #          ") pitch = ", vbar_pitch, "(", getprop("/orientation/pitch-deg"),
 #         ")" );

    registerTimer();
}


#############################################################################
# Use tha nasal timer to call ourselves every frame
#############################################################################

registerTimer = func {
    settimer(update, 0);
}
registerTimer();
