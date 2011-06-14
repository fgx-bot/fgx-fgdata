#############################################################################
#
# Simple sequenced ATC background chatter function
#
# Written by Curtis Olson
# Started 8 Jan 2006.
#
#############################################################################

#############################################################################
# Global shared variables
#############################################################################

var fg_root = nil;
var chatter = "UK";
var chatter_dir = "";

var chatter_min_interval = 20.0;
var chatter_max_interval = 40.0;
var next_interval = nil;

var chatter_index = 0;
var chatter_size = 0;
var chatter_list = 0;


#############################################################################
# Chatter is initialized only when actually enabled. See listener connected
# to /sim/sound/chatter/enabled.
#############################################################################

var chatter_init = func {
    # default values
    fg_root = getprop("/sim/fg-root");
    chatter_dir = sprintf("%s/ATC/Chatter/%s", fg_root, chatter);
    chatter_list = directory( chatter_dir );
    chatter_size = size(chatter_list);
    # seed the random number generator (with time) so we don't start in
    # same place in the sequence each run.
    srand();
    chatter_index = int( chatter_size * rand() );
}


#############################################################################
# main update function to be called each frame
#############################################################################

var chatter_update = func {
    if ( chatter_index >= chatter_size ) {
        chatter_index = 0;
    }

    if ( substr(chatter_list[chatter_index],
                size(chatter_list[chatter_index]) - 4) == ".wav" )
    {	
	var vol =getprop("/sim/sound/chatter/volume");
	if(vol == nil){vol = 0.5;}
        tmpl = { path : chatter_dir, file : chatter_list[chatter_index] , volume : vol};
        if ( getprop("/sim/sound/chatter/enabled") ) {
            # go through the motions, but only schedule the message to play
            # if atc-chatter is enabled.
            printlog("info", "update atc chatter ", chatter_list[chatter_index] );
	    fgcommand("play-audio-sample", props.Node.new(tmpl) );
        }
    } else {
        # skip non-wav file found in directory
    }

    chatter_index = chatter_index + 1;
    nextChatter();
}


#############################################################################
# Use the nasal timer to update every 10 seconds
#############################################################################

var nextChatter = func {
    if (!getprop("/sim/sound/chatter/enabled"))
    {
      next_interval = nil;
      return;
    }

    # schedule next message in next min-max interval seconds so we have a bit
    # of a random pacing
    next_interval = chatter_min_interval
       + int(rand() * (chatter_max_interval - chatter_min_interval));

    # printlog("info", "next chatter in ", next_interval, " seconds");

    settimer(chatter_update, next_interval );
}

#############################################################################
# Start chatter processing. Also connected to chatter/enabled property as a
# listener.
#############################################################################

var startChatter = func {
  if ( getprop("/sim/sound/chatter/enabled") ) {
    if (fg_root == nil)
      chatter_init();
    if (next_interval == nil)
      nextChatter();
  }
}

# connect listener
_setlistener("/sim/sound/chatter/enabled", startChatter);

# start chatter immediately, if enable is already set.
settimer(startChatter, 0);

