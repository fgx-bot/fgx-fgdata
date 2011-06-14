#=========================== recoil ==============================
print("recoil running");
var trigger_node = props.globals.getNode("/controls/armament/trigger", 1);
var recoil_node = props.globals.getNode("/sim/ai/recoil", 1);
var runout_node = props.globals.getNode("/sim/ai/runout", 1);

var recoil_norm = 0;
var runout_norm = 1;

var updateRecoil = func {

    if (trigger_node.getValue()) {
        recoil_norm =!recoil_norm;
        runout_norm =!runout_norm;
        recoil_node.setDoubleValue(recoil_norm);
        runout_node.setDoubleValue(runout_norm);
        #print ("recoil norm trigger", recoil_norm, " " , runout_norm);
        settimer(updateRecoil, 0.04);
    } else {
        recoil_node.setDoubleValue(0);
        runout_node.setDoubleValue(0);
        #print ("recoil norm non trigger", recoil_norm, " ", runout_norm);
    }

#    print ("recoil norm ", recoil_norm, " ", runout_norm);
}

setlistener(trigger_node, updateRecoil)

# end 