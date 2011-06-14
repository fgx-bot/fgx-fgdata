var model_cockpit_view_handler = {
init : func {
    me.models = {};
    me.list = [];
    me.current = 0;
    me.active = 0;
    me.dialog = props.Node.new({ "dialog-name": "model-cockpit-view" });
       },
start : func {
       me.models = {};
       var ai = props.globals.getNode("/ai/models", 1);
       foreach (var m; [props.globals]
       ~ ai.getChildren("wingman"))
           me.models[m.getPath()] = m;

       me.lnr = [];
#	   append(me.lnr, setlistener("/ai/models/model-added", func(n) {
#		   var m = props.globals.getNode(n.getValue(), 1);
#		   me.models[m.getPath()] = m;
#	   }));
#	   append(me.lnr, setlistener("/ai/models/model-removed", func(n) {
#		   var m = props.globals.getNode(n.getValue(), 1);
#		   delete(me.models, m.getPath());
#	   }));
       append(me.lnr, setlistener("/devices/status/mice/mouse/mode", func(n) {
           me.mouse_mode = n.getValue();
       }, 1));
       append(me.lnr, setlistener("/devices/status/mice/mouse/button", func(n) {
           me.mouse_button = n.getValue();
           if (me.mouse_button == 1)
               me.mouse_start = me.mouse_y;
       }, 1));
       append(me.lnr, setlistener("/devices/status/mice/mouse/y", func(n) {
           me.mouse_y = n.getValue();
       }, 1));
       me.offs = 0;
       me.active = 1;
       me.reset();
       fgcommand("dialog-show", me.dialog);
       },
update : func {
       if (me.mouse_mode == 0 and me.mouse_button) { 

           var curr = 0;
           var n = me.models[me.list[me.current]];
           var type = n.getName();
           var name = nil;

           curr = getprop("/sim/current-view/z-offset-m") - me.offs;
           me.offs += me.mouse_y - me.mouse_start;
           var new = curr + me.offs;

           if (type != "wingman"){

               if (new < -5)
                   new = -5;

           } 

           setprop("/sim/current-view/z-offset-m", new);
           me.mouse_start = me.mouse_y;
       }
       return 0;
       },
stop : func {
       fgcommand("dialog-close", me.dialog);
       me.active = 0;
       foreach (var listener; me.lnr)
           removelistener(listener);
       },
reset : func {
       me.next(me.current = 0);
       },
next : func(v) {
       if (!me.active or !size(me.models))
           return;
       if (v)
           me.current += v;
       else
           me.current = 0;

       me.list = sort(keys(me.models), cmp);
       if (me.current < 0)
           me.current = size(me.list) - 1;
       elsif (me.current >= size(me.list))
           me.current = 0;

       var c = me.list[me.current];
       var s = "/sim/view[197]/config";
       setprop(s, "eye-lat-deg-path", c ~ "/position/latitude-deg");
       setprop(s, "eye-lon-deg-path", c ~ "/position/longitude-deg");
       setprop(s, "eye-alt-ft-path", c ~ "/position/altitude-ft");
       setprop(s, "eye-heading-deg-path", c ~ "/orientation/true-heading-deg");
       setprop(s, "eye-pitch-deg-path", c ~ "/orientation/pitch-deg");
       setprop(s, "eye-roll-deg-path", c ~ "/orientation/roll-deg");

       var n = me.models[me.list[me.current]];
       var type = n.getName();
       var name = nil;
       var z = 0;

       if (type == "") {
           z = getprop("/sim/chase-distance-m");
           if (name = getprop("/sim/multiplay/callsign"))
               name = 'callsign "' ~ name ~ '"';
       } else {
           if ((name = n.getNode("name")) != nil and (name = name.getValue()))
               name = n.getName() ~ ' "' ~ name ~ '"';
       }

       var color = {};
       if (type != "multiplayer")
           color = { text: { color: { red: 0.5, green: 0.8, blue: 0.5 }}};

       if (type != "wingman" and getprop("/sim/current-view/view-number") == 8  )
           setprop("/sim/current-view/z-offset-m", me.offs = z);

       if (type == "wingman" and getprop("/sim/current-view/view-number") == 8){
           setprop("/sim/current-view/x-offset-m", 0.0);
           setprop("/sim/current-view/y-offset-m", 0.65);
           setprop("/sim/current-view/z-offset-m", me.offs = -3.15);
           setprop("/sim/current-view/pitch-offset-deg", -20);
#          print("model cockpit view stuff");
       }

       if (name){
           setprop("/sim/current-view/model-cockpit-view", name);
       }
       },
};

setlistener("/sim/signals/fdm-initialized", func {
    view.manager.register("Model Cockpit View", model_cockpit_view_handler);
    print ("Model Cockpit View registered");
});