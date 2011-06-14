# If the balloon scenario is loaded and enabled,
# place all balloons near the aircraft to get them loaded
#
_setlistener("/sim/signals/fdm-initialized", func {

  var balloonScenarioFound = 0;
  foreach( var scenario; props.globals.getNode("/sim/ai", 1 ).getChildren("scenario") ) {
    if( scenario.getValue() == "balloon_demo" )
      balloonScenarioFound = 1;
  }
  if( balloonScenarioFound != 0 ) {
    var position = geo.aircraft_position();
    var elevation = geo.elevation( position.lat(), position.lon() );
    position.set_alt( elevation != nil ? elevation : 0.0 );

    foreach( var tanker; props.globals.getNode("/ai/models",1).getChildren("tanker") ) {
      var callsign = tanker.getNode("callsign").getValue();
      if( callsign == nil ) continue;
      if( string.match(callsign,"ballon*") ) {
        tanker.getNode("position/latitude-deg",1).setDoubleValue( position.lat() - 0.002 );
        tanker.getNode("position/longitude-deg",1).setDoubleValue( position.lon() - 0.002 );
        tanker.getNode("position/altitude-ft", 1 ).setDoubleValue( position.alt() );
      }
    }
  }
  delete(globals, "balloons");
});


