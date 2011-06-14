    M877 = {
        new : func(prop,FMprop){
        m = { parents : [M877]};
        m.current_mode=0;
        m.m877 = props.globals.getNode(prop,1);
        m.FM_exists =1;
        m.Fmeter_sec = props.globals.getNode(FMprop);
        if(m.Fmeter_sec==nil)m.FM_exists=0;
        m.ET_offset=0;
        if(m.Fmeter_sec==nil)m.FM_exists=0;
        if(m.FM_exists!=0)m.ET_offset=m.Fmeter_sec.getValue();
        m.set_hour=m.m877.getNode("set-hour",1);
        m.set_hour.setBoolValue(0);
        m.set_min=m.m877.getNode("set-min",1);
        m.set_min.setBoolValue(0);
        m.mode=m.m877.getNode("mode",1);#0=GMT,1=LT,2=FT,3=ET#
        m.mode.setIntValue(0);
        m.Ind_Hr=m.m877.getNode("indicated-hour",1);
        m.Ind_Hr.setDoubleValue(0);
        m.Ind_Min=m.m877.getNode("indicated-min",1);
        m.Ind_Min.setDoubleValue(0);
        m.GMT_hour=props.globals.getNode("/instrumentation/clock/indicated-hour",1);
        m.LOCAL_hour=props.globals.getNode("/instrumentation/clock/local-hour",1);
        m.MINUTES=props.globals.getNode("/instrumentation/clock/indicated-min",1);
    return m;
    },
####
    update:func{
        if(me.current_mode ==0){
            me.Ind_Hr.setValue(me.GMT_hour.getValue());
            me.Ind_Min.setValue(me.MINUTES.getValue());
        }elsif(me.current_mode ==1){
            me.Ind_Hr.setValue(me.LOCAL_hour.getValue());
            me.Ind_Min.setValue(me.MINUTES.getValue());
        }elsif(me.current_mode ==2){
            if(me.FM_exists){
                var FMseconds=me.Fmeter_sec.getValue();
                var Fmin=int(FMseconds * 0.016666);
                var Fhr=int(Fmin * 0.016666);
                me.Ind_Hr.setValue(Fhr);
                me.Ind_Min.setValue(Fmin);
            }
        }elsif(me.current_mode ==3){
        if(me.FM_exists){
                var ETseconds=me.Fmeter_sec.getValue();
                ETseconds=ETseconds-me.ET_offset;
                var ETmin=int(ETseconds * 0.016666);
                var EThr=int(ETmin * 0.016666);
                me.Ind_Hr.setValue(EThr);
                me.Ind_Min.setValue(ETmin);
            }
        }
    },
####
    set_mode:func{
        var md=me.mode.getValue();
        md+=1;
        if(md>3)md-=4;
        me.current_mode=md;
        me.mode.setValue(md);
    }
};
##################################

var Chrono=M877.new("/instrumentation/clock/m877","/instrumentation/clock/flight-meter-sec","/instrumentation/clock/ET-hr");

setlistener("/sim/signals/fdm-initialized", func {
    print("Chronometer ... Check");
    settimer(update_clock,2);
});

var update_clock = func{
    Chrono.update();
settimer(update_clock,1);
}