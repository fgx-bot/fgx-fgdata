# =============================
# system for 737-100 by helijah
# =============================

var loop = func {

  # =========================
  # gph -> pph by Helijah
  # =========================
  var FuelDensity=props.globals.getNode("consumables/fuel/tank[0]/density-ppg",1).getValue();
  if(FuelDensity == nil){FuelDensity = 6.72};
  var pph=getprop("/engines/engine[0]/fuel-flow-gph");
  if(pph == nil){pph = 0.0};
  setprop("/engines/engine[0]/fuel-flow-gph", pph * FuelDensity );

  var poundperhour = sprintf("%05.f", getprop("/engines/engine[0]/fuel-flow-gph") );

  setprop("/engines/engine[0]/fuel-flow-pph/unit10000", chr(poundperhour[0]));
  setprop("/engines/engine[0]/fuel-flow-pph/unit1000", chr(poundperhour[1]));
  setprop("/engines/engine[0]/fuel-flow-pph/unit100", chr(poundperhour[2]));
  setprop("/engines/engine[0]/fuel-flow-pph/unit10", chr(poundperhour[3]));
  setprop("/engines/engine[0]/fuel-flow-pph/unit1", chr(poundperhour[4]));

  var FuelDensity=props.globals.getNode("consumables/fuel/tank[0]/density-ppg",1).getValue();
  if(FuelDensity == nil){FuelDensity = 6.72};
  var pph=getprop("/engines/engine[1]/fuel-flow-gph");
  if(pph == nil){pph = 0.0};
  setprop("/engines/engine[1]/fuel-flow-gph", pph * FuelDensity );

  var poundperhour = sprintf("%05.f", getprop("/engines/engine[1]/fuel-flow-gph") );

  setprop("/engines/engine[1]/fuel-flow-pph/unit10000", chr(poundperhour[0]));
  setprop("/engines/engine[1]/fuel-flow-pph/unit1000", chr(poundperhour[1]));
  setprop("/engines/engine[1]/fuel-flow-pph/unit100", chr(poundperhour[2]));
  setprop("/engines/engine[1]/fuel-flow-pph/unit10", chr(poundperhour[3]));
  setprop("/engines/engine[1]/fuel-flow-pph/unit1", chr(poundperhour[4]));

  # =========================
  # Course for HSI by Helijah
  # =========================
  var rsd = sprintf("%03.f", getprop("/instrumentation/nav[1]/radials/selected-deg") );

  setprop("/instrumentation/nav[1]/radials/rsd/val100", chr(rsd[0]));
  setprop("/instrumentation/nav[1]/radials/rsd/val10", chr(rsd[1]));
  setprop("/instrumentation/nav[1]/radials/rsd/val1", chr(rsd[2]));

  # ==========================
  # Heading for HSI by Helijah
  # ==========================
  var dist = sprintf("%04.f", getprop("/instrumentation/tacan/indicated-distance-nm") );

  setprop("/instrumentation/tacan/dist/val1000", chr(dist[0]));
  setprop("/instrumentation/tacan/dist/val100", chr(dist[1]));
  setprop("/instrumentation/tacan/dist/val10", chr(dist[2]));
  setprop("/instrumentation/tacan/dist/val1", chr(dist[3]));

  settimer(loop, 0);
}

loop();

