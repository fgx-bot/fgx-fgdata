####    Player Mode ATC ####
####  Syd Adams , Csaba Halász  ####

var ATC = {
    new : func(){
        m = { parents : [ATC] };
        m.AP=nil;
        m.Tower_lat = props.globals.initNode("/sim/tower/latitude-deg");
        m.Tower_lon = props.globals.initNode("/sim/tower/longitude-deg");
        m.Tower_alt = props.globals.initNode("/sim/tower/altitude-ft");
        m.Tower_id = props.globals.initNode("/sim/tower/airport-id");
        m.ATC_lat = props.globals.initNode("position/latitude-deg");
        m.ATC_lon = props.globals.initNode("position/longitude-deg");
        m.ATC_alt = props.globals.initNode("position/altitude-ft");
        m.ATC_heading = props.globals.initNode("orientation/heading-deg");
        m.ATC_pitch = props.globals.initNode("orientation/pitch-deg");
        m.ATC_roll = props.globals.initNode("orientation/roll-deg");
        m.ATC_fov = props.globals.initNode("sim/current-view/field-of-view");
        m.ATC_offset_x = props.globals.initNode("sim/current-view/x-offset-m");
        m.ATC_offset_y = props.globals.initNode("sim/current-view/y-offset-m");
        m.ATC_offset_z = props.globals.initNode("sim/current-view/z-offset-m");
        m.ATC_target_brg = props.globals.initNode("sim/current-view/goal-heading-offset-deg");
        m.ATC_target_pitch = props.globals.initNode("sim/current-view/goal-pitch-offset-deg");
        m.ATC_wind = props.globals.initNode("sim/atc/wind-from",0,"DOUBLE");
        m.ATC_target_tracking = props.globals.initNode("sim/atc/tracking",1,"BOOL");
        m.ATC_target_id = props.globals.initNode("sim/atc/target-id"," ","STRING");
        m.ATC_target_alt = props.globals.initNode("sim/atc/target-alt",0.0,"DOUBLE");
        m.ATC_target_range = props.globals.initNode("sim/atc/target-range",0.0,"DOUBLE");
        m.ATC_target_speed = props.globals.initNode("sim/atc/target-kt",0.0,"DOUBLE");
        m.ATC_target_hdg = props.globals.initNode("/sim/atc/target-hdg",0.0,"DOUBLE");
        m.ATC_runways = props.globals.initNode("/sim/atc/runways-enabled",1,"BOOL");
        m.ATC_rangering = props.globals.initNode("/sim/atc/compass",1,"BOOL");
        m.ATC_mag_display = props.globals.initNode("/sim/atc/mag-compass",1,"BOOL");
        m.ATC_text = props.globals.initNode("/sim/atc/screen-text",1,"BOOL");
        m.ATC_num =props.globals.initNode("sim/atc/target-number",0."INT");
        m.ATC_panel_visibility = props.globals.initNode("sim/panel/visibility", 1,"BOOL");
        m.ATC_carrier = props.globals.initNode("/sim/atc/carrier",0,"INT");
        m.RADAR_range =props.globals.initNode("instrumentation/radar/range");
        m.RADAR_id =props.globals.initNode("instrumentation/radar/selected-id");
        m.RADAR_rotate =props.globals.initNode("instrumentation/radar/display-controls/rotate",1,"BOOL");
        m.mag_offset = 0;
        m.follow = m.ATC_target_tracking.getValue();

        m.towerL=setlistener("/sim/tower/airport-id", func m.do_init(),0,0);
        m.towerAitL=setlistener("/sim/tower/altitude-ft", func m.do_init(),0,0);
        m.magL=setlistener(m.ATC_mag_display,func m.magswap(),1);
        return m;
    },

#### carrier position###########

    c_update:func(cn) {
            var lat=0;
            var lon=0;
        if(cn==1){
            lat=getprop("ai/models/carrier[0]/position/latitude-deg");
            lon=getprop("ai/models/carrier[0]/position/longitude-deg");
        }elsif(cn==2){
            lat=getprop("ai/models/carrier[1]/position/latitude-deg");
            lon=getprop("ai/models/carrier[1]/position/longitude-deg");
        }
        me.ATC_lat.setValue(lat);
        me.ATC_lon.setValue(lon);
        me.ATC_alt.setValue(me.Tower_alt.getValue());
        me.Tower_lat.setValue(lat);
        me.Tower_lon.setValue(lon);
    },

#### carrier ###########

    goto_carrier:func(num) {
        if(num==0){
            me.Tower_id.setValue("NMTZ_C");
            me.Tower_alt.setValue(250);
        }elsif(num==1){
            me.Tower_id.setValue("EZHR_C");
            me.Tower_alt.setValue(250);
        };
    },

#### wind ###########

    wind_check:func {
        oldwind = me.ATC_wind.getValue();
        wind =getprop("environment/wind-from-heading-deg");
        if(me.ATC_mag_display.getValue()){
        wind=wind-me.mag_offset;
        if(wind <0)wind=wind+360;
        }
        me.ATC_wind.setValue(wind);
	if(wind==oldwind) return 0;
	else return 1;
    },

#### wrap ###########

    add_with_wrap:func(value, step, limit) {
        value += step;
        if (value < 0) value = limit - 1;
        if (value >= limit) value = 0;
        return value;
    },

#### adjust tower alt ###########

    adjust_alt:func(ht) {
        var twr=me.Tower_alt.getValue();
        twr=twr+ht;
        me.Tower_alt.setValue(twr);
},

#### adjust view ###########
# adjust view so that it is centered at the given position 
# position 0 is center, position 1 is edge

    adjust_view:func(fov, position) {
    return me.ATC_panel_visibility.getValue() ? math.atan2(tan(fov * 0.00872665) * position, 1) * R2D : 0;
},

#### mag toggle ###########

     magswap:func() {
        var tmpmag=0;
        if(me.ATC_mag_display.getValue()){
            tmpmag=me.mag_offset;
            if(tmpmag<0)tmpmag+=360;
        }
    me.ATC_heading.setValue(tmpmag);
},

#### toggle tracking ###########

    toggle_tracking: func() {
    me.follow = !me.follow;
    me.ATC_target_tracking.setValue(me.follow);
},
#### target valid ###########

    is_valid_target:func(target) {
        return target.getNode("valid").getValue() and target.getNode("radar/in-range").getValue();
},

#### target prefix for mp chat ############
    get_target_chat_prefix: func() {
        tgt = me.ATC_target_id.getValue();
	if(tgt != "")
	   val = sprintf("%s: ",tgt);
	else val = "";
	return val;
},

#### radar range ###########
    step_radar_range:func(dir) {
    var range = me.RADAR_range.getValue();
    range *= dir > 0 ? 2 : 0.5;
    if (range < 1) range = 1;
    if(range>128)range=128;
    me.RADAR_range.setValue(range);
},

#### get runways ###########
    get_rwy_list:func(ap_id) {
        var carrier=me.ATC_carrier.getValue();
        var id=ap_id;
        var id_list=[];
        for(var i=0;i<20;i+=1){
            setprop("/sim/atc/rwy["~i~"]/id","");
        }
        if(carrier==0){
        var Apt=airportinfo(id);
        foreach(var r;keys(Apt.runways)){
            var curr = Apt.runways[r];
            var buf = sprintf("%s",curr.id);
            append(id_list,buf);
        }
        var num=size(id_list);
        props.globals.initNode("/sim/atc/num-rwys",num,"INT");
	wind = getprop("environment/wind-from-heading-deg")-me.mag_offset;
        if(wind <0)wind=wind+360;
	windspeed = getprop("environment/wind-speed-kt");
        for(var i=0;i<num;i+=1){
	    var head_component = 0;
	    var status = "";
	    var rw_heading_magnetic = 100*(id_list[i][0]-48)+10*(id_list[i][1]-48);
	    difference = rw_heading_magnetic - wind;
	    if(difference<0) difference = difference*-1;
	    if(windspeed < 3) status="****"; # Winds calm, any runway is OKay
	    else {
	      head_component = math.cos(difference * D2R);
	      if(head_component >= 0.8) status="*****";
	      elsif(head_component > 0.5) status="****";
	      elsif(head_component > 0.2) status="***";
	      elsif(head_component > 0) status="**";
	      elsif(head_component == 0) status="*";
	      else {
	        if((head_component * windspeed) < -10) # too strong tailwinds
                    status = "*";
		else {
                  if(head_component > -0.75) status = "**";
		  else status = "***"
		}
	      }
	    }
	    runway_info = sprintf("%5s  %s",status, id_list[i]);
            setprop("/sim/atc/rwy["~i~"]/id",runway_info);
        }
    }
},

#### init on reset ###########
    do_init: func (){
        print("Initializing...");
        var carrier=0;
        var nm=me.Tower_id.getValue();
        if(nm=="NMTZ_C"){
            carrier=1;
        }elsif(nm=="EZHR_C"){
            carrier=2;
        }
        me.ATC_carrier.setValue(carrier);
        var tmpmag=0;
        var minhgt=getprop("sim/atc/min-height");
        me.mag_offset=getprop("environment/magnetic-variation-deg");
        if(me.ATC_mag_display.getValue())tmpmag=tmpmag-me.mag_offset;
        if(tmpmag<0)tmpmag+=360;
        if(carrier==0){
            var ht = me.Tower_alt.getValue();
            if(ht<minhgt) ht=minhgt;
            me.ATC_lat.setValue(me.Tower_lat.getValue());
            me.ATC_lon.setValue(me.Tower_lon.getValue());
            me.ATC_alt.setValue(ht);
        }elsif(carrier==1){
            me.ATC_lat.setValue(getprop("ai/models/carrier[0]/position/latitude-deg"));
            me.ATC_lon.setValue(getprop("ai/models/carrier[0]/position/longitude-deg"));
            me.ATC_alt.setValue(250);
        }elsif(carrier==2){
            me.ATC_lat.setValue(getprop("ai/models/carrier[1]/position/latitude-deg"));
            me.ATC_lon.setValue(getprop("ai/models/carrier[1]/position/longitude-deg"));
            me.ATC_alt.setValue(250);
        }
        setprop("orientation/heading-deg",0);
        setprop("orientation/roll-deg",0);
        setprop("orientation/pitch-deg",0);
        me.get_rwy_list(getprop("/sim/tower/airport-id"));
	setprop("sim/atc/mag-compass",1); # Set default to magnetic compass. 
    },

#### update target ###########

    update_target:func(MP) {
        var alt = MP.getNode("position/altitude-ft").getValue();
    
    if (me.follow) {
        var eye_coords = geo.Coord.new();

        # view offsets: 
        #   x right +
        #   y up +
        #   z back +

        eye_coords.set_latlon(me.ATC_lat.getValue(),me.ATC_lon.getValue(),me.ATC_alt.getValue() * FT2M);
        var matrix = get_rotation_matrix(me.ATC_roll.getValue() * D2R,me.ATC_pitch.getValue() * D2R,me.ATC_heading.getValue() * D2R);
        var offset = tmul33(matrix, [me.ATC_offset_x.getValue(), -me.ATC_offset_z.getValue(), me.ATC_offset_y.getValue() ] );

        eye_coords.apply_course_distance(offset[1] < 0 ? 180 :  0, math.abs(offset[1]));
        eye_coords.apply_course_distance(offset[0] < 0 ? 270 : 90, math.abs(offset[0]));
        eye_coords.set_alt(eye_coords.alt() + offset[2]);

        var target_coords = geo.Coord.new();
        target_coords.set_latlon(
            MP.getNode("position/latitude-deg").getValue(),
            MP.getNode("position/longitude-deg").getValue(),
            alt * FT2M);

        var brg = -eye_coords.course_to(target_coords) + me.ATC_heading.getValue();
#- me.adjust_view(me.ATC_fov.getValue(), 0.586);
        var elevation = math.atan2(target_coords.alt() - eye_coords.alt(), eye_coords.distance_to(target_coords)) * R2D;
        # FIXME: assumes 4:3 aspect
#        var pitch = me.ATC_pitch.getValue() * math.cos(brg * D2R) - me.ATC_roll.getValue() * math.sin(brg * D2R) - me.adjust_view(me.ATC_fov.getValue() * 0.5, 0.5);
        var pitch=MP.getNode("radar/v-offset").getValue();
        me.ATC_target_brg.setValue(brg);
        me.ATC_target_pitch.setValue(pitch);
    }
    me.ATC_target_alt.setValue(alt);
    me.ATC_target_id.setValue(MP.getNode("callsign").getValue());
    me.ATC_target_range.setValue(MP.getNode("radar/range-nm").getValue());
    me.ATC_target_speed.setValue(MP.getNode("velocities/true-airspeed-kt").getValue());
    var truhdg=MP.getNode("orientation/true-heading-deg").getValue();
    var mphdg =truhdg;
    if(me.ATC_mag_display.getValue())mphdg=mphdg-me.mag_offset;
    me.ATC_target_hdg.setValue(mphdg);
    },

#### step target ###########

    step_target:func(step) {
        var mp_craft = props.globals.getNode("/ai/models").getChildren("multiplayer");
        var num = me.ATC_num.getValue();
        var ttl = size(mp_craft);

        if (ttl > 0) {
            num = me.add_with_wrap(num, step, ttl);
            if (step == 0) {
                # search upwards by default
                step = 1;
            }

            for(var tries = 0; tries < ttl; tries += 1) {
                if (me.is_valid_target(mp_craft[num])) {
                    me.ATC_num.setValue(num);
                    me.RADAR_id.setValue(mp_craft[num].getNode("id").getValue());
                    return mp_craft[num];
                }
                num = me.add_with_wrap(num, step, ttl);
            }
        }
        me.ATC_num.setValue(-1);
        me.RADAR_id.setValue(-1);
        return nil;
    },
};

var atc=ATC.new();
############################################

setlistener("sim/signals/fdm-initialized", func {
    atc.do_init();
    settimer(update_systems, 1);
});

setlistener("sim/signals/reinit", func(n) {
    n.getBoolValue() and return;
    # HACK: something overwrites view & position if we call do_init from here
    settimer(atc.do_init, 1);
});


# based on YASim function euler2orient
# returned matrix should be transposed
var get_rotation_matrix = func(roll, pitch, yaw)
{
    var out = [ 1, 0, 0, 0, 1, 0, 0, 0, 1 ];
    
    var col = 0;
    var x = 0;
    var y = 0;
    var z = 0;
    var s = math.sin(roll);
    var c = math.cos(roll);
    for(col = 0; col < 3; col += 1) {
        y = out[col + 3];
        z = out[col + 6];
        out[col + 3] = c * y - s * z;
        out[col + 6] = s * y + c * z;
    }

    s = math.sin(pitch);
    c = math.cos(pitch);
    for(col = 0; col < 3; col += 1) {
        x = out[col];
        z = out[col + 6];
        out[col]     = c * x + s * z;
        out[col + 6] = c * z - s * x;
    }

    s = math.sin(yaw);
    c = math.cos(yaw);
    for(col = 0; col< 3; col += 1) {
        x = out[col];
        y = out[col + 3];
        out[col]   = c * x - s * y;
        out[col+3] = s * x + c * y;
    }
    
    return out;
}

var tmul33 = func(matrix, vector) {
    var out = [ 0, 0, 0 ];
    for(var row = 0; row < 3; row += 1) {
        for(var col = 0; col < 3; col += 1) {
            out[row] += matrix[3 * col + row] * vector[col];
        }
    }
    return out;
}

var tan = func(x) {
    return math.sin(x) / math.cos(x);
}

var update_systems = func {
        # verify current target is valid,
        # try to find another if not
        var carrier=atc.ATC_carrier.getValue();
        var target = atc.step_target(0);
        if (target != nil) {
            atc.update_target(target);
        } else {
            atc.ATC_target_alt.setValue("");
            atc.ATC_target_id.setValue("");
            atc.ATC_target_range.setValue(0);
            atc.ATC_target_speed.setValue(0);
            atc.ATC_target_hdg.setValue(0);
        }
        if(atc.wind_check()) atc.get_rwy_list(getprop("/sim/tower/airport-id"));

        if(carrier==1){
            atc.c_update(1);
        }elsif(carrier==2){
            atc.c_update(2);
        }
        settimer(update_systems, 0);
}

var select_font_callback = func(n) { 
    var font = n.getValue();
    setprop("/instrumentation/radar/font/name", font);
}

var select_atc_font = func {
    var font = getprop("/instrumentation/radar/font");
    var dir = getprop("/sim/fg-root") ~ "/Fonts";
    var file = "";
    if (font != nil and size(font) > 0) {
        file = font;
        for(var i = size(font) - 2; i >= 0; i -= 1) {
            if (font[i] == `/`) {
                dir = substr(font, 0, i);
                file = substr(font, i + 1);
                break;
            }
        }
    }
    var selector = gui.FileSelector.new(select_font_callback, "Select ATC radar font", "Select", nil, dir, file);
    selector.open();
}
