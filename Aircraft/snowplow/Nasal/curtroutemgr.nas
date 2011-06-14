# route manager

var routes_node = props.globals.getNode("/routes", 1);
var route_node = nil;
var route_num = 0;
var wpt_num = 0;
var next_wpt = geo.Coord.new();
var course = 0.0;
var dist = 0.0;

var setRoute = func( num ) {
    route_num = num;
    route_node = routes_node.getChild("route", route_num);
}

var setWaypoint = func( num ) {
    wpt_num = num;
    var wpt_node = route_node.getChild("wpt", wpt_num);
    if ( wpt_node == nil ) {
        wpt_num = 0;
        wpt_node = route_node.getChild("wpt", wpt_num);
    }
    next_wpt.set_latlon( wpt_node.getChild("lat").getValue(),
                         wpt_node.getChild("lon").getValue() );
}


var incrWaypoint = func() {
    wpt_num += 1;
    setWaypoint( wpt_num );
}


var routeInit = func {
    setRoute(0);
    setWaypoint(0);
}


var routeUpdate = func( dt ) {
    var location = geo.aircraft_position();
    dist = location.distance_to( next_wpt );
    course = location.course_to( next_wpt );

    # print("route c/d = ", course, " ", dist);

    if ( dist < 10.0 ) {
        incrWaypoint();
    }
}
