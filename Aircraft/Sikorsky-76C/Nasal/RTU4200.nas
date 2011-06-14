var RTU=props.globals.getNode("/instrumentation/RTU4200",1);
var ADF=props.globals.getNode("/instrumentation/adf/frequencies",1);
var SELECTED0 =["comm","nav","atc","adf"];
var SELECTED1 =["comm[1]","nav[1]","atc","adf"];
RTU.getNode("unit[0]/serviceable",1).setBoolValue(1);
RTU.getNode("unit[0]/mode",1).setIntValue(0);
RTU.getNode("unit[0]/selected",1).setIntValue(0);
RTU.getNode("unit[0]/comm",1).setDoubleValue(000.00);
RTU.getNode("unit[0]/comm-stby",1).setDoubleValue(000.00);
RTU.getNode("unit[0]/nav",1).setDoubleValue(000.00);
RTU.getNode("unit[0]/nav-stby",1).setDoubleValue(000.00);
RTU.getNode("unit[0]/adf",1).setDoubleValue(000.0);
RTU.getNode("unit[1]/serviceable",1).setBoolValue(1);
RTU.getNode("unit[1]/mode",1).setIntValue(1);
RTU.getNode("unit[1]/selected",1).setIntValue(0);
RTU.getNode("unit[1]/comm",1).setDoubleValue(000.00);
RTU.getNode("unit[1]/comm-stby",1).setDoubleValue(000.00);
RTU.getNode("unit[1]/nav",1).setDoubleValue(000.00);
RTU.getNode("unit[1]/nav-stby",1).setDoubleValue(000.00);
RTU.getNode("unit[1]/adf",1).setDoubleValue(000.0);

setlistener("/sim/signals/fdm-initialized", func {
    update_display(0);
    update_display(1);
    print("RTU 4200 System ... Check");
});

setlistener("/instrumentation/RTU4200/unit[0]/mode", func(m1){
    update_display(0);
},0,0);

setlistener("/instrumentation/RTU4200/unit[0]/selected", func(ms1) {
    update_display(0);
},0,0);

setlistener("/instrumentation/RTU4200/unit[1]/mode", func(m2){
    update_display(1);
},0,0);

setlistener("/instrumentation/RTU4200/unit[1]/selected", func(ms2){
    update_display(0);
},0,0);

var update_display = func{
    var Unit = RTU.getNode("unit["~arg[0]~"]");
    var mode =Unit.getNode("mode").getValue();
    var Comm = props.globals.getNode("instrumentation/comm["~mode~"]/frequencies");
    var Nav = props.globals.getNode("instrumentation/nav["~mode~"]/frequencies");
    Unit.getNode("comm").setValue(Comm.getNode("selected-mhz").getValue());
    Unit.getNode("comm-stby").setValue(Comm.getNode("standby-mhz").getValue());
    Unit.getNode("nav").setValue(Nav.getNode("selected-mhz").getValue());
    Unit.getNode("nav-stby").setValue(Nav.getNode("standby-mhz").getValue());
    Unit.getNode("adf").setValue(ADF.getNode("selected-khz").getValue());
}