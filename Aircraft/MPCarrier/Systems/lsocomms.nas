###-------------------------------------------------------------
# Locks the heading and pitch offsets to the 
# defined values

var LSOComms = {
    new: func() {
        var m = { parents: [LSOComms] };
        me.commentaryN = 
            props.globals.initNode("/sim/current-view/lso-commentary", 0, "BOOL");
        me.gearN = 
            props.globals.initNode("/sim/current-view/gear", 0, "DOUBLE");
        me.flapN = 
            props.globals.initNode("/sim/current-view/flap", 0, "DOUBLE");
        me.hookN = 
            props.globals.initNode("/sim/current-view/hook", 0, "DOUBLE");
        me.bearingN = 
            props.globals.initNode("/sim/current-view/bearing-deg", 0, "DOUBLE");
        props.globals.initNode("/sim/current-view/line-up", "", "STRING");
        props.globals.initNode("/sim/current-view/source", "", "STRING");

        me.height = ["", "high", "a little high", "on the glideslope",
            "a little low", "low", "very low"];
        me.lineup = ["", " You're lined up right", " You're on the centerline",
            " You're lined up left"];

        me.distance = nil;
        me.gear = 0;
        me.flap = 0;
        me.hook = 0;
        me.commentaryN.setValue(1);
        me.message = nil;
        print("... lso comms initialized");
        return me;
    },
    reset: func {
        me.distance = nil;
        me.gear = 0;
        me.flap = 0;
        me.hook = 0;
        setprop("/sim/current-view/line-up","");

        foreach (var c; props.globals.getNode("/ai/models").getChildren("carrier")){
            c.getNode("controls/flols/wave-off-lights",1).setValue(0);
        }

#	print("comms reset");
    },
    update: func (callsign, distance, elevation, rel_brg) {
    
        if(callsign == nil or distance == nil or elevation == nil or rel_brg == nil
            or callsign == "") return;
        
#		print("updating lso comms ... ", callsign,
#			" dist", distance, 
#			" dist old", me.distance,
#			" elev ", elevation, 
#			);

        var source = 0;
        var lineup = 0;

        if(distance <= 2 ){
            source = me.get_source(elevation);
            lineup = me.get_lineup(rel_brg);
        }

        var message = "";
        var warn = reason = "";
        var gear = gear2= "";
        var flap = flap2 = "";
        var hook = "";

        me.gear = me.gearN.getValue();
        if (me.gear == nil) me.gear = 0;
        me.flap = me.flapN.getValue();
        me.hook = me.hookN.getValue();

        if (me.distance != nil ){

#			print ("updating comms ", callsign,
#				" dist ", distance,
#				" old dist ", me.distance,
#				" dist diff ", distance - me.distance,);

            if (me.gear < 3){
                gear = " Drop your gear";
                gear2 = " NO GEAR";
            }

            if (me.flap != nil and me.flap < 1){
                flap = " Drop your flaps";
                flap2 = " NO FLAPS";
            }

            if (me.hook != nil and me.hook < 1) hook = " drop your hook";

            if (gear != "" or flap != "" or hook != ""){
                warn = gear ~ flap ~ hook;
                reason = gear2 ~ flap2;
            }

            if (distance > 4 or distance > me.distance){
                me.reset();
            } elsif (distance < 3.15 and distance >=3.0 ){
                var bearing = sprintf("%03d", me.bearingN.getValue());

                if (bearing == nil)
                    message = 
                        callsign ~ ": " ~ "3 Miles";
                else
                    message = 
                        callsign ~ ": " ~ "3 Miles bearing " ~ bearing;

            } elsif (distance < 2.15 and distance >=2.0 ){
                var course = sprintf("%03d",getprop("/orientation/true-heading-deg"));
                message = 
                    callsign ~ ": " ~ "2 Miles" ~ warn ~ " flying course " ~ course
                    ~ me.lineup[lineup];
            } elsif (distance < 1.15 and distance >=1.0 ){
                message = 
                    callsign ~ ": " ~ "1 Mile call the ball" ~ warn;
            } elsif (distance < 0.6 and distance >=0.5 
                    and reason != "" ){
                message = 
                    callsign ~ ": " ~ "WAVEOFF WAVEOFF" ~ reason;

                foreach (var c; props.globals.getNode("/ai/models").getChildren("carrier")){
                    c.getNode("controls/flols/wave-off-lights",1).setValue(1);
                }

            } elsif (distance < 1.0 and distance >=0.08
                and me.height[source] != ""){

                if (distance < 0.5 and source == 6)
                    message = 
                        callsign ~ ": You're " ~ me.height[source] ~ " POWER";
                else
                    message = 
                        callsign ~ ": You're " ~ me.height[source] ~ me.lineup[lineup]; 
            }

            if (message != ""){

                if (message != me.message)
                    setprop("/sim/messages/approach", message);

                me.message = message;
            }

        }

        me.distance = distance;

        return;

    },
get_source: func (elevation) {
    var source= 0;

        if ( elevation <= 4.35 and elevation > 4.01 )
            source = 1;
        elsif ( elevation <= 4.01 and elevation > 3.670 )
            source = 2;
        elsif ( elevation <= 3.670 and elevation > 3.330 )
            source = 3;
        elsif ( elevation <= 3.330 and elevation > 2.990 )
            source = 4;
        elsif ( elevation <= 2.990 and elevation > 2.650 )
            source = 5;
        elsif ( elevation <= 2.650 )
            source = 6;
        else
            source = 0;

    setprop("/sim/current-view/height",
            me.height[source]);
    return source;
    },
    get_lineup: func (rel_bearing) {
        var lineup = 0;

        if ( rel_bearing < -1.5 and rel_bearing > -25 )
            lineup = 1;
        elsif ( rel_bearing >= -1.5 and rel_bearing <= 1.5 )
            lineup = 2;
        elsif ( rel_bearing > 1.5 and rel_bearing < 25 )
            lineup = 3;
        else
            lineup = 0;

    setprop("/sim/current-view/line-up",
            me.lineup[lineup]);
    return lineup;
    },
};

