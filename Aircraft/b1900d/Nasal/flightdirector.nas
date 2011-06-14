#############################################################################
# Flight Director/Autopilot controller.
# Syd Adams
#
#FlightDirector/Autopilot 
# ie: var fltdir = flightdirector.new(property);


var flightdirector = {
    new : func(fdprop){
        m = {parents : [flightdirector]};
        m.lnav_text=["ROLL","HDG","NAV","GPS-CRS"];
        m.vnav_text=["PITCH","ALT","VS","GS","CLIMB","DCS"];
        m.spd_text=["","IAS"];
        m.step=0;


        m.node = props.globals.initNode(fdprop);
        m.yawdamper = props.globals.initNode("autopilot/locks/yaw-damper",0,"BOOL");
        m.HSI = m.node.initNode("hsi");
        m.lnav = m.node.initNode("lnav",0,"INT");
        m.vnav = m.node.initNode("vnav",0,"INT");
        m.gs_arm = m.node.initNode("gs-arm",0,"BOOL");
        m.nav_arm = m.node.initNode("nav-arm",0,"BOOL");
        m.alt_arm = m.node.initNode("alt-arm",0,"BOOL");
        m.asel = m.node.initNode("Asel",10000,"DOUBLE");
        m.speed = m.node.initNode("spd",0,"INT");
        m.DH = m.node.initNode("decision-hold",200,"INT");
        m.Defl = props.globals.getNode("instrumentation/nav/heading-needle-deflection");
        m.GSDefl = props.globals.getNode("instrumentation/nav/gs-needle-deflection-norm");
        m.FD_defl = m.HSI.initNode("crs-deflection",0,"DOUBLE");
        m.FD_crs = m.HSI.initNode("crs-mag-heading",0,"INT");
        m.FD_toflag = m.HSI.initNode("to-flag",0,"BOOL");
        m.NavLoc = props.globals.getNode("instrumentation/nav/nav-loc");
        m.hasGS = props.globals.getNode("instrumentation/nav/has-gs");
        m.GSrange = props.globals.getNode("instrumentation/nav/gs-in-range");
        m.Valid = props.globals.getNode("instrumentation/nav/in-range");
        m.FMS = props.globals.initNode("instrumentation/nav/slaved-to-gps",1,"BOOL");

        m.AP_hdg = props.globals.initNode("/autopilot/locks/heading",m.lnav_text[0],"STRING");
        m.AP_hdg_setting = props.globals.initNode("/autopilot/settings/heading-bug-deg",0,"INT");
        m.AP_spd_setting = props.globals.initNode("/autopilot/settings/target-speed-kt",100,"INT");
        m.AP_vsi_setting = props.globals.initNode("/autopilot/settings/target-vs-fpm",0,"INT");
        m.AP_climb_speed = props.globals.initNode("/autopilot/settings/target-climb-speed",210,"INT");
        m.AP_descent_fpm = props.globals.initNode("/autopilot/settings/target-descent-fpm",-1500,"INT");
        m.AP_pitch= props.globals.initNode("/autopilot/settings/target-pitch-deg",0,"DOUBLE");
        m.AP_roll= props.globals.initNode("/autopilot/settings/target-roll-deg",0,"DOUBLE");
        m.AP_alt = props.globals.initNode("/autopilot/locks/altitude",m.vnav_text[0],"STRING");
        m.AP_spd = props.globals.initNode("/autopilot/locks/speed",m.spd_text[0],"STRING");
        m.AP_off = props.globals.initNode("/autopilot/locks/passive-mode",1,"BOOL");

        m.pitch_active=props.globals.initNode("/autopilot/locks/pitch-active",1,"BOOL");
        m.roll_active=props.globals.initNode("/autopilot/locks/roll-active",1,"BOOL");
        m.bank_limit=m.node.initNode("bank-limit-switch",0,"BOOL");

        m.max_pitch=m.node.initNode("pitch-max",5,"DOUBLE");
        m.min_pitch=m.node.initNode("pitch-min",-5,"DOUBLE");
        m.max_roll=m.node.initNode("roll-max",27,"DOUBLE");
        m.min_roll=m.node.initNode("roll-min",-27,"DOUBLE");
    return m;
    },
    ############################
#### main loop####
    ap_loop : func(){
        if(me.step==0){
            me.update_lnav();
        }elsif(me.step==1){
            me.update_vnav();
        }elsif(me.step==2){
            var APoff = me.check_AP_limits();
        }
        me.step +=1;
        if(me.step >2)me.step=0;
    },
    ############################
    preset_altitude : func(vl){
        var asl=0;
        if(vl!=0){
            asl = me.asel.getValue();
            asl +=vl;
            if(asl > 99000)asl=99000;
            if(asl<0)asl=0;
        }
        me.asel.setValue(asl);
    },
############################
    set_lateral_mode : func(lnv){

        if(lnv ==1){
            if(me.lnav.getValue()==1)lnv=me.nav_arm.getValue();
        }
        me.lnav.setValue(lnv);
        me.AP_hdg.setValue(me.lnav_text[lnv]);
    },
###########################
    set_vertical_mode : func(vnv){
    var tst =me.vnav.getValue();
    var ptch = getprop("orientation/pitch-deg");
    if(vnv ==tst){
        vnv=0;
        me.AP_pitch.setValue(ptch);
    }
        if(vnv==1){
        var asel=getprop("instrumentation/altimeter/indicated-altitude-ft");
        asel = int(asel * 0.1) * 10;
        me.asel.setValue(asel);
        }
        if(vnv==2){
            var vspm = getprop("velocities/vertical-speed-fps");
            vspm = int(vspm * 60);
            me.AP_vsi_setting.setValue(vspm);
        }
        me.vnav.setValue(vnv);
        me.AP_alt.setValue(me.vnav_text[vnv]);
    },
###########################
    set_course : func(crs){
        var mag=getprop("environment/magnetic-variation-deg");
        var rd =0;
        rd = me.FD_crs.getValue();
            if(crs ==0){
                rd=int(getprop("orientation/heading-magnetic-deg"));
            }else{
                rd = rd+crs;
                if(rd >360)rd =rd-360;
                if(rd <1)rd = rd +360;
            }
            me.FD_crs.setValue(rd);
            if(me.FMS.getValue()){
                rd+=mag;
                if(rd>360)rd-=360;
                setprop("instrumentation/gps/wp/wp[1]/desired-course-deg",rd);
            }else{
                setprop("instrumentation/nav/radials/selected-deg",rd);
            }
    },
###########################
    set_hdg_bug : func(hbg){
        var rd =0;
            rd = getprop("autopilot/settings/heading-bug-deg");
            if(rd==nil)rd=0;
            if(hbg ==0){
                rd=int(getprop("orientation/heading-magnetic-deg"));
            }else{
                rd = rd+hbg;
                if(rd >360)rd =rd-360;
                if(rd <1)rd = rd +360;
            }
            setprop("autopilot/settings/heading-bug-deg",rd);
    },
###########################
    ias_set : func(spd){
        var rd =0;
            rd = me.AP_spd_setting.getValue();
            if(rd==nil)rd=0;
            if(spd ==0){
                rd=0;
            }else{
                rd = rd+spd;
                if(rd >400)rd =400;
                if(rd <0)rd = 0;
            }
            me.AP_spd_setting.setValue(rd);
    },
#### button press handler####
    set_mode : func(mode){
        if(mode=="hdg"){
            me.set_lateral_mode(1);
        }elsif(mode=="nav"){
            var tmp=1-me.nav_arm.getValue();
            me.nav_arm.setValue(tmp);
            me.set_lateral_mode(1);
        }elsif(mode=="apr"){
            var app =me.nav_arm.getValue();
            app=1-app;
            if(!me.NavLoc.getValue())app =0;
            if(!me.hasGS.getValue())app =0;
            me.nav_arm.setValue(app);
            me.gs_arm.setValue(app);
        }elsif(mode=="bc"){
            var tst=me.lnav.getValue();
            var bcb = getprop("instrumentation/nav/back-course-btn");
            bcb = 1-bcb;
            if(tst <2 and tst >5)bcb = 0;
            setprop("instrumentation/nav/back-course-btn",bcb);
        }elsif(mode=="alt"){
            me.set_vertical_mode(1);
        }elsif(mode=="asel"){
            var tmp=1-me.alt_arm.getValue();
            me.alt_arm.setValue(tmp);
        }elsif(mode=="vs"){
            me.set_vertical_mode(2);
        }elsif(mode=="climb"){
            me.set_vertical_mode(4);
        }elsif(mode=="dcs"){
            me.set_vertical_mode(5);
        }elsif(mode=="ias"){
            var sp = me.speed.getValue();
            sp=1-sp;
            me.AP_spd.setValue(me.spd_text[sp]);
            me.speed.setValue(sp);
            if(sp==1){
                var veloc = abs(getprop("velocities/airspeed-kt"));
                if(veloc<100) veloc=100;
                setprop("autopilot/settings/target-speed-kt",veloc);
            }else{
                setprop("autopilot/settings/target-speed-kt",100);
            }
        }
    },
#### check AP errors####
    check_AP_limits : func(){
        var apmode = me.AP_off.getBoolValue();
        var agl=getprop("/position/altitude-agl-ft");
        if(!apmode){
            var maxroll = getprop("/orientation/roll-deg");
            var maxpitch = getprop("/orientation/pitch-deg");
            if(maxroll > 60 or maxroll < -60){
                apmode = 1;
            }
            if(maxpitch > 30 or maxpitch < -30){
                apmode = 1;
                setprop("controls/flight/elevator-trim",0);
            }
            if(agl < 150)apmode = 1;
            me.AP_off.setBoolValue(apmode);
        }
        if(agl < 50)me.yawdamper.setBoolValue(0);
        return apmode;
    },
#### update lnav####
    update_lnav : func(){
        var lnv = me.lnav.getValue();
        var fms = me.FMS.getValue();
        var armed = me.nav_arm.getValue();

    if(armed){
        var defl = me.Defl.getValue();
        if(me.Valid.getBoolValue()){
            if(defl <= 9 and defl >= -9){
                me.nav_arm.setValue(0);
                lnv=2;
            }
        }
    }
    me.lnav.setValue(lnv);
    me.AP_hdg.setValue(me.lnav_text[lnv]);
    },

#### update vnav####

    update_vnav : func(){
        var clmb_spd = me.AP_climb_speed.getValue();
        var vnv = me.vnav.getValue();
        var altmtr = getprop("instrumentation/altimeter/indicated-altitude-ft");
        var clm = altmtr-10000;
        if(clm<0)clm=0;
        clm *= 0.002;

        setprop("autopilot/internal/climb-ias",clmb_spd-clm);

        if(me.gs_arm.getBoolValue()){
            var defl = me.GSDefl.getValue();
            if(defl < 0.2 and defl > -0.2){
                if(me.GSrange.getValue()){
                    vnv=3;
                    me.gs_arm.setBoolValue(0);
                }
            }
            me.vnav.setValue(vnv);
            me.AP_alt.setValue(me.vnav_text[vnv]);
        }

        if(me.alt_arm.getBoolValue()){
            
            var asel = abs(altmtr-me.asel.getValue());
            if(asel < 1000){
                vnv=1;
                me.alt_arm.setBoolValue(0);
                me.vnav.setValue(vnv);
                me.AP_alt.setValue(me.vnav_text[vnv]);
            }
        }
},
#### update course from gps/nav####
    update_crs : func(){
        var mag=getprop("environment/magnetic-variation-deg");
        var dfl=0;
        var crs=0;
        var to=0;
        var hdg=0;
        var gps_offset=0;
        if(me.FMS.getValue()){
            dfl = getprop("instrumentation/gps/wp/wp[1]/course-error-nm");
            if(dfl==nil)dfl=0;
            dfl = dfl * 2;
            if(dfl>10)dfl=10;
            if(dfl<-10)dfl=-10;
            to=getprop("instrumentation/gps/wp/wp[1]/to-flag");
            crs=getprop("instrumentation/gps/wp/wp[1]/desired-course-deg");
            crs-=mag;
            if(crs<0)crs+=360;
            hdg=getprop("orientation/heading-magnetic-deg");
            gps_offset=crs-hdg;
            gps_offset+=(dfl*4.5);
            if(gps_offset<-180)gps_offset+=360;
            if(gps_offset>180)gps_offset-=360;
            }else{
            dfl = me.Defl.getValue();
            to=getprop("instrumentation/nav/to-flag");
            crs=getprop("instrumentation/nav/radials/selected-deg");
        }
        if(dfl==nil)dfl=0;
        if(to==nil)to=0;
        if(crs==nil)crs=0;
        me.FD_defl.setValue(dfl);
        me.FD_toflag.setValue(to);
        me.FD_crs.setValue(crs);
        setprop("autopilot/internal/gps-course-offset",gps_offset);
    },
#### autopilot engage####
    toggle_autopilot : func(apmd){
        var md1=0;
        if(apmd=="ap"){
            md1 = me.AP_off.getBoolValue();
            md1=1-md1;
            if(getprop("/position/altitude-agl-ft") < 180)md1=1;
            me.AP_off.setBoolValue(md1);
            if(md1==0)me.yawdamper.setBoolValue(1);
        }elsif(apmd=="yd"){
            md1 = me.yawdamper.getBoolValue();
            md1=1-md1;
            me.yawdamper.setBoolValue(md1);
            if(md1==0)me.AP_off.setBoolValue(1);
        }elsif(apmd=="bank"){
            md1 = me.bank_limit.getBoolValue();
            md1=1-md1;
            me.bank_limit.setBoolValue(md1);
            if(md1==1){
                me.max_roll.setValue(14);
                me.min_roll.setValue(-14);
            }else{
                me.max_roll.setValue(27);
                me.min_roll.setValue(-27);
            }
        }
    }
};

var FlDr=flightdirector.new("instrumentation/flightdirector");

######################################

setlistener("/sim/signals/fdm-initialized", func {
    setprop("autopilot/settings/target-altitude-ft",0);
    settimer(update_fd, 5);
    setprop("autopilot/settings/vertical-speed-fpm",0);
    setprop("autopilot/settings/target-pitch-deg",0);
    print("Flight Director ...Check");
});


var update_fd = func {
FlDr.ap_loop();
settimer(update_fd, 0); 
}
