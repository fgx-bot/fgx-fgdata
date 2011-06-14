###############################################################################
##
##  A message based information broadcast for the multiplayer network.
##
##  Copyright (C) 2008 - 2011  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

###############################################################################
# Broadcast primitive using a MP enabled string property.
# Broadcasts from users in multiplayer.ignore are ignored.
#
# BroadcastChannel.new(mpp_path, process)
#   Create a new broadcast primitive. Any MP user with the same
#   primitive will receive all messages sent to the channel from the point
#   she/he joined (barring severe MP packet loss).
#   NOTE: Message delivery is not guaranteed.
#     mpp_path - MP property path                        : string
#     process  - handler called when receiving a message : func (n, msg)
#                n is the base node of the senders property tree
#                (i.e. /ai/models/multiplay[x])
#     send_to_self - if 1 locally sent messages are      : int {0,1}
#                    delivered just like remote messages.
#                    If 0 locally sent messages are not delivered
#                    to the local receiver.
#     accept_predicate - function to select which        : func (p)
#                        multiplayers to listen to.
#                        p is the multiplayer entry node.
#                        The default is to accept any multiplayer.
#     on_disconnect - function to be called when an      : func (p)
#                     accepted MP user leaves.
#     enable_send   - Set to 0 to disable sending.
#
# BroadcastChannel.send(msg)
#   Sends the message msg to the channel.
#     msg - text string with Binary data encoded data : string
#
# BroadcastChannel.die()
#   Destroy this BroadcastChannel instance.
#
var BroadcastChannel = {};
BroadcastChannel.new = func (mpp_path, process,
                             send_to_self = 0,
                             accept_predicate = nil,
                             on_disconnect = nil,
                             enable_send=1) {
  var obj = { parents      : [BroadcastChannel],
              mpp_path     : mpp_path,
              send_node    : enable_send ? props.globals.getNode(mpp_path, 1) 
                                         : nil,
              process_msg  : process,
              send_to_self : send_to_self,
              accept_predicate :
                (accept_predicate != nil) ? accept_predicate
                                          : func (p) { return 1; },
              on_disconnect : (on_disconnect != nil) ? on_disconnect
                                                     : func (p) { return; },
              # Internal state.
              send_buf     : [],
              peers        : {},
              loopid       : 0,
              PERIOD       : 1.3,
              last_time    : 0.0,  # For join handling.
              last_send    : 0.0,  # For the send queue 
              SEND_TIME    : 0.5 };
  if (enable_send and (obj.send_node == nil)) {
    printlog("warn",
             "BroadcastChannel invalid send node.");
    return nil;
  }
  obj.start();

  return obj;
}
BroadcastChannel.send = func (msg) {
  if (me.send_node == nil) return;

  var t = getprop("/sim/time/elapsed-sec");
  if (((t - me.last_send) > me.SEND_TIME) and (size(me.send_buf) == 0)) {
    me.send_node.setValue(msg);
    me.last_send = t;
    if (me.send_to_self) me.process_msg(props.globals, msg);
  } else {
    append(me.send_buf, msg);
  }  
}
BroadcastChannel.die = func {
  me.loopid += 1;
#  print("BroadcastChannel[" ~ me.mpp_path ~ "] ...  destroyed.");
}
BroadcastChannel.start = func {
  me.loopid += 1;
  settimer(func { me._loop_(me.loopid); }, 0, 1);
}
BroadcastChannel.stop = func {
  me.loopid += 1;
}

############################################################
# Internals.
BroadcastChannel.update = func {
  var t = getprop("/sim/time/elapsed-sec");
  var process_msg = me.process_msg;

  # Handled join/leave. This is done more seldom.
  if ((t - me.last_time) > me.PERIOD) {
    var mpplayers =
      props.globals.getNode("/ai/models").getChildren("multiplayer");
    foreach (var pilot; mpplayers) {
      var valid = pilot.getChild("valid");
      if ((valid != nil) and valid.getValue() and
          !contains(multiplayer.ignore,
                    pilot.getChild("callsign").getValue())) {
        if ((me.peers[pilot.getIndex()] == nil) and
            me.accept_predicate(pilot)) {
          me.peers[pilot.getIndex()] =
            MessageChannel.
            new(pilot.getNode(me.mpp_path),
                MessageChannel.new_message_handler(process_msg, pilot));
        }
      } else {
        if (contains(me.peers, pilot.getIndex())) {
          delete(me.peers, pilot.getIndex());
          me.on_disconnect(pilot);
        }
      }
    }
    me.last_time = t;
  }
  # Process new messages.
  foreach (var w; keys(me.peers)) {
    if (me.peers[w] != nil) me.peers[w].update();
  }
  # Check send buffer.
  if (me.send_node == nil) return;

  if ((t - me.last_send) > me.SEND_TIME) {
    if (size(me.send_buf) > 0) {
      me.send_node.setValue(me.send_buf[0]);
      if (me.send_to_self) me.process_msg(props.globals, me.send_buf[0]);
      me.send_buf = subvec(me.send_buf, 1);
      me.last_send = t;
    } else {
      # Nothing new to send. Reset the send property to save bandwidth.
      me.send_node.setValue("");
    }
  }
}
BroadcastChannel._loop_ = func(id) {
  id == me.loopid or return;
  me.update();
  settimer(func { me._loop_(id); }, 0, 1);
}
######################################################################

###############################################################################
# Some routines for encoding/decoding values into/from a string. 
# NOTE: MP is picky about what it sends in a string propery.
#       Encode 7 bits as a printable 8 bit character.
var Binary = {};
Binary.TWOTO31 = 2147483648;
Binary.TWOTO32 = 4294967296;
Binary.sizeOf = {};
############################################################
Binary.sizeOf["int"] = 5;
Binary.encodeInt = func (int) {
  var bf = bits.buf(5);
  if (int < 0) int += Binary.TWOTO32;
  var r = int;
  for (var i = 0; i < 5; i += 1) {
    var c = math.mod(r, 128);
    bf[4-i] = c + `A`;
    r = (r - c)/128;
  }
  return bf;
}
############################################################
Binary.decodeInt = func (str) {
  var v = 0;
  var b = 1;
  for (var i = 0; i < 5; i += 1) {
    v += (str[4-i] - `A`) * b;
    b *= 128;
  }
  if (v / Binary.TWOTO31 >= 1) v -= Binary.TWOTO32;
  return int(v);
}
############################################################
# NOTE: This encodes a 7 bit byte.
Binary.sizeOf["byte"] = 1;
Binary.encodeByte = func (int) {
  var bf = bits.buf(1);
  if (int < 0) int += 128;
  bf[0] = math.mod(int, 128) + `A`;
  return bf;
}
############################################################
Binary.decodeByte = func (str) {
  var v = str[0] - `A`;
  if (v / 64 >= 1) v -= 128;
  return int(v);
}
############################################################
# NOTE: This can neither handle huge values nor really tiny.
Binary.sizeOf["double"] = 2*Binary.sizeOf["int"];
Binary.encodeDouble = func (d) {
  return Binary.encodeInt(int(d)) ~
         Binary.encodeInt((d - int(d)) * Binary.TWOTO31);
}
############################################################
Binary.decodeDouble = func (str) {
  return Binary.decodeInt(substr(str, 0)) +
         Binary.decodeInt(substr(str, 5)) / Binary.TWOTO31;
}
############################################################
# Encodes a geo.Coord object.
Binary.sizeOf["Coord"] = 3*Binary.sizeOf["double"];
Binary.encodeCoord = func (coord) {
  return Binary.encodeDouble(coord.lat()) ~
         Binary.encodeDouble(coord.lon()) ~
         Binary.encodeDouble(coord.alt());
}
############################################################
# Decodes an encoded geo.Coord object.
Binary.decodeCoord = func (str) {
  var coord = geo.aircraft_position();
  coord.set_latlon(Binary.decodeDouble(substr(str, 0)),
                   Binary.decodeDouble(substr(str, 10)),
                   Binary.decodeDouble(substr(str, 20)));
  return coord;
}
######################################################################

###############################################################################
# Detects incomming messages encoded in a string property.
#   n       - MP source : property node
#   process - action    : func (v)
# NOTE: This is a low level component.
#       The same object is seldom used for both sending and receiving.
var MessageChannel = {};
MessageChannel.new = func (n = nil, process = nil) {
  var obj = { parents     : [MessageChannel],
              node        : n, 
              process_msg : process,
              old         : "" };
  return obj;
}
MessageChannel.update = func {
  if (me.node == nil) return;

  var msg = me.node.getValue();
  if (!streq(typeof(msg), "scalar")) return;

  if ((me.process_msg != nil) and
      !streq(msg, "") and
      !streq(msg, me.old)) {
    me.process_msg(msg);
    me.old = msg;
  }
}
MessageChannel.send = func (msg) {
  me.node.setValue(msg);
}
MessageChannel.new_message_handler = func (handler, arg1) {
  var local_arg1 = arg1; # Disconnect from future changes to arg1.
  return func (msg) { handler(local_arg1, msg) };
};
