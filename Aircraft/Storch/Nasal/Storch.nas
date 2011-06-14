var F_Switch = props.globals.getNode("controls/fuel/switch-position",2);
var FDM=0;
var hmHobbs  =  aircraft.timer.new("instrumentation/hobbs-meter/time", 60); 
var rpmN     = props.globals.getNode("engines/engine[0]/rpm", 1); 

var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("controls/lighting/strobe-state", [0.05, 1.30], strobe_switch);

var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("controls/lighting/beacon-state", [1.0, 1.0], beacon_switch);

aircraft.livery.init("Aircraft/Storch/Models/Liveries");

setlistener("/sim/signals/fdm-initialized", func {
    F_Switch.setIntValue(-1);
    setprop("consumables/fuel/tank[0]/selected",1);
    setprop("consumables/fuel/tank[1]/selected",1);
    setup_start();
    FDM=1;
    update();
});

setlistener("/sim/signals/reinit", func(n) {
    if(n.getValue()==0){
    setup_start();
    }
});

setlistener("controls/fuel/switch-position", func(n) {
    var position=n.getValue();
    setprop("consumables/fuel/tank[0]/selected",0);
    setprop("consumables/fuel/tank[1]/selected",0);
    if(position == 1 or position == 2){
        setprop("consumables/fuel/tank[0]/selected",1);
    };
    if(position == 2 or position == 3){
        setprop("consumables/fuel/tank[1]/selected",1);
    };
},1);

setlistener("controls/electric/circuitbreaker/cb_0_1", func(n) {
    if (n.getBoolValue()) {
	    setprop("instrumentation/marker-beacon/power-btn",0);
    } else {
	    setprop("instrumentation/marker-beacon/power-btn",1);
    }
});

setlistener("controls/electric/circuitbreaker/cb_0_6", func(n) {
    if (n.getBoolValue()) {
	    setprop("/sim/view/dynamic/enabled",0);
    } else {
	    setprop("/sim/view/dynamic/enabled",1);
    }
});

   
# ==============
# 8 Day Clock
# ==============

var clockTime=0;

clockResetexport = func{
    var running=getprop("instrumentation/clock/stopwatch-running");
    var time=getprop("instrumentation/clock/stopwatch-seconds");
# print("clockReset Called: time=", time, " Running=", running);
# running -> stop    
    if(running == 1){
# print("clockReset: stop!");
        setprop("instrumentation/clock/stopwatch-running", 0);
    }
    if(running == 0)
    {
# print("clockReset:running is false!");
# !running & seconds -> reset
        if(time > 0)
        {
# print("clockReset: reset!");
            setprop("instrumentation/clock/stopwatch-seconds", 0);
            clockTime=0;
        }
# !running & !seconds ->start
        if(time == 0)
        {
# print("clockReset: start!");
            setprop("instrumentation/clock/stopwatch-running", 1);
            clockTime=getprop("/sim/time/utc/day-seconds");

        }
    }
}

clockUpdate = func
{
    var running=getprop("instrumentation/clock/stopwatch-running");
    if(running){
        var time=getprop("/sim/time/utc/day-seconds");
        setprop("instrumentation/clock/stopwatch-seconds", time-clockTime);
    }
} 

# ==============
# Fuel System
# ==============

var fuelPressure = func{
    var rpm=getprop("engines/engine/rpm");
    rpm = rpm > 300 ? 1 : rpm/300;
    interpolate("engines/engine/fuel-pressure-psi", 30.0*rpm, 1);
}


setup_start = func{

}
# ==============
# Hobbs Meter
# ==============

calcDigits = func( v, prop, ndigit ) {
    v = int( v );
    for( var i = 0; i < ndigit ; i=i+1 ) {
        v2 = int( v / 10 );
        r = v - v2 * 10;
        setprop( prop~i, r );
        v = v2;
    }
}

var calcHoursMeter = func {
  if( rpmN.getValue() > 100.0 ) {
    hmHobbs.start();
  } else {
    hmHobbs.stop();
  }
  calcDigits( int(getprop("instrumentation/hobbs-meter/time") / 360), "instrumentation/hobbs-meter/digits", 5);
}

update = func {
    fuelPressure();
    clockUpdate();
    calcHoursMeter();
    settimer(update,0);
}

