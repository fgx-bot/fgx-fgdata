#############################################################################
# This file is part of FlightGear, the free flight simulator
# http://www.flightgear.org/
#
# Copyright (C) 2009 Torsten Dreyer, Torsten (at) t3r _dot_ de
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#############################################################################

GetPropertyPath = func(node) {
  if( node.getParent() != nil ) {
    return GetPropertyPath( node.getParent() ) ~ "/" ~ node.getName();
  }
  return "";
}

var listenerHash = {};

propertyListener = func(node) {
  var timer = listenerHash[ GetPropertyPath( node ) ];
  if( timer != nil ) {
    timer.listener();
  }
}

var timeNode = props.globals.getNode( "/sim/time/elapsed-sec" );

var Timer = {};

Timer.new = func {
  var obj = {};
  obj.parents = [Timer];
  obj.timerNode = arg[0];
  obj.name = obj.timerNode.getNode( "name" ).getValue();
  obj.enableNode = obj.getProperty( "enable-property" );
  obj.startNode  = obj.getProperty( "start-property" );
  obj.outputNode = obj.getProperty( "output-property" );
  if( obj.outputNode != nil )
    obj.outputNode.setBoolValue( 0 );
  obj.t0Node  = obj.timerNode.getNode( "t0" );
  obj.expires = 0;

  setlistener( obj.startNode, propertyListener );

  var s = GetPropertyPath( obj.startNode );
  listenerHash[s] = obj;

  return obj;
}

Timer.getProperty = func(prop) {
  var node = me.timerNode.getNode( prop );
  if( node == nil ) {
    return nil;
  }
  return props.globals.getNode( node.getValue() );
}

Timer.listener = func {
  if( ! me.outputNode.getBoolValue() and me.startNode.getBoolValue() ) {
    me.outputNode.setBoolValue( 1 );
    me.expires = timeNode.getValue() + me.t0Node.getValue();
    settimer( expireTimers, me.t0Node.getValue() );
  }
}

Timer.expire = func {
  if( me.outputNode.getBoolValue() and me.expires <= timeNode.getValue() ) {
    me.outputNode.setBoolValue( 0 );
  }
}

var timers = [];

createTimer = func(timer) {
  var t = Timer.new( timer );
  append( timers, t );
}

var expireTimers = func {
  foreach( var timer; timers ) {
    timer.expire();
  }
}

# read the property-tree
var timersNode = props.globals.getNode( "/sim/timers");
var timerNodes = timersNode.getChildren( "timer" );
foreach( var timer; timerNodes ) {
  createTimer( timer );
}
