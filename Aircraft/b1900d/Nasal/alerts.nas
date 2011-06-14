####	Warning/Caution/GPWS alerts ####


var Alarm = {
    new : func(prop){
    m = { parents : [Alarm] };
    m.counter=0;
    m.gpwscounter=0;
    m.gpwstimer=0;
    m.dh_armed=0;
    m.warning_props=["L-fuel-psi","cbn-alt","cbn-diff","R-fuel-psi","L-oil-psi",
    "L-env-fail","cbn-door","R-env-fail","R-oil-psi","L-ac-bus","crg-door",
    "R-ac-bus","L-bleed-air","AP-trim","emer-lights","AP-fail","R-bleed-air"];
    m.warning_index=[];
    m.node = props.globals.getNode(prop,1);
    m.Caution = m.node.getNode("caution",1);
        m.MCaution = m.Caution.getNode("Master",1);
        m.MCaution.setBoolValue(0);
        m.Ctest = m.Caution.getNode("test",1);
        m.Ctest.setBoolValue(0);
        m.MCflasher = m.Caution.getNode("flasher",1);
        m.MCflasher.setIntValue(0);
    m.Warning = m.node.getNode("warning",1);
        m.MWarning = m.Warning.getNode("Master",1);
        m.MWarning.setBoolValue(0);
        m.Wtest = m.Warning.getNode("test",1);
        m.Wtest.setBoolValue(0);
        m.MWflasher = m.Warning.getNode("flasher",1);
        m.MWflasher.setIntValue(0);
    m.GPWS = m.node.getNode("gpws",1);
        m.volume=m.GPWS.getNode("volume",1);
        m.volume.setDoubleValue(0.5);
        m.altitude_active=m.GPWS.getNode("altitude-active",1);
        m.altitude_active.setBoolValue(0);
        m.altitude_callout=m.GPWS.getNode("altitude-callout",1);
        m.altitude_callout.setIntValue(0);
        m.terrain_active=m.GPWS.getNode("terrain-active",1);
        m.terrain_active.setBoolValue(0);
        m.terrain_alert=m.GPWS.getNode("terrain-alert",1);
        m.terrain_alert.setBoolValue(0);
        m.bank=m.GPWS.getNode("bank-angle",1);
        m.bank.setBoolValue(0);
        m.pitch=m.GPWS.getNode("pitch",1);
        m.pitch.setBoolValue(0);
        m.sink=m.GPWS.getNode("sink-rate",1);
        m.sink.setBoolValue(0);
        m.minimums=m.GPWS.getNode("minimums",1);
        m.minimums.setBoolValue(0);

    for(var i=0; i<size(m.warning_props); i+=1) {
        append(m.warning_index,m.Warning.getNode(m.warning_props[i],1));
        m.warning_index[i].setBoolValue(0);
    }

    return m;
    },
###############
    check_caution:func{
        if(me.MCaution.getValue()){
            var Cflash =me.MCflasher.getValue();
            Cflash=1-Cflash;
            me.MCflasher.setValue(Cflash);
        }else{
            me.MCflasher.setValue(0);
        }
    },
###############
    check_warning:func{
        var testbutton=me.Wtest.getValue();
        var master=me.MWarning.getValue();
        var pwr=getprop("systems/electrical/volts");
        if(pwr==nil)pwr=0;
        var test1=0;
        var test2=0;
        var ac1=0;
        var ac2=0;
        var cbndoor=0;
        if(master){
                var Wflash =me.MWflasher.getValue();
                Wflash=1-Wflash;
                me.MWflasher.setValue(Wflash);
            }else{
                me.MWflasher.setValue(0);
            }

        if(pwr<5){
            master=0;
            test1=0;
            test2=0;
            ac1=0;
            ac2=0;
            cbndoor=0;
            testbutton=0;
        }elsif(testbutton){
            master=1;
            test1=1;
            test2=1;
            ac1=1;
            ac2=1;
            cbndoor=1;
        }else{
            if(getprop("engines/engine/n2")<30){
                test1=1;
                master=1;
            }
            if(getprop("engines/engine[1]/n2")<30){
                test2=1;
                master=1;
            }
            if(getprop("systems/electrical/LH-ac-bus")<100){
                ac1=1;
                master=1;
            }
            if(getprop("systems/electrical/RH-ac-bus")<100){
                ac2=1;
                master=1;
            }
            if(getprop("controls/cabin-door/position-norm")>0){
                cbndoor=1;
                master=1;
            }
        }
            me.MWarning.setValue(master);
            me.warning_index[0].setValue(test1);
            me.warning_index[4].setValue(test1);
            me.warning_index[5].setValue(test1);
            me.warning_index[12].setValue(test1);

            me.warning_index[3].setValue(test2);
            me.warning_index[7].setValue(test2);
            me.warning_index[8].setValue(test2);
            me.warning_index[16].setValue(test2);

            me.warning_index[9].setValue(ac1);
            me.warning_index[11].setValue(ac2);

            me.warning_index[1].setValue(testbutton);
            me.warning_index[2].setValue(testbutton);
            me.warning_index[10].setValue(testbutton);
            me.warning_index[13].setValue(testbutton);
            me.warning_index[14].setValue(testbutton);
            me.warning_index[15].setValue(testbutton);
            me.warning_index[6].setValue(cbndoor);


    }
};


var alert=Alarm.new("instrumentation/annunciators");

########################################

setlistener("sim/signals/fdm-initialized", func {
    print("Alerts   ...Check");
     settimer(update_alarms,2);
    });

var update_alarms = func {
    if(alert.counter ==0){
        alert.check_caution();
    }elsif(alert.counter ==1){
        alert.check_warning();
    }
    alert.counter =1-alert.counter;

settimer(update_alarms,0.2);
}
