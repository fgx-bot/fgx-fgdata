var lso_view_handler = {
    init: func(node) {
        me.viewN = node;
        me.current = getprop("/sim/current-view/callsign", nil);
        me.legendN = 
            props.globals.initNode("/sim/current-view/landing-signal-officer-view", "");
        me.commentaryN = 
            props.globals.initNode("/sim/current-view/lso-commentary", 0, "BOOL");
        me.gearN = 
            props.globals.initNode("/sim/current-view/gear", 0, "DOUBLE");
        me.dialog = props.Node.new({ "dialog-name": "lso-view" });
#		me.height = ["", "HIGH", "A LITTLE HIGH", "ON THE GLIDESLOPE", "A LITTLE LOW",
#			"LOW", "VERY LOW"];

        me.distance = 0;
        me.gear = 0;
        me.flap = 0;
        me.hook = 0;
        me.bearing = 0;
        me.comms = nil;
        me.elevation = 0;
        me.source = nil;
        me.lineup = nil;
        me.rel_lineup = nil;

        print("... lso view initialized");
    },
    start: func {
        me.comms = LSOComms.LSOComms.new();
        me.listener = setlistener("/sim/signals/multiplayer-updated",
            func me._update_(), 1);
        me.listener2 = setlistener("/sim/current-view/lso-commentary",
            func me.commentary(), 0);
        me.reset();
        me.commentaryN.setValue(1);
        multiplayer.model.update();
        fgcommand("dialog-show", me.dialog);
    },
    stop: func {
        fgcommand("dialog-close", me.dialog);
        me.commentaryN.setValue(0);
        removelistener(me.listener);
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
        var view_x = getprop("sim/current-view/viewer-x-m");
        var view_y = getprop("sim/current-view/viewer-y-m");
        var view_z = getprop("sim/current-view/viewer-z-m");
        var self = geo.Coord.new().set_xyz(view_x, view_y, view_z);
        var target_callsign = me.current;
        var heading = getprop("/orientation/heading-deg");

        foreach (var mp; multiplayer.model.list) {
            var n = mp.node;
            var callsign = n.getNode("callsign").getValue();

            if(callsign == target_callsign){
                var x = n.getNode("position/global-x").getValue();
                var y = n.getNode("position/global-y").getValue();
                var z = n.getNode("position/global-z").getValue();
                var ac = geo.Coord.new().set_xyz(x, y, z);
                var ht_ft = n.getNode("position/altitude-ft").getValue();
                var height = getprop("sim/current-view/y-offset-m") * M2FT;
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

                var range = self.distance_to(ac);
                me.elevation = math.atan2((ht_ft - height)* FT2M, range) * R2D;
                var hdg_offset = heading - self.course_to(ac);
                me.bearing = sprintf ( "%03d", ac.course_to(self));
                me.distance = range * M2NM;

                if (hdg_offset < 0) hdg_offset += 360;

                var source = 0;
                var lineup = 0;

                if(hdg_offset >= 8.5)
                    me.rel_lineup = (hdg_offset - 180 - 8.5) * -1;
                else
                    me.rel_lineup = (hdg_offset + 180 - 8.5) * -1;

                if(me.distance <= 8 and me.distance > 0){
                    source = me.comms.get_source(me.elevation);
                    lineup = me.comms.get_lineup(me.rel_lineup);
                }

                setprop("/sim/current-view/distance",
                    me.distance);
                setprop("/sim/current-view/gear",
                    me.gear);
                setprop("/sim/current-view/flap",
                    me.flap); 
                setprop("/sim/current-view/hook",
                    me.hook);
                setprop("/sim/current-view/pitch-offset-deg",
                    me.elevation);
                setprop("/sim/current-view/heading-offset-deg",
                    hdg_offset);
                setprop("/sim/current-view/bearing-deg",
                    me.bearing);
                setprop("/sim/current-view/callsign",
                    me.current);
                setprop("/sim/current-view/line-up-deg", 
                    me.rel_lineup); 

                if (me.source != source or me.lineup != lineup){
                    me.commentary();
                }

                me.source = source;
                me.lineup = lineup;
            }

        }

        return 0
    },
    commentary: func() {
        var commentary = getprop("/sim/current-view/lso-commentary");

        if (!commentary){
            print("Commentary OFF");
            return;
        } else {
            var rel_brg = getprop("/sim/current-view/heading-offset-rel-deg");

            if (me.distance == nil or rel_brg == nil) return;

            if (me.distance < 8 and me.distance > 1 
                or rel_brg <= -138 or rel_brg >= 122){
                    me.comms.update(me.current, me.distance, 
                        me.elevation, me.rel_lineup);
                    settimer(func { me.commentary() }, 20);
            } elsif (me.distance <= 1 or rel_brg <= -138 or rel_brg >= 122){
                me.comms.update(me.current, me.distance, 
                    me.elevation, me.rel_lineup);
                settimer(func { me.commentary() }, 10);
            } else {
                me.comms.reset();
                settimer(func { me.commentary() }, 20);
            }

        }
        
    },
    setup: func(data) {
        if (data.root == '/') {
            var ident = '[' ~ data.callsign ~ ']';
        } else {
            var ident = '"' ~ data.callsign ~ '" (' ~ data.model ~ ')';
        }

        me.current = data.callsign;
        me.legendN.setValue(ident);

        setprop("/sim/current-view/x-offset-m",-19.7208);
        setprop("/sim/current-view/y-offset-m",21.925);
        setprop("/sim/current-view/z-offset-m",175.307);
        setprop("/sim/current-view/default-field-of-view-deg",25);

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
    view.manager.register("Landing Signal Officer View", lso_view_handler);
    print("lsoview registered");
});