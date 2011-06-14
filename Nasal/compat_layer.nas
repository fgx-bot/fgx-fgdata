
########################################################
# compatibility layer for local weather package
# Thorsten Renk, March 2011
########################################################

# function			purpose
#
# setDefaultCloudsOff		to remove the standard Flightgear 3d clouds
# setVisibility			to set the visibility to a given value
# setLift			to set lift to given value
# setRain			to set rain to a given value
# setSnow			to set snow to a given value
# setTurbulence			to set turbulence to a given value
# setTemperature		to set temperature to a given value
# setPressure			to set pressure to a given value
# setDewpoint			to set the dewpoint to a given value
# setLight			to set light saturation to given value
# setWind			to set wind
# setWindSmoothly 		to set the wind gradually across a second
# smooth_wind_loop		(helper function for setWindSmoothly)
# create_cloud			to place a single cloud into the scenery
# create_cloud_array		to place clouds from storage arrays into the scenery
# get_elevation			to get the terrain elevation at given coordinates
# get_elevation_vector		to get terrain elevation at given coordinate vector



# This file contains portability wrappers for the local weather system: 
#   http://wiki.flightgear.org/index.php/A_local_weather_system
#   
# This module is intended to provide a certain degree of backward compatibility for past 
# FlightGear releases, while sketching out the low level APIs used and required by the 
# local weather system, as these
# are being added to FlightGear.
#
# This file contains various workarounds for doing things that are currently not yet directly 
# supported by the core FlightGear/Nasal APIs (fgfs 2.0).
#
# Some of these workarounds are purely implemented in Nasal space, and may thus not provide sufficient
# performance in some situations.
#
# The goal is to move all such workarounds eventually  into this module, so that the high level weather modules
# only refer to this "compatibility layer" (using an "ideal API"), while this module handles 
# implementation details 
# and differences among different versions of FlightGear, so that key APIs can be ported to C++ space 
# for the sake
# of improving runtime performance and efficiency.
#
# This provides an abstraction layer that isolates the rest of the local weather system from low 
# level implementation details.
# 
# C++ developers who want to help improve the local weather system (or the FlightGear/Nasal 
# interface in general) should 
# check out this file (as well as the wiki page) for APIs or features that shall eventually be 
# re/implemented in C++ space for
# improving the local weather system.
#
# 
# This module provides a handful of helpers for dynamically querying the Nasal API of the running fgfs binary,
# so that it can make use of new APIs (where available), while still working with older fgfs versions.
#
# Note: The point of these helpers is that they should really only be used 
# by this module, and not in other parts/files of the 
# local weather system. Any hard coded special cases should be moved into this module.
#
# The compatibility layer is currently work in progress and will be extended as new Nasal 
# APIs are being added to FlightGear.


_setlistener("/sim/signals/nasal-dir-initialized", func { 

var result = "yes";

print("Compatibility layer: testing for hard coded support");

if (props.globals.getNode("/rendering/scene/saturation", 0) == nil)
	{result = "no"; features.can_set_light = 0;}
else
	{result = "yes"; features.can_set_light = 1;}
print("* can set light saturation:        "~result);


if (props.globals.getNode("/environment/terrain", 0) == nil)
	{result = "no"; features.terrain_presampling = 0;}
else
	{result = "yes"; features.terrain_presampling = 1;}
print("* hard coded terrain presampling:  "~result);

if ((props.globals.getNode("/environment/terrain/area[0]/enabled",1).getBoolValue() == 1) and (features.terrain_presampling ==1))
	{result = "yes"; features.terrain_presampling_active = 1;}
else
	{result = "no"; features.terrain_presampling_active = 0;}
print("* terrain presampling initialized: "~result);


if (props.globals.getNode("/environment/config/enabled", 0) == nil)
	{result = "no"; features.can_disable_environment = 0;}
else
	{result = "yes"; features.can_disable_environment = 1;}
print("* can disable global weather:      "~result);

#if (features.terrain_presampling_active == 1)
#	{
#	setlistener("/environment/terrain/area[0]/output/valid", func {local_weather.manage_hardcoded_presampling(); });
#	}

print("Compatibility layer: tests done.");
});



var setDefaultCloudsOff = func {

if (features.can_disable_environment == 1)
	{
	var layers = props.globals.getNode("/environment/clouds").getChildren("layer");
	
	foreach (l; layers)
		{
		l.getNode("coverage-type").setValue(5);
		}
	}
else
	{
	var layers = props.globals.getNode("/environment/clouds").getChildren("layer");

	foreach (l; layers)
		{
		l.getNode("coverage").setValue("clear");
		}
	}

}


####################################
# set visibility to given value
####################################

var setVisibility = func (vis) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/visibility-m",vis);
	}
else
	{
	# this is a workaround for systems which lack hard-coded support
	# essentially we update all entries in config and reinit environment

	var entries_aloft = props.globals.getNode("environment/config/aloft", 1).getChildren("entry");
	foreach (var e; entries_aloft) {
			e.getNode("visibility-m",1).setValue(vis);
			}

	var entries_boundary = props.globals.getNode("environment/config/boundary", 1).getChildren("entry");
	foreach (var e; entries_boundary) {
			e.getNode("visibility-m",1).setValue(vis);
			}
	fgcommand("reinit", props.Node.new({subsystem:"environment"}));
	}
}

####################################
# set thermal lift to given value
####################################

var setLift = func (lift) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/wind-from-down-fps",lift);
	}
}

####################################
# set rain to given value
####################################

var setRain = func (rain) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/rain-norm", rain);
	}
else
	{
	# setting the lowest cloud layer to 30.000 ft is a workaround
	# as rain is only created below that layer in default

	setprop("/environment/clouds/layer[0]/elevation-ft", 30000.0);
	setprop("/environment/metar/rain-norm",rain);
	}

}

####################################
# set snow to given value
####################################

var setSnow = func (snow) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/snow-norm", snow);
	}
else
	{
	# setting the lowest cloud layer to 30.000 ft is a workaround
	# as snow is only created below that layer in default

	setprop("environment/clouds/layer[0]/elevation-ft", 30000.0);
	setprop("environment/metar/snow-norm",snow);
	}
}


####################################
# set turbulence to given value
####################################

var setTurbulence = func (turbulence) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/turbulence/magnitude-norm",turbulence);
	setprop("/environment/turbulence/rate-hz",3.0);
	}

else
	{
	# this is a workaround for systems which lack hard-coded support
	# essentially we update all entries in config and reinit environment

	var entries_aloft = props.globals.getNode("environment/config/aloft", 1).getChildren("entry");
	foreach (var e; entries_aloft) {
			e.getNode("turbulence/magnitude-norm",1).setValue(turbulence);
			e.getNode("turbulence/rate-hz",1).setValue(3.0);
			e.getNode("turbulence/factor",1).setValue(1.0);
			}

	# turbulence is slightly reduced in boundary layers

	var entries_boundary = props.globals.getNode("environment/config/boundary", 1).getChildren("entry");
	var i = 1;
	foreach (var e; entries_boundary) {
			e.getNode("turbulence/magnitude-norm",1).setValue(turbulence * 0.25*i);
			e.getNode("turbulence/rate-hz",1).setValue(5.0);
			e.getNode("turbulence/factor",1).setValue(1.0);
			i = i + 1;
			}
	fgcommand("reinit", props.Node.new({subsystem:"environment"}));
	}
}


####################################
# set temperature to given value
####################################

var setTemperature = func (T) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/temperature-sea-level-degc",T);
	}
else
	{
	# this is a workaround for systems which lack hard-coded support
	# essentially we update the entry in config and reinit environment
	
	setprop(ec~"boundary/entry[0]/temperature-degc",T);
	fgcommand("reinit", props.Node.new({subsystem:"environment"}));
	}
}

####################################
# set pressure to given value
####################################

var setPressure = func (p) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/pressure-sea-level-inhg",p);
	}
else
	{
	# this is a workaround for systems which lack hard-coded support
	# essentially we update the entry in config and reinit environment

	setprop(ec~"boundary/entry[0]/pressure-sea-level-inhg",p);
	setprop(ec~"aloft/entry[0]/pressure-sea-level-inhg",p);
	fgcommand("reinit", props.Node.new({subsystem:"environment"}));
	}
}

####################################
# set dewpoint to given value
####################################

var setDewpoint = func (D) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/dewpoint-sea-level-degc",D);
	}
else
	{
	# this is a workaround for systems which lack hard-coded support
	# essentially we update the entry in config and reinit environment

	setprop(ec~"boundary/entry[0]/dewpoint-degc",D);
	fgcommand("reinit", props.Node.new({subsystem:"environment"}));
	}
}

####################################
# set light saturation to given value
####################################

var setLight = func (s) {

if (features.can_set_light == 1)
	{	
	setprop("/rendering/scene/saturation",s);
	}
}

###########################################################
# set wind to given direction and speed
###########################################################


var setWind = func (dir, speed) {

if (features.can_disable_environment == 1)
	{
	setprop("/environment/wind-from-heading-deg",dir);
	setprop("/environment/wind-speed-kt",speed);
	}
else
	{
	# this is a workaround for systems which lack hard-coded support
	# essentially we update all entries in config and reinit environment
	
	var entries_aloft = props.globals.getNode("environment/config/aloft", 1).getChildren("entry");
	foreach (var e; entries_aloft) {
			e.getNode("wind-from-heading-deg",1).setValue(dir);
			e.getNode("wind-speed-kt",1).setValue(speed);
			}

	var entries_boundary = props.globals.getNode("environment/config/boundary", 1).getChildren("entry");
	foreach (var e; entries_boundary) {
			e.getNode("wind-from-heading-deg",1).setValue(dir);
			e.getNode("wind-speed-kt",1).setValue(speed);
			}

	fgcommand("reinit", props.Node.new({subsystem:"environment"}));
	}
}

###########################################################
# set wind smoothly to given direction and speed
# interpolating across several frames
###########################################################


var setWindSmoothly = func (dir, speed) {

if (features.can_disable_environment == 1)
	{
	setWind(dir, speed);
	}
else
	{

	var entries_aloft = props.globals.getNode("environment/config/aloft", 1).getChildren("entry");

	var dir_old = entries_aloft[0].getNode("wind-from-heading-deg",1).getValue();
	var speed_old = entries_aloft[0].getNode("wind-speed-kt",1).getValue();

	var dir = dir * math.pi/180.0;
	var dir_old = dir_old * math.pi/180.0;

	var vx = speed * math.sin(dir);
	var vx_old = speed_old * math.sin(dir_old);

	var vy = speed * math.cos(dir);
	var vy_old = speed_old * math.cos(dir_old);

	smooth_wind_loop(vx,vy,vx_old, vy_old, 4, 4);
	}

}


var smooth_wind_loop = func (vx, vy, vx_old, vy_old, counter, count_max) {

var time_delay = 0.9/count_max;

if (counter == 0) {return;}

var f = (counter -1)/count_max;

var vx_set = f * vx_old + (1-f) * vx;
var vy_set = f * vy_old + (1-f) * vy;

var speed_set = math.sqrt(vx_set * vx_set + vy_set * vy_set);
var dir_set = math.atan2(vx_set,vy_set) * 180.0/math.pi;

setWind(dir_set,speed_set);

settimer( func {smooth_wind_loop(vx,vy,vx_old,vy_old,counter-1, count_max); },time_delay);

}

###########################################################
# place a single cloud 
###########################################################

var create_cloud = func(path, lat, long, alt, heading) {

var tile_counter = getprop(lw~"tiles/tile-counter");
var buffer_flag = getprop(lw~"config/buffer-flag");
var d_max = weather_tile_management.cloud_view_distance + 1000.0;


# check if we deal with a convective cloud

var convective_flag = 0;

if (find("cumulus",path) != -1)
	{
	if ((find("alto",path) != -1) or (find("cirro", path) != -1) or (find("strato", path) != -1))
		{convective_flag = 0;}
	else if ((find("small",path) != -1) or (find("whisp",path) != -1)) 
		{convective_flag = 1;}
	else if (find("bottom",path) != -1) 
		{convective_flag = 4;}
	else	
		{convective_flag = 2;}
	
	}
else if (find("congestus",path) != -1)
	{
	if (find("bottom",path) != -1) 
		{convective_flag = 5;}
	else
		{convective_flag = 3;}
	} 

#print("path: ", path, " flag: ", convective_flag);

# first check if the cloud should be stored in the buffer
# we keep it if it is in visual range or at high altitude (where visual range is different)

if (buffer_flag == 1)
	{
	# calculate the distance to the aircraft
	var pos = geo.aircraft_position();
	var cpos = geo.Coord.new();
	cpos.set_latlon(lat,long,0.0);
	var d = pos.distance_to(cpos);
	
	if ((d > d_max) and (alt < 20000.0)) # we buffer the cloud
		{
		var b = weather_tile_management.cloudBuffer.new(lat, long, alt, path, heading, tile_counter, convective_flag);
		if (local_weather.dynamics_flag ==1) 
			{
			b.timestamp = weather_dynamics.time_lw;
			if (convective_flag !=0) # Cumulus clouds get some extra info
				{
				b.evolution_timestamp = cloud_evolution_timestamp;
				b.flt = cloud_flt;
				b.rel_alt = alt - cloud_mean_altitude;
				}
			}
		append(weather_tile_management.cloudBufferArray,b);
		return;
		}
	}

# now check if we are writing from the buffer, in this case change tile index
# to buffered one

if (getprop(lw~"tmp/buffer-status") == "placing")
	{
	#tile_counter = getprop(lw~"tmp/buffer-tile-index");
	tile_counter = buffered_tile_index;
	}



# if the cloud is not buffered, get property tree nodes and write it 
# into the scenery

var n = props.globals.getNode("local-weather/clouds", 1);
var c = n.getChild("tile",tile_counter,1);


var cloud_number = n.getNode("placement-index").getValue();
		for (var i = cloud_number; 1; i += 1)
			if (c.getChild("cloud", i, 0) == nil)
				break;
	cl = c.getChild("cloud", i, 1);
	n.getNode("placement-index").setValue(i);

	var placement_index = i;

var model_number = n.getNode("model-placement-index").getValue();
var m = props.globals.getNode("models", 1);
		for (var i = model_number; 1; i += 1)
			if (m.getChild("model", i, 0) == nil)
				break;
	model = m.getChild("model", i, 1);
	n.getNode("model-placement-index").setValue(i);	



var latN = cl.getNode("position/latitude-deg", 1); latN.setValue(lat);
var lonN = cl.getNode("position/longitude-deg", 1); lonN.setValue(long);
var altN = cl.getNode("position/altitude-ft", 1); altN.setValue(alt);
var hdgN = cl.getNode("orientation/true-heading-deg", 1); hdgN.setValue(heading);

cl.getNode("tile-index",1).setValue(tile_counter);

model.getNode("path", 1).setValue(path);
model.getNode("latitude-deg-prop", 1).setValue(latN.getPath());
model.getNode("longitude-deg-prop", 1).setValue(lonN.getPath());
model.getNode("elevation-ft-prop", 1).setValue(altN.getPath());
model.getNode("heading-deg-prop", 1).setValue(hdgN.getPath());
model.getNode("tile-index",1).setValue(tile_counter);
model.getNode("load", 1).remove();


# sort the model node into a vector for easy deletion
# append(weather_tile_management.modelArrays[tile_counter-1],model);

# sort the cloud into the cloud hash array

if (buffer_flag == 1)
	{
	var cs = weather_tile_management.cloudScenery.new(tile_counter, convective_flag, cl, model);
	append(weather_tile_management.cloudSceneryArray,cs);
	}

# if weather dynamics is on, also create a timestamp property and sort the cloud hash into quadtree

if (local_weather.dynamics_flag == 1)
	{
	cs.timestamp = weather_dynamics.time_lw;
	cs.write_index = placement_index;

	if (convective_flag !=0) # Cumulus clouds get some extra info
			{
			cs.evolution_timestamp = cloud_evolution_timestamp;
			cs.flt = cloud_flt;
			cs.rel_alt = alt - cloud_mean_altitude;
			cs.target_alt = alt;
			}

	if (getprop(lw~"tmp/buffer-status") == "placing")
		{
		var blat = buffered_tile_latitude;
		var blon = buffered_tile_longitude;
		var alpha = buffered_tile_alpha;
		#var blat1 = getprop(lw~"tiles/tmp/latitude-deg");
		#var blon1 = getprop(lw~"tiles/tmp/longitude-deg");
		#var alpha1 = getprop(lw~"tmp/tile-orientation-deg");

		#print("Lat: ", blat1, " ", blat);
		#print("Lon: ", blon1, " ", blon);
		#print("Alp: ", alpha1, " ", alpha);
		
		}
	else
		{
		var blat = getprop(lw~"tiles/tmp/latitude-deg");
		var blon = getprop(lw~"tiles/tmp/longitude-deg");
		var alpha = getprop(lw~"tmp/tile-orientation-deg");
		}
	weather_dynamics.sort_into_quadtree(blat, blon, alpha, lat, long, weather_dynamics.cloudQuadtrees[tile_counter-1], cs); 
	}

}


###########################################################
# place a cloud layer from arrays, split across frames 
###########################################################

var create_cloud_array = func (i, clouds_path, clouds_lat, clouds_lon, clouds_alt, clouds_orientation) {

if (getprop(lw~"tmp/thread-status") != "placing") {return;}
if (getprop(lw~"tmp/convective-status") != "idle") {return;}
if ((i < 0) or (i==0)) 
	{
	if (local_weather.debug_output_flag == 1) 
		{print("Cloud placement from array finished!"); }
	setprop(lw~"tmp/thread-status", "idle");

	# now set flag that tile has been completely processed
	var dir_index = props.globals.getNode(lw~"tiles/tmp/dir-index").getValue();

	props.globals.getNode(lw~"tiles").getChild("tile",dir_index).getNode("generated-flag").setValue(2);
	
	return;
	}


var k_max = 30;
var s = size(clouds_path);  

if (s < k_max) {k_max = s;}

for (var k = 0; k < k_max; k = k+1)
	{
	if (getprop(lw~"config/dynamics-flag") ==1)
		{
		cloud_mean_altitude = local_weather.clouds_mean_alt[s-k-1];
		cloud_flt = local_weather.clouds_flt[s-k-1];
		cloud_evolution_timestamp = local_weather.clouds_evolution_timestamp[s-k-1];
		}
	create_cloud(clouds_path[s-k-1], clouds_lat[s-k-1], clouds_lon[s-k-1], clouds_alt[s-k-1], clouds_orientation[s-k-1]);
	}

setsize(clouds_path,s-k_max);
setsize(clouds_lat,s-k_max);
setsize(clouds_lon,s-k_max);
setsize(clouds_alt,s-k_max);
setsize(clouds_orientation,s-k_max);

if (getprop(lw~"config/dynamics-flag") ==1)
		{
		setsize(local_weather.clouds_mean_alt,s-k_max);
		setsize(local_weather.clouds_flt,s-k_max);
		setsize(local_weather.clouds_evolution_timestamp,s-k_max);
		}

settimer( func {create_cloud_array(i - k, clouds_path, clouds_lat, clouds_lon, clouds_alt, clouds_orientation ) }, 0 );
};








###########################################################
# get terrain elevation
###########################################################

var get_elevation = func (lat, lon) {

var info = geodinfo(lat, lon);
	if (info != nil) {var elevation = info[0] * local_weather.m_to_ft;}
	else {var elevation = -1.0; }


return elevation;
}

###########################################################
# get terrain elevation vector
###########################################################

var get_elevation_array = func (lat, lon) {

var elevation = [];
var n = size(lat);


for(var i = 0; i < n; i=i+1)
	{
	append(elevation, get_elevation(lat[i], lon[i]));
	}
	

return elevation;
}



############################################################
# global variables
############################################################

# some common abbreviations

var lw = "/local-weather/";
var ec = "/environment/config/";

# storage arrays for model vector

var mvec = [];
var msize = 0;

# available hard-coded support

var features = {};

# globals to transmit info if clouds are written from buffer

var buffered_tile_latitude = 0.0;
var buffered_tile_longitude = 0.0;
var buffered_tile_alpha = 0.0;
var buffered_tile_index = 0;

# globals to handle additional info for Cumulus cloud dynamics

var cloud_mean_altitude = 0.0;
var cloud_flt = 0.0;
var cloud_evolution_timestamp = 0.0;
