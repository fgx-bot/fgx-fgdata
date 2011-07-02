###############################################################################
##
## Nasal module for connecting a local AI carrier to a MP player.
##
##  Copyright (C) 2007 - 2011  Anders Gidenstam  (anders(at)gidenstam.org)
##  Copyright (C) 2009  Vivian Meazza
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

# NOTE:
#   This module is intended to be loaded under the name MPCarriers.

# Constants
var lat     = "position/latitude-deg";
var lon     = "position/longitude-deg";
var alt     = "position/altitude-ft";
var c_heading = "orientation/true-heading-deg";
var c_pitch   = "orientation/pitch-deg";
var c_roll    = "orientation/roll-deg";
var c_speed   = "velocities/speed-kts";
var x           = "position/global-x";
var y           = "position/global-y";
var z           = "position/global-z";

#var c_control_speed   = "controls/base-speed-kts";
#var c_control_course  = "controls/base-course-deg";
var c_control_speed   = "controls/tgt-speed-kts";
var c_control_course  = "controls/tgt-heading-degs";
var c_wave_off_lights = "controls/flols/wave-off-lights";


var c_control_mp_ctrl = "controls/mp-control";

var c_deck_elev          = "controls/elevators";
var c_deck_lights        = "controls/lighting/deck-lights";
var c_flood_lights       = "controls/lighting/flood-lights-red-norm";
var c_turn_to_launch_hdg = "controls/turn-to-launch-hdg";
var c_turn_to_recvry_hdg = "controls/turn-to-recovery-hdg";
var c_turn_to_base_co    = "controls/turn-to-base-course";


var mp_heading = "orientation/true-heading-deg";
var mp_pitch   = "orientation/pitch-deg";
var mp_roll    = "orientation/roll-deg";

# MP transmitted controls
var mp_speed              = "surface-positions/flap-pos-norm";
var mp_rudder             = "surface-positions/rudder-pos-norm";
var mp_network            = "sim/multiplay/generic/string[0]";
var mp_message            = "sim/multiplay/generic/string[2]";
var mp_tgt_hdg            = "sim/multiplay/generic/float[0]";
var mp_tgt_spd            = "sim/multiplay/generic/float[1]";
var mp_turn_radius        = "sim/multiplay/generic/float[2]";

# Controller parameters.
var cross_course_gain    = 0.2;
var cross_course_fadeout = 100.0;
var cross_course_limit   = 20.0;

###############################################################################
# Manager class for one model instance.
var Manager = {};
##################################################
Manager.new = func (player = nil, carrier_name = nil, callsign = nil) {
  var obj = { parents           : [Manager],
              rplayer           : player,
              carrier_name      : carrier_name,
              carrier           : nil,
              accept_callsign   : callsign,
              callsign_listener : nil,
              FREEZE_DIST       : 400.0,
              comms             : nil,
              message           : nil,
              loopid  : 0 };

  var carriers =
    props.globals.getNode("/ai/models").getChildren("carrier");

  foreach(var c; carriers) {
    if (c.getNode("name").getValue() == carrier_name) {

      obj.carrier = c;
      print("MPCarriers ... " ~ carrier_name ~ " for player " ~
            player.getPath() ~ " initializing.");
      obj.callsign_listener =
        setlistener(callsign,
                    func { print("MPCarriers ... callsign update");
                           obj.start(); });
      MPCarriersNW.Manager_instances[player.getIndex()] = obj;
      obj.start();
      return obj;
    }
  }
  print("MPCarriers ... Failure: The AI carrier " ~ carrier_name ~
        " was not found.");
  print("MPCarriers: The nimitz_demo AI scenario must be active.");
  return obj;
}
##################################################
Manager.is_valid = func {
  return ((me.rplayer.getNode("valid") != nil) and
          me.rplayer.getNode("valid").getValue() and
          (me.rplayer.getNode("callsign") != nil));
}
##################################################
Manager.is_active = func {
  return ((me.rplayer.getNode("callsign") != nil) and
          cmp(me.rplayer.getNode("callsign").getValue(),
              me.accept_callsign.getValue()) == 0);
}
##################################################
Manager.set_property = func (path, value) {
  if (!me.is_valid() or !me.is_active()) return;
  me.carrier.getNode(path).setValue(value);
}
##################################################
Manager.update = func {
  var aircraft_pos = geo.aircraft_position();
  var carrier_pos  = geo.Coord.new(aircraft_pos);

  if (!me.is_valid()) {
    # This carrier player is not valid anymore.
    me.die();
    return;
  }
  if (!me.is_active()) {
    # This carrier player is not the chosen one. Go idle.
    me.stop();
    return;
  }

# LSO comms
  var message = me.rplayer.getNode(mp_message).getValue();
  if (message != ""){

    if (message != me.message){
      setprop("/sim/messages/approach", message);
    }

    me.message = message;
  }

#  carrier_pos.set_latlon(me.carrier.getNode(lat).getValue(),
#                         me.carrier.getNode(lon).getValue(),
#                         me.carrier.getNode(alt).getValue());

  carrier_pos.set_xyz(me.carrier.getNode(x).getValue(),
                      me.carrier.getNode(y).getValue(),
                      me.carrier.getNode(z).getValue());

  # Compute the position and orientation error.
  var rplayer_pos  = geo.Coord.new(carrier_pos);
#  rplayer_pos.set_latlon(me.rplayer.getNode(lat).getValue(),
#                         me.rplayer.getNode(lon).getValue(),
#                         me.rplayer.getNode(alt).getValue());

  rplayer_pos.set_xyz(me.rplayer.getNode(x).getValue(),
                      me.rplayer.getNode(y).getValue(),
                      me.rplayer.getNode(z).getValue());

  var master_course      =
    normalize_course(me.rplayer.getNode(mp_heading).getValue());
  var master_speed       = me.rplayer.getNode(mp_speed).getValue();
  var bearing_to_master  = normalize_course(carrier_pos.course_to(rplayer_pos));
  var distance_to_master = carrier_pos.direct_distance_to(rplayer_pos);
  var v = D2R * normalize_course(bearing_to_master - master_course);
  var cross_track_error  =
    distance_to_master * math.sin(v);
  var along_track_error  =
    distance_to_master * math.cos(v);
  var master_tgt_hdg     = as_num(me.rplayer.getNode(mp_tgt_hdg).getValue(),
                                  me.rplayer.getNode(mp_heading).getValue());
  var master_tgt_spd     = as_num(me.rplayer.getNode(mp_tgt_spd).getValue(),
                                  me.rplayer.getNode(mp_speed).getValue());
  var master_turn_radius = as_num(me.rplayer.getNode(mp_turn_radius).getValue());

  var diff = master_course - master_tgt_hdg;

  if (diff > 180)
      diff -= 360;
  elsif (diff < -180)
      diff += 360;

  if ( diff < -1.0 or diff > 1.0){
      # major course alteration - we'll just use target heading from
      # master until it's nearly complete
      # print("major turn" , diff);
      var set_course = master_tgt_hdg ;
      var correction = 0;

      if (diff < 0){
          correction = -cross_track_error * M2FT;
#          print("stbd turn ", correction);
      } elsif (diff > 0){
          correction = cross_track_error * M2FT;
#          print("port turn ", correction);
      } else {
          correction = 0;
#          print("no turn ", correction);
      }

      me.carrier.getNode("controls/turn-radius-ft", 1).setValue(master_turn_radius + correction);

  } else {
      # Use Controller.
      me.carrier.getNode("controls/turn-radius-ft", 1).setValue(master_turn_radius);
      var set_course =
        normalize_course(180.0/math.pi *
                         (math.abs(cross_track_error) < cross_course_fadeout ?
                          math.pow
                           (math.abs(cross_track_error/cross_course_fadeout),2) :
                          1.0) *
                         math.atan2(cross_course_gain * cross_track_error,
                                    along_track_error) +
                         master_course);
      # Limit the course to +/-cross_course_limit degrees off the master's course.
      if (set_course - master_course > cross_course_limit) {
        set_course = normalize_course(master_course + cross_course_limit);
      } else if (set_course - master_course < -cross_course_limit) {
        set_course = normalize_course(master_course - cross_course_limit);
      }

  }
  var spd_diff = master_speed - master_tgt_spd;

  if ( spd_diff < -1 or spd_diff > 1){
# major speed alteration - we'll just use target speed from
# master until it's nearly complete
      var set_speed = master_tgt_spd +
          0.01 * along_track_error;
      if (set_speed > master_tgt_spd + 5.0) set_speed = master_tgt_spd + 5.0;
      if (set_speed < master_tgt_spd - 5.0) set_speed = master_tgt_spd - 5.0;
  } else {
      var set_speed  = master_speed +
          0.01 * along_track_error;
      if (set_speed > master_speed + 5.0) set_speed = master_speed + 5.0;
      if (set_speed < master_speed - 5.0) set_speed = master_speed - 5.0;
  }

  # publish controller settings.
  me.carrier.getNode("mp-control/bearing-to-master-rel-deg", 1).
    setValue(v);
  me.carrier.getNode("mp-control/bearing-to-master-deg", 1).
    setValue(bearing_to_master);
  me.carrier.getNode("mp-control/distance-to-master-m", 1).
    setValue(distance_to_master);
  me.carrier.getNode("mp-control/cross-track-error-m", 1).
    setValue(cross_track_error);
  me.carrier.getNode("mp-control/along-track-error-m", 1).
    setValue(along_track_error);

  me.carrier.getNode("mp-control/master-speed-kts", 1).setValue(master_speed);
  me.carrier.getNode("mp-control/master-course-deg", 1).setValue(master_course);

  me.carrier.getNode("mp-control/set-speed-kts", 1).setValue(set_speed);
  me.carrier.getNode("mp-control/set-course-deg", 1).setValue(set_course);
  me.carrier.getNode("mp-control/tgt-hdg-deg", 1).setValue(sprintf ( "%03.1d", master_tgt_hdg));
  me.carrier.getNode("mp-control/tgt-spd-kts", 1).setValue(master_tgt_spd);
  me.carrier.getNode("mp-control/turn-radius-ft", 1).setValue(master_turn_radius);

  if (aircraft_pos.direct_distance_to(carrier_pos) > me.FREEZE_DIST) {
    # Latch the local AI carrier to the remote player's
    # location only when the local player is far enough away not
    # to suffer side effects.
    me.carrier.getNode(lat).setValue(me.rplayer.getNode(lat).getValue());
    me.carrier.getNode(lon).setValue(me.rplayer.getNode(lon).getValue());
    me.carrier.getNode(alt).setValue(me.rplayer.getNode(alt).getValue());

    me.carrier.getNode(c_heading).
      setValue(master_course);
    me.carrier.getNode(c_pitch).
      setValue(me.rplayer.getNode(mp_pitch).getValue());
    me.carrier.getNode(c_roll).
      setValue(me.rplayer.getNode(mp_roll).getValue());

    # Accelerate the AI carrier to the right speed.
    me.carrier.getNode(c_control_speed).
      setValue(master_speed);
  } else {
    # Player on deck. Use the speed controller.
    me.carrier.getNode(c_control_speed).
      setValue(set_speed);
  }

  # Always set these commands.
  me.carrier.getNode(c_control_course).
    setValue(set_course);

  # Switch off AI control for the carrier if available.
  if (me.carrier.getNode(c_control_mp_ctrl) != nil)
    me.carrier.getNode(c_control_mp_ctrl).setBoolValue(1);
}
##################################################
Manager.stop = func {
  me.loopid += 1;
  print("MPCarriers ... " ~ me.carrier_name ~ " for " ~
        me.rplayer.getPath() ~ " idle.");
  # Reenable AI control.
  if (me.carrier.getNode(c_control_mp_ctrl) != nil)
    me.carrier.getNode(c_control_mp_ctrl).setBoolValue(0);
}
##################################################
Manager.die = func {
  removelistener(me.callsign_listener);
  delete(MPCarriersNW.Manager_instances, me.rplayer.getIndex());
  me.loopid += 1;

  # Delay the reactivation of AI control.
  settimer(func {
    if (me.carrier.getNode(c_control_mp_ctrl) != nil)
      me.carrier.getNode(c_control_mp_ctrl).setBoolValue(0);
  }, 5.0);

  print("MPCarriers ... " ~ me.carrier_name ~ " for " ~
        me.rplayer.getPath() ~ " destroyed.");
}
##################################################
Manager.start = func {
            print("initializing lso comms ... ");
  me.loopid += 1;
  print("MPCarriers ... " ~ me.carrier_name ~ " for " ~
        me.rplayer.getPath() ~ " activated.");
  me._loop_(me.loopid);
}
##################################################
Manager._loop_ = func(id) {
  id == me.loopid or return;
  me.update();
  settimer(func { me._loop_(id); }, 0);
}
###############################################################################

###############################################################################

#################################################################
var normalize_course = func(c) {
    while (c < 0) c += 360;
    while (c >= 360) c -= 360;
    return c;
}

#################################################################
# Return a hash containing all nearby carrier players
# indexed on MP-carrier type
var find_carrier_players = func {
    var mpplayers =
        props.globals.getNode("/ai/models").getChildren("multiplayer");

    var res = {};
    foreach (var pilot; mpplayers) {
        if ((pilot.getNode("valid") != nil) and
            (pilot.getNode("valid").getValue()) and
            (pilot.getNode("sim/model/ac-type") != nil)) {
            var type = pilot.getNode("sim/model/ac-type").getValue();

            if (streq("MP-", substr(type, 0, 3))) {
                if (!contains(res, type)) {
                    res[type] = [pilot.getNode("callsign").getValue()];
                } else {
                    append(res[type], pilot.getNode("callsign").getValue());
                }
            }
        }
    }
#    debug.dump(res);
    return res;
}

###############################################################################
# MPCarrier selection dialog.
var CARRIER_DLG = 0;
var carrier_dialog = {};
############################################################
carrier_dialog.init = func (x = nil, y = nil) {
    me.x = x;
    me.y = y;
    me.bg = [0, 0, 0, 0.3];    # background color
    me.fg = [[1.0, 1.0, 1.0, 1.0]]; 
    #
    # "private"
    me.title = "MPCarrier";
    me.basenode = props.globals.getNode("/sim/mp-carriers", 1);
    me.dialog = nil;
    me.namenode = props.Node.new({"dialog-name" : me.title });
    me.listeners = [];
    me.carriers = { "MP-Nimitz"     : "nimitz-callsign",
                    "MP-Eisenhower" : "eisenhower-callsign",
                    "MP-Foch"       : "foch-callsign",
                    "MP-Clemenceau" : "clemenceau-callsign",
                    "MP-Vinson"     : "vinson-callsign"};
}
############################################################
carrier_dialog.create = func {
    if (me.dialog != nil)
        me.close();

    me.dialog = gui.Widget.new();
    me.dialog.set("name", me.title);
    if (me.x != nil)
        me.dialog.set("x", me.x);
    if (me.y != nil)
        me.dialog.set("y", me.y);

    me.dialog.set("layout", "vbox");
    me.dialog.set("default-padding", 0);
    var titlebar = me.dialog.addChild("group");
    titlebar.set("layout", "hbox");
    titlebar.addChild("empty").set("stretch", 1);
    titlebar.addChild("text").set("label", "MPCarriers online");
    var w = titlebar.addChild("button");
    w.set("pref-width", 16);
    w.set("pref-height", 16);
    w.set("legend", "");
    w.set("default", 0);
    w.set("key", "esc");
    w.setBinding("nasal", "MPCarriers.carrier_dialog.destroy(); ");
    w.setBinding("dialog-close");
    me.dialog.addChild("hrule");

    var content = me.dialog.addChild("group");
    content.set("layout", "vbox");
    content.set("halign", "center");
    content.set("default-padding", 5);

    # Generate the dialog contents.
    me.players = find_carrier_players();
    foreach (var type; keys(me.carriers)) {
        var selected = me.basenode.getNode(me.carriers[type], 1).getValue();
        var tmpbase = me.basenode.getNode(type, 1);

        if (contains(me.players, type)) {
            var i = 0;
            foreach (var p; me.players[type]) {
                var tmp = tmpbase.getNode("b[" ~ i ~ "]", 1);
                tmp.setBoolValue(streq(selected, p));
                var w = content.addChild("checkbox");
                w.node.setValues({"label"    : p ~ "  (" ~ type ~ ")",
                                  "halign"   : "left",
                                  "property" : tmp.getPath()});
                w.setBinding
                    ("nasal",
                     "MPCarriers.carrier_dialog.select_action(" ~
                     "\"" ~ type ~ "\", " ~ i ~ ");");
                i = i + 1;
            }
        }
    }
    me.dialog.addChild("hrule");

    # Display the dialog.
    fgcommand("dialog-new", me.dialog.prop());
    fgcommand("dialog-show", me.namenode);
}
############################################################
carrier_dialog.close = func {
    fgcommand("dialog-close", me.namenode);
}
############################################################
carrier_dialog.destroy = func {
    CARRIER_DLG = 0;
    me.close();
    foreach(var l; me.listeners)
        removelistener(l);
    delete(gui.dialog, "\"" ~ me.title ~ "\"");
}
############################################################
carrier_dialog.show = func {
#    print("Showing MPCarriers dialog!");
    if (!CARRIER_DLG) {
        CARRIER_DLG = int(getprop("/sim/time/elapsed-sec"));
        me.init();
        me.create();
        me._update_(CARRIER_DLG);
    }
}
############################################################
carrier_dialog._redraw_ = func {
    if (me.dialog != nil) {
        me.close();
        me.create();
    }
}
############################################################
carrier_dialog._update_ = func (id) {
    if (CARRIER_DLG != id) return;
    me._redraw_();
    settimer(func { me._update_(id); }, 4.1);
}
############################################################
carrier_dialog.select_action = func (type, n) {
    var base = me.basenode.getNode(type);
    var selected = me.basenode.getNode(me.carriers[type]).getValue();
    var bs = base.getChildren();
    # Assumption: There are two true b:s or none. The one not matching selected
    #             is the new selection.
    var i = 0;
    me.basenode.getNode(me.carriers[type], 1).setValue("");
    foreach (var b; bs) {
        if (!b.getValue() and (i == n)) {
            b.setValue(1);
            me.basenode.getNode(me.carriers[type]).setValue
                (me.players[type][i]);
        } else {
            b.setValue(0);
        }
        i = i + 1;
    }
    me._redraw_();
}
###############################################################################

var as_num = func (val, default=0.0) {
    return (typeof(val) == "scalar") ? val : default;
}

###############################################################################
# Overall initialization. Should only take place when the MPCarrier module is
# being loaded.

# Load the MPCarrier MP network.
if (!contains(globals, "MPCarriersNW")) {
  io.load_nasal(getprop("/sim/fg-root") ~
                "/Aircraft/MPCarrier/Systems/mp-network.nas",
                "MPCarriersNW");
  MPCarriersNW.mp_network_init(0);
}
