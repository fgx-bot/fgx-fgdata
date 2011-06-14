###############################################################################
##
## Nasal for controling an AI carrier.
##
##  Copyright (C) 2007 - 2010  Anders Gidenstam  (anders(at)gidenstam.org)
##  Copyright (C) 2009  Vivian Meazza
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

# Carrier constants
var carrier_base = nil;
var c_lat     = "position/latitude-deg";
var c_lon     = "position/longitude-deg";
var c_alt     = "position/altitude-ft";
var c_heading = "orientation/true-heading-deg";
var c_pitch   = "orientation/pitch-deg";
var c_roll    = "orientation/roll-deg";
var c_speed   = "velocities/speed-kts";
var c_deck_elev = "controls/elevators";
var c_deck_lights        = "controls/lighting/deck-lights";
var c_flood_lights       = "controls/lighting/flood-lights-red-norm";
var c_turn_to_launch_hdg = "controls/turn-to-launch-hdg";
var c_turn_to_recvry_hdg = "controls/turn-to-recovery-hdg";
var c_turn_to_base_co    = "controls/turn-to-base-course";
var c_wave_off_lights    = "controls/flols/wave-off-lights";

var c_control_speed   = "controls/tgt-speed-kts";
var c_control_course  = "controls/tgt-heading-degs";
var c_control_rudder  = "surface-positions/rudder-pos-deg";
var c_control_mp_ctrl = "controls/mp-control";
var c_control_radius  = "controls/turn-radius-ft";


# Player constants
var p_lat     = "/position/latitude-deg";
var p_lon     = "/position/longitude-deg";
var p_alt     = "/position/altitude-ft";
var p_heading = "/orientation/heading-deg";
var p_pitch   = "/orientation/pitch-deg";
var p_roll    = "/orientation/roll-deg";
var p_speed   = "/velocities/groundspeed-kt";

var p_control_speed  = "/controls/speed-kts";
var p_control_rudder = "/controls/rudder-pos-deg";
var p_control_course = "/controls/target-course-deg";

var p_controls_rudder = 0;

# MP properties
var mp_rudder             = "surface-positions/rudder-pos-norm";
var mp_speed              = "surface-positions/flap-pos-norm";
var mp_network            = "sim/multiplay/generic/string[0]";
var mp_message            = "sim/multiplay/generic/string[2]";
var mp_tgt_hdg            = "sim/multiplay/generic/float[0]";
var mp_tgt_spd            = "sim/multiplay/generic/float[1]";
var mp_turn_radius        = "sim/multiplay/generic/float[2]";

var MP_ANNOUNCE_INTERVAL  = 10.0;
var last_announce = 0;

# Control state
var AI_control = 1;
var loopid  = 0;

###########################################################################
var update = func (id) {
  setprop(p_lat, carrier_base.getNode(c_lat).getValue());
  setprop(p_lon, carrier_base.getNode(c_lon).getValue());
  setprop(p_alt, carrier_base.getNode(c_alt).getValue());

  setprop(p_heading, carrier_base.getNode(c_heading).getValue());
  setprop(p_pitch, carrier_base.getNode(c_pitch).getValue());
  setprop(p_roll, carrier_base.getNode(c_roll).getValue());

  # Force the rudder to obey the player. Overrules AI.
  if (!AI_control) {
    # Switch off AI control for the carrier. (If available.)
    if (carrier_base.getNode(c_control_mp_ctrl) != nil)
      carrier_base.getNode(c_control_mp_ctrl).setBoolValue(1);
    if (p_controls_rudder) {
      carrier_base.getNode(c_control_rudder).
        setValue(getprop(p_control_rudder));
    } else {
      carrier_base.getNode(c_control_course).
        setValue(getprop(p_control_course));        
    }
  } else {
    # Switch on AI control for the carrier. (If available.)
    if (carrier_base.getNode(c_control_mp_ctrl) != nil)
      carrier_base.getNode(c_control_mp_ctrl).setBoolValue(0);
  }

  # Export commands to MP network
  setprop(mp_rudder, carrier_base.getNode(c_control_rudder).getValue());
  setprop(mp_speed, carrier_base.getNode(c_speed).getValue());
  setprop(mp_tgt_hdg, carrier_base.getNode(c_control_course).getValue());
  setprop(mp_tgt_spd, carrier_base.getNode(c_control_speed).getValue());
  setprop(mp_turn_radius, carrier_base.getNode(c_control_radius).getValue());

  # Check and send events if needed.
  send_events();

  settimer(func { update(id) }, 0);
}

###########################################################################
var send_events = func () {
  # Announce local state.
  var now = systime();
  if (now > last_announce + MP_ANNOUNCE_INTERVAL) {
    #    print("Announcing state.");
    MPCarriersNW.send_elevator_state(carrier_base.
                                     getNode(c_deck_elev).getValue());
    MPCarriersNW.send_decklight_state(carrier_base.
                                      getNode(c_deck_lights).getValue());
    MPCarriersNW.send_floodlight_state(carrier_base.
                                       getNode(c_flood_lights).getValue());
    MPCarriersNW.send_launch_state(carrier_base.
                                   getNode(c_turn_to_launch_hdg).getValue()); 
    MPCarriersNW.send_recovery_state(carrier_base.
                                     getNode(c_turn_to_recvry_hdg).getValue());
    MPCarriersNW.send_base_state(carrier_base.
                                 getNode(c_turn_to_base_co).getValue());
    MPCarriersNW.send_wave_off_lights_state(carrier_base.
                                 getNode(c_wave_off_lights).getValue());
    last_announce = now;
  }
}

###########################################################################
var incSpeed = func (i) {
  var speed = getprop(p_control_speed);
  speed = speed + i;
  if (speed < 0) speed = 0;
  if (speed > 30) speed = 30;
  setprop(p_control_speed, speed);
  carrier_base.getNode(c_control_speed).setValue(speed);
  gui.popupTip("Ordered " ~ speed ~ " kts ahead.")
} 

###########################################################################
var incRudder = func (i) {
  if (AI_control) return;
  if (p_controls_rudder) {
    var angle = getprop(p_control_rudder);
    angle += i;
    if (angle < -30) angle = -30;
    if (angle > 30) angle = 30;
    setprop(p_control_rudder, angle);
    gui.popupTip("Rudder to " ~ angle ~ " degrees to " ~
                 (angle < 0 ? "port" : "starboard") ~ ".");
  } else {
    var cur = getprop(p_control_course) + i;
    if (cur < 0) cur += 360;
    if (cur >= 360) cur -= 360;
    setprop(p_control_course, cur);
    gui.popupTip("New course " ~ cur ~ " degrees.");
  }
}

###########################################################################
var toggleAIControl = func {
  if (AI_control) {
    AI_control = 0;
  } else {
    AI_control = 1;
  }
  gui.popupTip(((AI_control) ? "AI" : "Manual") ~ " control.")
}

###########################################################################
var init = func {
  var carriers =
    props.globals.getNode("/ai/models").getChildren("carrier");

  foreach(var c; carriers) {
    if (c.getNode("name").getValue() == carrier_name) {
      carrier_base = c;

      print("Carrier ... AI " ~ carrier_name ~ " found.");
      loopid += 1;

      # Load the MPCarrier MP network.
      io.load_nasal(getprop("/sim/fg-root") ~
                    "/Aircraft/MPCarrier/Systems/mp-network.nas",
                    "MPCarriersNW");
      MPCarriersNW.mp_network_init(1);

      # Make sure the current speed and course will be transmitted.
      setprop(p_control_speed,
              carrier_base.getNode(c_control_speed).getValue());
      setprop(p_control_course,
              carrier_base.getNode(c_control_course).getValue());      
      update(loopid);
      
      # Map some important carrier properties to the main tree.
      var p = "environment/rel-wind-from-carrier-hdg-degs";
      props.globals.getNode(p, 1).alias(carrier_base.getNode(p));
      p = "environment/rel-wind-speed-kts";
      props.globals.getNode(p, 1).alias(carrier_base.getNode(p));
      p = "orientation/true-heading-deg";
      props.globals.getNode(p, 1).alias(carrier_base.getNode(p));
      p = "velocities/speed-kts";
      props.globals.getNode(p, 1).alias(carrier_base.getNode(p));
      p = "controls/tgt-heading-degs";
      props.globals.getNode(p, 1).alias(carrier_base.getNode(p));
      p = "controls/tgt-speed-kts";
      props.globals.getNode(p, 1).alias(carrier_base.getNode(p));

      # Avoid ugly error messages if the current carrier doesn't
      # have a walk view.
      if (!contains(globals, "walkview")) {
        globals.walkview = {
            forward   : func {},
            side_step : func {}
        };
      }

      return;
    }
  }
  print("Carrier ... Failure. The " ~ carrier_name ~
        " carrier was not found.");
  print("Carrier: An appropriate AI scenario must be active " ~
        "(" ~ carrier_name ~ "_demo?).");
}

setlistener("/sim/signals/fdm-initialized", func {
  settimer(func {
    init();
  }, 1.0);
});
