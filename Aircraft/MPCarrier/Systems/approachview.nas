
###-------------------------------------------------------------
# Locks the heading and pitch offsets to the 
# defined values

var app_view_handler = {
    init: func (node) {
        print("initializing app view ... ");
        me.viewN = node;
        me.dialog = props.Node.new({ "dialog-name": "app-view" });
        me.legendN = 
            props.globals.initNode("/sim/current-view/approach-view", "");
        me.commentaryN = 
            props.globals.initNode("/sim/current-view/lso-commentary", 0, "BOOL");
        me.gearN = 
            props.globals.initNode("/sim/current-view/gear", 0, "DOUBLE");
        props.globals.initNode("/sim/current-view/heading-offset-rel-deg", 0, "DOUBLE");
        props.globals.initNode("/sim/current-view/rel-bearing-deg", 0, "DOUBLE");
        props.globals.initNode("/sim/current-view/bearing-deg", 0, "DOUBLE");
        props.globals.initNode("/sim/current-view/callsign", "", "STRING");
        props.globals.initNode("/sim/controls/radar", 0, "BOOL");

        me.callsign = "";
        me.distance = 0;
        me.elevation = 0;
        me.comms = nil;
        me.current = nil;
        me.source = nil;
        me.lineup = nil;
    },
    start: func {
        print ("app view starting");
        me.comms = LSOComms.LSOComms.new();
        me.listener = setlistener("/sim/signals/multiplayer-updated",
            func me._update_(), 1);
        me.listener2 = setlistener("/sim/current-view/lso-commentary",
            func me.commentary(), 0);
        multiplayer.model.update();
        me.commentaryN.setValue(1);
        me.reset();
    },
    stop: func {
        me.commentaryN.setValue(0);
        removelistener(me.listener);
        me.comms.reset();
        setprop("/sim/current-view/gear", 0);
        setprop("/sim/current-view/flap", 0); 
        setprop("/sim/current-view/hook", 0);
        removelistener(me.listener2);
    },
    reset: func {
        me.select(0);
    },
    find: func(callsign) {
        forindex (var i; me.list)
            if (me.list[i].callsign == callsign)
                return i;
        return nil;
    },
    select: func(which) {
        if (num(which) == nil)
            which = me.find(which) or 0;  # turn callsign into index

        me.setup(me.list[which]);
    },
    next: func(step) {
        var i = me.find(me.current);
        i = i == nil ? 0 : math.mod(i + step, size(me.list));
        me.setup(me.list[i]);
    },
    _update_: func {
        var self = { callsign: getprop("/sim/multiplay/callsign"), model:,
                node: props.globals, root: '/' };
        me.list = [self] ~ multiplayer.model.list;
        if (!me.find(me.current))
            me.select(0);
    },
    update: func {
        setprop("/sim/current-view/heading-offset-deg",188.5);
        setprop("/sim/current-view/pitch-offset-deg", 3.5);
        setprop("/sim/current-view/roll-offset-deg", 0);
        setprop("/sim/current-view/field-of-view", 25);
        setprop("/sim/controls/radar", 0);

        var view_x = getprop("sim/current-view/viewer-x-m");
        var view_y = getprop("sim/current-view/viewer-y-m");
        var view_z = getprop("sim/current-view/viewer-z-m");
        var self = geo.Coord.new().set_xyz(view_x, view_y, view_z);

        var heading = getprop("/orientation/heading-deg");

        foreach (var mp; multiplayer.model.list) {
            var n = mp.node;
            var x = n.getNode("position/global-x").getValue();
            var y = n.getNode("position/global-y").getValue();
            var z = n.getNode("position/global-z").getValue();
            var ac = geo.Coord.new().set_xyz(x, y, z);
            var range = self.distance_to(ac);

            var ht_ft = n.getNode("position/altitude-ft").getValue();
            var height = getprop("sim/current-view/y-offset-m") * M2FT;
            var elevation = math.atan2((ht_ft - height)* FT2M, range) * R2D;

            var bearing = self.course_to(ac);
            var rel_bearing = bearing - heading;

            if (rel_bearing < 0) rel_bearing += 360;

            n.getNode("radar/range-nm",1).setValue(range * M2NM);
            n.getNode("radar/bearing-deg",1).setValue(bearing);
            n.getNode("radar/bearing-rel-deg",1).setValue(rel_bearing);
            n.getNode("radar/elevation-deg",1).setValue(elevation);
            var rel_brg_deg = n.getNode("radar/elevation-deg",1).getValue();

            if(range * M2NM <= 8 and range > 0 
                and rel_brg_deg > -50 and rel_brg_deg < 50) {
                me.distance = range * M2NM;
                me.elevation = elevation;
                me.callsign = n.getNode("callsign").getValue();
                var bearing_from = sprintf( "%03d", ac.course_to(self));

                var gear_0 = n.getNode("gear/gear/position-norm").getValue();
                var gear_1 = n.getNode("gear/gear[1]/position-norm").getValue();
                var gear_2 = n.getNode("gear/gear[2]/position-norm").getValue();

                if (gear_0 == nil) gear_0 = 0;
                if (gear_1 == nil) gear_1 = 0;
                if (gear_2 == nil) gear_2 = 0;

                me.gear = gear_0 + gear_1 + gear_2;
                me.flap = n.getNode("surface-positions/flap-pos-norm").getValue();
                me.hook = n.getNode("gear/tailhook/position-norm").getValue();

                if (!me.hook) me.hook = 0;
                if (!me.flap) me.flap = 0;

                var h_offset = getprop("/sim/current-view/heading-offset-rel-deg");
                var v_offset = getprop("/sim/current-view/pitch-offset-deg");

                n.getNode("radar/h-offset",1).setValue(rel_bearing - h_offset);
                n.getNode("radar/v-offset",1).setValue(me.elevation - v_offset);

                setprop("/sim/current-view/gear", me.gear);
                setprop("/sim/current-view/flap", me.flap); 
                setprop("/sim/current-view/hook", me.hook);
                setprop("/sim/current-view/callsign", me.callsign);
                setprop("/sim/current-view/bearing-deg", bearing_from);
                setprop("/sim/current-view/distance", me.distance);
                setprop("/sim/current-view/rel-bearing-deg", rel_bearing - h_offset); 
                setprop("/sim/current-view/elevation", me.elevation); 

                var source = me.comms.get_source(me.elevation);
                var rel_lineup = rel_bearing - h_offset;
                var lineup = me.comms.get_lineup(rel_lineup);

                if (me.source != source or me.lineup != lineup){
                    me.commentary();
                }

                me.source = source;
                me.lineup = lineup;
            } else {
                n.getNode("radar/h-offset",1).setValue(0);
                n.getNode("radar/v-offset",1).setValue(0);
            }

        }
        return 0;
    },
    commentary: func() {
        var commentary = getprop("/sim/current-view/lso-commentary");
        var rel_brg = getprop("/sim/current-view/rel-bearing-deg");

        if (!commentary){
            print("Commentary OFF");
            return;
        } elsif (me.distance <=4 and me.distance > 1
            and rel_brg > -50 and rel_brg < 50 and me.callsign != ""){
            me.comms.update(me.callsign, me.distance, me.elevation, rel_brg);
            settimer(func { me.commentary() }, 20);
        } elsif (me.distance <= 1 and me.distance > 0.05
            and rel_brg > -50 and rel_brg < 50 and me.callsign != ""){
            me.comms.update(me.callsign, me.distance, me.elevation, rel_brg);
            settimer(func { me.commentary() }, 10);
        } else {
            me.comms.reset();
            settimer(func { me.commentary() }, 20);
        }
        
    },
    setup: func(data) {
    if (data.root == '/') {
        var ident = '[' ~ data.callsign ~ ']';
    } else {
        var ident = '"' ~ data.callsign ~ '" (' ~ data.model ~ ')';
    }

#	me.current = data.callsign;
#	me.legendN.setValue(ident);

    setprop("/sim/current-view/heading-offset-deg", 188.5);
    setprop("/sim/current-view/pitch-offset-deg", 3.5);
    setprop("/sim/current-view/roll-offset-deg", 0);
    setprop("/sim/current-view/field-of-view", 25);
    setprop("/sim/controls/radar", 0);

    me.viewN.getNode("config").setValues({
        "eye-lat-deg-path":"/" ~ "/position/latitude-deg",
        "eye-lon-deg-path": "/" ~"/position/longitude-deg",
        "eye-alt-ft-path": "/" ~ "/position/altitude-ft",
        "eye-heading-deg-path": "/" ~ "/orientation/heading-deg",
        "target-lon-deg-path": data.root ~ "/position/longitude-deg",
        "target-alt-ft-path": data.root ~ "/position/altitude-ft",
        "target-heading-deg-path": data.root ~ "/orientation/heading-deg",
        "target-pitch-deg-path": data.root ~ "/orientation/pitch-deg",
        "target-roll-deg-path": data.root ~ "/orientation/roll-deg",
    });
    },
};

setlistener("sim/signals/fdm-initialized", func {
    view.manager.register("Approach View", app_view_handler);
    print("... app view registered");
});

###-------------------------------------------------------------
# This utility converts the input angle into a relative bearing
# using the convention of +ve bearing = starboard, -ve = port
#

props.globals.initNode("/sim/current-view/heading-offset-rel-deg", 0, "DOUBLE");

setlistener("/sim/signals/nasal-dir-initialized", func {
    setlistener("/sim/current-view/heading-offset-deg", func(n) {
        var heading_offset_deg = n.getValue();
        if (heading_offset_deg >= 180){
            setprop("/sim/current-view/heading-offset-rel-deg", 
                heading_offset_deg * -1 + 360);
        } else {
            setprop("/sim/current-view/heading-offset-rel-deg",
                heading_offset_deg * -1);
        }
    });
},1);

