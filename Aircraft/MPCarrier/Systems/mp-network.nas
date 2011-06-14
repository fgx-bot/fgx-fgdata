###############################################################################
##
## MPCarrier multiplayer message network.
##
##  Copyright (C) 2009 - 2011  Anders Gidenstam  (anders(at)gidenstam.org)
##  Copyright (C) 2009  Vivian Meazza
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

var Binary = nil;
var broadcast = nil;
var message_id = nil;

var Manager_instances = {};

var get_carrier = func (pilot) {
  if (contains(Manager_instances, pilot.getIndex())) {
      return Manager_instances[pilot.getIndex()];
  }
  print("Error: " ~ pilot.getPath() ~ " is not a recognized MPCarrier.");
  return nil;
}

###############################################################################
# Send message wrappers.
var send_elevator_state = func (state) {
    if (typeof(broadcast) != "hash") return;
    broadcast.send(message_id["elevator_state"] ~
                   Binary.encodeByte(state));
}
var send_decklight_state = func (state) {
    if (typeof(broadcast) != "hash") return;
    broadcast.send(message_id["decklight_state"] ~
                   Binary.encodeByte(state));
}
var send_floodlight_state = func (state) {
    if (typeof(broadcast) != "hash") return;
    broadcast.send(message_id["floodlight_state"] ~
                   Binary.encodeDouble(state));
}
var send_launch_state = func (state) {
    if (typeof(broadcast) != "hash") return;
    broadcast.send(message_id["launch_state"] ~
                   Binary.encodeDouble(state));
}
var send_recovery_state = func (state) {
    if (typeof(broadcast) != "hash") return;
    broadcast.send(message_id["recovery_state"] ~
                   Binary.encodeDouble(state));
}
var send_base_state = func (state) {
    if (typeof(broadcast) != "hash") return;
    broadcast.send(message_id["base_state"] ~
                   Binary.encodeDouble(state));
}

var send_wave_off_lights_state = func (state) {
    if (typeof(broadcast) != "hash") return;
    broadcast.send(message_id["wave_off_state"] ~
                   Binary.encodeDouble(state));
}
###############################################################################
# MP broadcast message handler.
var handle_message = func (sender, msg) {
#    print("Message from "~ sender.getNode("callsign").getValue() ~
#          " size: " ~ size(msg));
#    debug.dump(msg);
    var type    = msg[0];
    var carrier = get_carrier(sender);
    if (carrier == nil) return;

    if (type == message_id["elevator_state"][0]) {
        #print("MPCarrier: Elevator state");
        var state =
            Binary.decodeByte(substr(msg, 1));
        #debug.dump(state);
        carrier.set_property(MPCarriers.c_deck_elev, state);
    } else if (type == message_id["decklight_state"][0]) {
        #print("MPCarrier: Deck light state");
        var state =
            Binary.decodeByte(substr(msg, 1));
        #debug.dump(state);
        carrier.set_property(MPCarriers.c_deck_lights, state);
    } else if (type == message_id["floodlight_state"][0]) {
        #print("MPCarrier: Flood light state");
        var state =
            Binary.decodeDouble(substr(msg, 1));
        #debug.dump(state);
        carrier.set_property(MPCarriers.c_flood_lights, state);
    } else if (type == message_id["launch_state"][0]) {
        #print("MPCarrier: launch state");
        var state =
            Binary.decodeDouble(substr(msg, 1));
        #debug.dump(state);
        carrier.set_property(MPCarriers.c_turn_to_launch_hdg, state);
    } else if (type == message_id["recovery_state"][0]) {
        #print("MPCarrier: recovery state");
        var state =
            Binary.decodeDouble(substr(msg, 1));
        #debug.dump(state);
        carrier.set_property(MPCarriers.c_turn_to_recvry_hdg, state);
    } else if (type == message_id["base_state"][0]) {
        #print("MPCarrier: base state");
        var state =
            Binary.decodeDouble(substr(msg, 1));
        #debug.dump(state);
        carrier.set_property(MPCarriers.c_turn_to_base_co, state);
    } else if (type == message_id["wave_off_state"][0]) {
#       print("MPCarrier: wave off state");
        var state =
            Binary.decodeDouble(substr(msg, 1));
        #debug.dump(state);
        carrier.set_property(MPCarriers.c_wave_off_lights, state);
    }
}

###############################################################################
# MP Accept and disconnect handlers.
var listen_to = func (pilot) {
  if (contains(Manager_instances, pilot.getIndex())) {
#    print("Accepted " ~ pilot.getPath());
    return 1;
  }
  return 0;
}

var when_disconnecting = func (pilot) {
    # Do nothing - MPCarrier handles this.
}

###############################################################################
# Initialization.
var mp_network_init = func (active_participant=0) {
    Binary = mp_broadcast.Binary;
    broadcast =
        mp_broadcast.BroadcastChannel.new
            ("sim/multiplay/generic/string[0]",
             handle_message,
             0,
             listen_to,
             when_disconnecting,
             active_participant);
    # Set up the recognized message types.
    message_id = { elevator_state   : Binary.encodeByte(1),
                   decklight_state  : Binary.encodeByte(2),
                   floodlight_state : Binary.encodeByte(3),
                   launch_state     : Binary.encodeByte(4),
                   recovery_state   : Binary.encodeByte(5),
                   base_state       : Binary.encodeByte(6),
                   wave_off_state   : Binary.encodeByte(7),
                 };
}
