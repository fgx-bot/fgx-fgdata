
########################################################
# routines to set up weather tiles
# Thorsten Renk, March 2011
########################################################

# function			purpose
#
# tile_start			to execute jobs common for all tiles on startup
# tile_finished			to execute jobs common for all tiles when tile creation is done
# set_NN_tile			to set a weather tile of type NN
# create_NN			to create the cloud configuration NN
# adjust_p			to make sure pressure variation cannot exceed limits between tiles
# calc_geo			to get local Cartesian geometry for latitude conversion
# get_lat			to get latitude from Cartesian coordinates
# get_lon			to get longitude from Cartesian coordinates

####################################
# tile setup calls
####################################

var tile_start = func {

# set thread lock
if (local_weather.thread_flag == 1){setprop(lw~"tmp/thread-status","computing");}

# set the tile code
var current_code = getprop(lw~"tiles/code");
var dir_index = getprop(lw~"tiles/tmp/dir-index");	
props.globals.getNode(lw~"tiles").getChild("tile",dir_index).getNode("code").setValue(current_code);

#print(current_code, getprop(lw~"tiles/tmp/code"));

if (current_code != getprop(lw~"tiles/tmp/code"))
	{weather_tiles.rnd_store = rand();}

# generate a handling array for models

var array = [];
append(weather_tile_management.modelArrays,array);


}

var tile_finished = func {

var current_code = getprop(lw~"tiles/code");

setprop(lw~"clouds/placement-index",0);
setsize(elat,0); setsize(elon,0); setsize(erad,0);

var dir_index = getprop(lw~"tiles/tmp/dir-index");	
#props.globals.getNode(lw~"tiles").getChild("tile",dir_index).getNode("code").setValue(current_code);

local_weather.assemble_effect_array();

if (local_weather.debug_output_flag == 1) 
	{print("Finished setting up tile type ",current_code, " in direction ",dir_index);}

if (local_weather.thread_flag == 1)
	{setprop(lw~"tmp/thread-status","placing");}
else 	# without worker threads, tile generation is complete at this point
	{props.globals.getNode(lw~"tiles").getChild("tile",dir_index).getNode("generated-flag").setValue(2);}


}





####################################
# test tile
####################################

var set_4_8_stratus_tile = func {

setprop(lw~"tiles/code","test");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# first weather info for tile center (lat, lon, visibility, temperature, dew point, pressure)

local_weather.set_weather_station(blat, blon, alt_offset, 20000.0, 14.0, 12.0, 29.78);

# create_8_8_nimbus_var3(blat, blon, 2000.0 + alt_offset+local_weather.cloud_vertical_size_map["Nimbus"] * 0.5 * m_to_ft, 0.0);

#create_2_8_sstratus_streak(blat, blon,5000.0,0.0);

#create_4_8_cirrocumulus_bank(blat, blon, 6000.0, 0.0);

#create_4_8_cirrocumulus_streaks(blat, blon, 6000.0, 0.0);

# create_2_8_cirrocumulus(blat, blon, 6000.0, 0.0);

create_detailed_small_stratocumulus_bank(blat, blon,3000.0+alt_offset,0.0);

#create_4_8_altocumulus_perlucidus(blat, blon, 10000.0, 0.0);

#local_weather.create_effect_volume(3, blat, blon, 20000.0, 7000.0, alpha, 0.0, 80000.0, -1, -1, -1, -1, 15.0, -3,-1);

create_1_8_contrails(blat, blon, 30000.0, 0.0);

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,3000.0);
append(weather_dynamics.tile_convective_strength,0.0);


tile_finished();

}


####################################
# high pressure core
####################################

var set_high_pressure_core_tile = func {

setprop(lw~"tiles/code","high_pressure_core");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 30000.0 + rand() * 15000.0;
var T = 20.0 + rand() * 10.0;
var spread = 5.0 + 3.0 * rand();
var D = T - spread;
var p = 1025.0 + rand() * 6.0; p = adjust_p(p);

# and set them at the tile center
local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);


var alt = spread * 1000;
var strength = 0.0;


var rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}


if (rn > 0.8)
	{
	# cloud scenario 1: weak cumulus development and blue thermals

	strength = rand() * 0.05;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	# generate a few blue thermals

	if (local_weather.generate_thermal_lift_flag !=0)
		{
		local_weather.generate_thermal_lift_flag = 3;
		strength = rand() * 0.4;
		local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
		local_weather.generate_thermal_lift_flag = 2;
		}
	
	}
else if (rn > 0.6)
	{
	# cloud scenario 2: some Cirrocumulus patches
	
	strength = rand() * 0.03;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	create_2_8_cirrocumulus(blat, blon, alt + alt_offset + 5000.0, alpha);

	create_2_8_cirrus(blat, blon, alt + alt_offset + 35000.0, alpha);
	}
else if (rn > 0.4)
	{
	# cloud scenario 3: Cirrostratus undulatus over weak cumulus
		
	strength = rand() * 0.03;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	create_4_8_cirrostratus_undulatus(blat, blon, alt + alt_offset + 32000.0, alpha);
	}
else if (rn > 0.2)
	{
	# cloud scenario 4: Cirrostratus undulatus streak

	strength = rand() * 0.03;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	create_1_8_cirrostratus_undulatus(blat, blon, alt + alt_offset + 32000.0, alpha);
	}
else if (rn > 0.0)
	{
	# cloud scenario 5: Cirrus

	create_2_8_cirrus(blat, blon, alt + alt_offset + 35000.0, alpha);


	create_1_8_cirrostratus_undulatus(blat, blon, alt + alt_offset + 28000.0, alpha);


	create_1_8_cirrostratus_undulatus(blat, blon, alt + alt_offset + 28000.0, alpha);
	}


# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);


tile_finished();

}


####################################
# high pressure 
####################################

var set_high_pressure_tile = func {

setprop(lw~"tiles/code","high_pressure");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 25000.0 + rand() * 15000.0;
var T = 15.0 + rand() * 10.0;
var spread = 4.0 + 2.0 * rand();
var D = T - spread;
var p = 1019.0 + rand() * 6.0; p = adjust_p(p);

# and set them at the tile center
local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);


var alt = spread * 1000;
var strength = 0.0;



var rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}

# rn = 0.1;

if (rn > 0.8)
	{
	# cloud scenario 1: possible Cirrus over Cumulus
	strength = 0.2 + rand() * 0.4;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	# one or two Cirrus clouds

	x = 2000.0 + rand() * 16000.0;
	y = 2.0 * (rand()-0.5) * 18000;
	var path = local_weather.select_cloud_model("Cirrus", "small");
	compat_layer.create_cloud(path, blat + get_lat(x,y,phi), blon+get_lon(x,y,phi),  alt + alt_offset + 25000.0 + rand() * 5000.0,alpha);
	
	if (rand() > 0.5)
		{
		x = -2000.0 - rand() * 16000.0;
		y = 2.0 * (rand()-0.5) * 18000;
		var path = local_weather.select_cloud_model("Cirrus", "small");
		compat_layer.create_cloud(path, blat + get_lat(x,y,phi), blon+get_lon(x,y,phi),  alt + alt_offset +25000.0 + rand() * 5000.0,alpha);
		}	

	}
else if (rn > 0.6)
	{
	# cloud scenario 2: Cirrostratus over weak Cumulus

	strength = 0.2 + rand() * 0.2;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	create_2_8_cirrostratus(blat, blon, alt+alt_offset+25000.0, alpha);
	}

else if (rn > 0.4)
	{
	# cloud scenario 3: Cirrocumulus sheet over Cumulus

	strength = 0.2 + rand() * 0.2;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
	
	x = 2.0 * (rand()-0.5) * 5000;
	y = 2.0 * (rand()-0.5) * 5000;


	var path = local_weather.select_cloud_model("Cirrocumulus", "large");
	compat_layer.create_cloud(path, blat + get_lat(x,y,phi), blon+get_lon(x,y,phi),  alt + alt_offset +24000,alpha);

	}
else if (rn > 0.2)
	{
	# cloud scenario 4: Cirrostratus undulatus over weak Cumulus

	strength = 0.15 + rand() * 0.15;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	create_4_8_cirrostratus_undulatus(blat, blon, alt + alt_offset + 25000.0, alpha);
	}
else if (rn > 0.0)
	{
	# cloud scenario 5: some scattered Altocumuli over Cumulus

	strength = 0.25 + rand() * 0.1;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	create_1_8_altocumulus_scattered(blat, blon, alt+alt_offset+10000.0, alpha);	

	create_1_8_cirrostratus_undulatus(blat, blon, alt + alt_offset + 25000.0, alpha);
	}

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);


tile_finished();

}


####################################
# high pressure border
####################################

var set_high_pressure_border_tile = func {

setprop(lw~"tiles/code","high_pressure_border");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 20000.0 + rand() * 12000.0;
var T = 12.0 + rand() * 10.0;
var spread = 3.0 + 2.0 * rand();
var D = T - spread;
var p = 1013.0 + rand() * 6.0; p = adjust_p(p);

# and set them at the tile center
local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);


# now a random selection of different possible cloud configuration scenarios

var alt = spread * 1000;
var strength = 0.0;

var rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}

if (rn > 0.875)
	{
	# cloud scenario 1: Altocumulus patch over weak Cumulus
	strength = 0.1 + rand() * 0.1;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	x = 2.0 * (rand()-0.5) * 5000;
	y = 2.0 * (rand()-0.5) * 5000;
	local_weather.create_streak("Altocumulus",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 12000.0+alt+alt_offset,1500.0,30,1000.0,0.2,1200.0,30,1000.0,0.2,1200.0,alpha ,1.0);

	}
else if (rn > 0.750)
	{
	# cloud scenario 2: Altocumulus streaks
	strength = 0.15 + rand() * 0.2;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	x = 2.0 * (rand()-0.5) * 10000;
	y = 2.0 * (rand()-0.5) * 10000;
	local_weather.create_streak("Altocumulus",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 12000.0+alt+alt_offset,1500.0,25,700.0,0.2,800.0,10,700.0,0.2,800.0,alpha ,1.4);
	x = 2.0 * (rand()-0.5) * 10000;
	y = 2.0 * (rand()-0.5) * 10000;
	local_weather.create_streak("Altocumulus",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 12000.0+alt+alt_offset,1500.0,22,750.0,0.2,1000.0,8,750.0,0.2,1000.0,alpha ,1.1);

	}
else if (rn > 0.625)
	{
	# cloud scenario 3: Cirrus

	strength = 0.1 + rand() * 0.1;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	x = 2.0 * (rand()-0.5) * 3000;
	y = 2.0 * (rand()-0.5) * 3000;
	local_weather.create_streak("Cirrus",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 22000.0+alt+alt_offset,1500.0,3,9000.0,0.0, 800.0, 1,8000.0,0.0,800,0,alpha ,1.0);

	}
else if (rn > 0.5)
	{
	# cloud scenario 4: Cumulonimbus banks

	strength = 0.7 + rand() * 0.3;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	for (var i = 0; i < 3; i = i + 1)
		{
		x = 2.0 * (rand()-0.5) * 16000;
		y = 2.0 * (rand()-0.5) * 16000;
	
		create_cloud_bank("Cumulonimbus", blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset, 1600.0, 800.0, 3000.0, 9, alpha);
		}
	}
else if (rn > 0.375)
	{
	# cloud scenario 5: scattered Stratus

	strength = 0.4 + rand() * 0.2;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	var size_offset = 0.5 * m_to_ft * local_weather.cloud_vertical_size_map["Stratus_structured"];

	local_weather.create_streak("Stratus (structured)",blat, blon, alt+6000.0+alt_offset+size_offset,1000.0,18,0.0,0.3,20000.0,18,0.0,0.3,20000.0,0.0,1.0);

	}
else if (rn > 0.250)
	{
	# cloud scenario 6: Cirrocumulus sheets

	strength = 0.2 + rand() * 0.2;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
	

	for (var i = 0; i < 2; i = i + 1)
		{
		x = 2.0 * (rand()-0.5) * 10000;
		y = -6000 + i * 12000 + 2.0 * (rand()-0.5) * 1000;

		var beta = rand() * 90;
		var alt_variation = rand() * 2000;

		var path = local_weather.select_cloud_model("Cirrocumulus", "large");
		compat_layer.create_cloud(path, blat + get_lat(x,y,phi), blon+get_lon(x,y,phi),  alt + alt_offset +20000+ alt_variation,alpha+ beta);
		}
	}
else if (rn > 0.125)
	{
	# cloud scenario 7: Thin Cirrocumulus sheets over weak Cumulus

	strength = 0.05 + rand() * 0.1;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
	
	create_4_8_cirrocumulus_streaks(blat, blon, alt + 6000.0 + alt_offset, alpha);

	}
else if (rn > 0.0)
	{
	# cloud scenario 8: Altocumulus perlucidus
	
	create_4_8_altocumulus_perlucidus(blat, blon, alt + 10000.0 + alt_offset, alpha);

	create_2_8_cirrus(blat, blon, alt + 30000.0 + alt_offset, alpha);
	}


# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);


tile_finished();

}

####################################
# low pressure border
####################################

var set_low_pressure_border_tile = func {

setprop(lw~"tiles/code","low_pressure_border");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;


var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");


# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 12000.0 + rand() * 9000.0;
var T = 10.0 + rand() * 10.0;
var spread = 2.0 + 2.0 * rand();
var D = T - spread;
var p = 1007.0 + rand() * 6.0; p = adjust_p(p);

# and set them at the tile center
local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0;
var strength = 0.0;

# now a random selection of different possible cloud configuration scenarios

var rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}

# rn = 0.1;

if (rn > 0.857)
	{
	# cloud scenario 1: low Stratocumulus, thin streaks above

	strength = 0.05 + rand() * 0.1;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	create_detailed_stratocumulus_bank(blat, blon, alt+alt_offset,alpha);

	create_4_8_alttstratus_streaks(blat, blon, alt+alt_offset+4000.0,alpha);
	}
else if (rn > 0.714)
	{
	# cloud scenario 2: weak Cumulus, Stratus undulatus above

	strength = 0.15 + rand() * 0.15;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
	
	create_6_8_tstratus_undulatus(blat, blon, alt+alt_offset+4000.0,alpha);

	create_2_8_alttstratus(blat, blon, alt+alt_offset+7000.0,alpha);
	}
else if (rn > 0.571)
	{
	# cloud scenario 3: Stratocumulus banks with patches above

	create_detailed_stratocumulus_bank(blat, blon, alt+alt_offset,alpha);
	create_detailed_small_stratocumulus_bank(blat, blon, alt+alt_offset,alpha);

	create_4_8_alttstratus_patches(blat, blon, alt+alt_offset+4000.0,alpha);
	}
else if (rn > 0.428)
	{
	# cloud scenario 4: structured Stratus
	
	alt = alt + local_weather.cloud_vertical_size_map["Stratus"] * 0.5 * m_to_ft;
	create_4_8_sstratus_patches(blat, blon, alt+alt_offset,alpha);

	create_2_8_alttstratus(blat, blon, alt+alt_offset+7000.0,alpha);
	}
else if (rn > 0.285)
	{
	# cloud scenario 5: Stratus blending with Cumulus with Cirrocumulus above
	
	strength = 0.1 + rand() * 0.1;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	create_4_8_tstratus_patches(blat, blon, alt+alt_offset,alpha);

	create_4_8_cirrocumulus_undulatus(blat, blon, alt+alt_offset + 12000.0,alpha);
	}
else if (rn > 0.142)
	{
	# cloud scenario 6: small Stratocumulus banks
	
	create_detailed_small_stratocumulus_bank(blat, blon, alt+alt_offset,alpha);
	create_detailed_small_stratocumulus_bank(blat, blon, alt+alt_offset,alpha);

	create_4_8_tstratus_patches(blat, blon, alt+alt_offset,alpha);

	create_2_8_cirrostratus(blat, blon, alt+alt_offset + 25000.0,alpha);
	}
else
	{
	# cloud scenario 7: blended structured and unstructured Stratiform clouds

	create_4_8_tstratus_patches(blat, blon, alt+alt_offset,alpha);
	create_4_8_sstratus_patches(blat, blon, alt+alt_offset,alpha);

	create_2_8_cirrostratus(blat, blon, alt+alt_offset + 25000.0,alpha);
	}



# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}

####################################
# low pressure 
####################################

var set_low_pressure_tile = func {

setprop(lw~"tiles/code","low_pressure");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;


if (getprop(lw~"tmp/presampling-flag") == 0)
	{var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");}
else
	{var alt_offset = getprop(lw~"tmp/tile-alt-layered-ft");}

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 8000.0 + rand() * 8000.0;
var T = 5.0 + rand() * 10.0;
var spread = 1.0 + 2.0 * rand();
var D = T - spread;
var p = 1001.0 + rand() * 6.0; p = adjust_p(p);



# and set them at the tile center
local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0;
var strength = 0.0;

var rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}

if (rn > 0.75)
	{

	# cloud scenario 1: two patches of Nimbostratus with precipitation
	# overhead broken stratus layers
	# cloud count 1050

	x = 2.0 * (rand()-0.5) * 11000.0;
	y = 2.0 * (rand()-0.5) * 11000.0;
	var beta = rand() * 360.0;

	local_weather.create_layer("Nimbus", blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset, 500.0, 12000.0, 7000.0, beta, 1.0, 0.2, 1, 1.0);
	local_weather.create_effect_volume(2, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 10000.0, 6000.0, beta, 0.0, alt + alt_offset, 5000.0, 0.3, -1, -1, -1,0,-1 );
	local_weather.create_effect_volume(2, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 9000.0, 5000.0, beta, 0.0, alt+alt_offset-300.0, 1500.0, 0.5, -1, -1, -1,0,-1 );

	x = 2.0 * (rand()-0.5) * 11000.0;
	y = 2.0 * (rand()-0.5) * 11000.0;
	var beta = rand() * 360.0;

	local_weather.create_layer("Nimbus", blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset, 500.0, 10000.0, 6000.0, beta, 1.0, 0.2, 1, 1.0);
	local_weather.create_effect_volume(2, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 9000.0, 5000.0, beta, 0.0, alt + alt_offset, 5000.0, 0.3, -1, -1, -1,0 ,-1);
	local_weather.create_effect_volume(2, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 8000.0, 4000.0, beta, 0.0, alt+alt_offset-300.0, 1500.0, 0.5, -1, -1, -1,0,-1 );

	create_4_8_sstratus_undulatus(blat, blon, alt+alt_offset +3000.0, alpha);
	create_2_8_tstratus(blat, blon, alt+alt_offset +6000.0, alpha);
	}
else if (rn >0.5)
	{
	# cloud scenario 2: 8/8 Stratus with light precipitation
	# above broken cover
	# cloud count 1180

	alt = alt + local_weather.cloud_vertical_size_map["Stratus"] * 0.5 * m_to_ft;
	create_8_8_stratus(blat, blon, alt+alt_offset,alpha);
	local_weather.create_effect_volume(3, blat, blon, 18000.0, 18000.0, 0.0, 0.0, 1800.0, 8000.0, -1, -1, -1, -1, 0,-1);
	local_weather.create_effect_volume(3, blat, blon, 14000.0, 14000.0, 0.0, 0.0, 1500.0, 6000.0, 0.1, -1, -1, -1,0,-1 );
	create_2_8_sstratus(blat, blon, alt+alt_offset+3000,alpha);
	}
else if (rn >0.25)
	{
	# cloud scenario 3: multiple broken layers
	# cloud count 1350

	alt = alt + local_weather.cloud_vertical_size_map["Stratus"] * 0.5 * m_to_ft;
	create_4_8_stratus(blat, blon, alt+alt_offset,alpha);
	create_4_8_stratus_patches(blat, blon, alt+alt_offset+3000,alpha);
	create_4_8_sstratus_undulatus(blat, blon, alt+alt_offset+6000,alpha);
	create_2_8_tstratus(blat, blon, alt+alt_offset+8000,alpha);
	}
else if (rn >0.0)
	{
	# cloud scenario 4: a low 6/8 layer and some clouds above
	# cloud count 650

	alt = alt + local_weather.cloud_vertical_size_map["Stratus"] * 0.5 * m_to_ft;
	create_6_8_stratus(blat, blon, alt+alt_offset,alpha);
	create_2_8_sstratus(blat, blon, alt+alt_offset+6000,alpha);
	}
	
# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}


####################################
# low pressure core
####################################

var set_low_pressure_core_tile = func {

setprop(lw~"tiles/code","low_pressure_core");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;

if (getprop(lw~"tmp/presampling-flag") == 0)
	{var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");}
else
	{var alt_offset = getprop(lw~"tmp/tile-alt-layered-ft");}

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 5000.0 + rand() * 5000.0;
var T = 3.0 + rand() * 7.0;
var spread = 1.0 + 1.0 * rand();
var D = T - spread;
var p = 995.0 + rand() * 6.0; p = adjust_p(p);

# and set them at the tile center
local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);


# set a closed Nimbostratus layer

var alt = spread * 1000.0 + local_weather.cloud_vertical_size_map["Nimbus"] * 0.5 * m_to_ft;
var strength = 0.0;


create_8_8_nimbus_rain(blat, blon, alt+alt_offset, alpha,0.4 + rand()*0.2);

# and a precipitation layer below, more rain in the center of the tile

#local_weather.create_effect_volume(3, blat, blon, 20000.0, 20000.0, alpha, 0.0, alt + alt_offset, 3000.0, 0.3, -1, -1, -1,0 ,0.95);
#local_weather.create_effect_volume(3, blat , blon, 16000.0, 16000.0, alpha, 0.0, alt + alt_offset - 300.0, 1500.0, 0.5, -1, -1, -1,0 ,0.8);


# and some broken Stratus cover above

var rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}

if (rn > 0.5){create_4_8_stratus_patches(blat, blon, alt+alt_offset+3000.0, alpha);}
else {create_4_8_stratus(blat, blon, alt+alt_offset+3000.0, alpha);}

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}


####################################
# cold sector
####################################

var set_cold_sector_tile = func {

setprop(lw~"tiles/code","cold_sector");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 35000.0 + rand() * 20000.0;
var T = 8.0 + rand() * 8.0;
var spread = 3.0 + 2.0 * rand();
var D = T - spread;
var p = 1005.0 + rand() * 10.0; p = adjust_p(p);

# and set them at the tile center
local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0;
var strength = 0.0;

var rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}

#rn = 0.1;

if (rn > 0.5)
	{
	# cloud scenario 1: strong Cumulus development
	strength = 0.8 + rand() * 0.2;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
	}

else if (rn > 0.0)
	{
	# cloud scenario 2: Cirrocumulus sheets over Cumulus

	strength = 0.6 + rand() * 0.2;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
	
	for (var i = 0; i < 2; i = i + 1)
		{
		x = 2.0 * (rand()-0.5) * 10000;
		y = -6000 + i * 12000 + 2.0 * (rand()-0.5) * 1000;

		var beta = rand() * 90;
		var alt_variation = rand() * 2000;

		var path = local_weather.select_cloud_model("Cirrocumulus", "large");
		compat_layer.create_cloud(path, blat + get_lat(x,y,phi), blon+get_lon(x,y,phi),  alt + alt_offset +20000+ alt_variation,alpha+ beta);
		}

	}

#local_weather.create_effect_volume(3, blat, blon, 20000.0, 7000.0, alpha, 0.0, 80000.0, -1, -1, -1, -1, 15.0, -3,-1);

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}


####################################
# Warm sector
####################################

var set_warm_sector_tile = func {

setprop(lw~"tiles/code","warm_sector");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 10000.0 + rand() * 8000.0;
var T = 16.0 + rand() * 10.0;
var spread = 2.0 + 2.0 * rand();
var D = T - spread;
var p = 1005.0 + rand() * 10.0; p = adjust_p(p);

# and set them at the tile center
local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0;
var strength = 0.0;

var rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}

if (rn > 0.8)
	{
	# cloud scenario 1: weak Cumulus development, some Cirrostratus
	strength = 0.3 + rand() * 0.2;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
	create_4_8_cirrostratus_patches(blat, blon, alt+alt_offset+25000.0, alpha);
	}
else if (rn > 0.6)	
	{
	# cloud scenario 2: weak Cumulus development under Altostratus streaks
	strength = 0.1 + rand() * 0.1;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	var size_offset = 0.5 * m_to_ft * local_weather.cloud_vertical_size_map["Stratus_structured"];

	create_2_8_sstratus_streak(blat, blon, alt+alt_offset + size_offset + 2000.0, alpha);
	create_2_8_sstratus_streak(blat, blon, alt+alt_offset + size_offset + 4000.0, alpha);
	}
else if (rn > 0.4)	
	{
	# cloud scenario 3: Cirrocumulus bank
	strength = 0.05 + rand() * 0.05;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	var size_offset = 0.5 * m_to_ft * local_weather.cloud_vertical_size_map["Cirrocumulus"];

	create_4_8_cirrocumulus_bank(blat, blon, alt+alt_offset + size_offset + 7000.0, alpha);

	}
else if (rn > 0.2)	
	{
	# cloud scenario 4: Cirrocumulus undulatus
	strength = 0.05 + rand() * 0.05;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);

	var size_offset = 0.5 * m_to_ft * local_weather.cloud_vertical_size_map["Cirrocumulus"];

	create_4_8_cirrocumulus_undulatus(blat, blon, alt+alt_offset + size_offset + 6000.0, alpha);
	}

else if (rn > 0.0)
	{
	# cloud scenario 5: weak Cumulus development under scattered Altostratus 

	strength = 0.15 + rand() * 0.15;
	local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);	

	var size_offset = 0.5 * m_to_ft * local_weather.cloud_vertical_size_map["Stratus_structured"];
	
	local_weather.create_streak("Stratus (structured)",blat, blon, alt+4000.0+alt_offset+size_offset,1000.0,14,0.0,0.3,20000.0,14,0.0,0.3,20000.0,0.0,1.0);

	}

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}



####################################
# Tropical weather
####################################

var set_tropical_weather_tile = func {

setprop(lw~"tiles/code","tropical_weather");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var sec_to_rad = 2.0 * math.pi/86400; # conversion factor for sinusoidal dependence on daytime

# get the local time of the day in seconds

var t = getprop("sim/time/utc/day-seconds");
t = t + getprop("sim/time/local-offset");

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 10000.0 + rand() * 10000.0;
var T = 20.0 + rand() * 15.0;
var spread = 3.0 + 2.0 * rand();
var D = T - spread;
var p = 970 + rand() * 10.0; p = adjust_p(p);

# first weather info for tile center (lat, lon, visibility, temperature, dew point, pressure)

local_weather.set_weather_station(blat, blon, alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0;
var strength = 0.0;

# tropical weather has a strong daily variation, call thunderstorm only in the correct afternoon time window

var t_factor = 0.5 * (1.0-math.cos((t * sec_to_rad)-0.9)); 

var rn = rand();


if (rn > (t_factor * t_factor * t_factor * t_factor)) # call a normal convective cloud system
{
strength = 1.0 + rand() * 0.2;
local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);
}

else 
{

# a random selection of different possible thunderstorm cloud configuration scenarios

rn = rand();

if (rand() < small_scale_persistence)
	{rn = rnd_store;}
else
	{rnd_store = rn;}

if (rn > 0.2)
	{
	# cloud scenario 1: 1-2 medium sized storms

	x = 2.0 * (rand()-0.5) * 12000;
	y = 2.0 * (rand()-0.5) * 12000;

	if (rand() > 0.6)
		{create_medium_thunderstorm(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt+alt_offset, alpha);}
	else	
		{create_small_thunderstorm(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt+alt_offset, alpha);}

	if (rand() > 0.5) # we do a second thunderstorm
		{
		x = 2.0 * (rand()-0.5) * 12000;
		y = 2.0 * (rand()-0.5) * 12000;
		if (rand() > 0.8)
			{create_medium_thunderstorm(blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset, alpha);}
		else
			{create_small_thunderstorm(blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset, alpha);}
		}
	}
else if (rn > 0.0)
	{
	# cloud scenario 2: Single big storm

	x = 2.0 * (rand()-0.5) * 12000;
	y = 2.0 * (rand()-0.5) * 12000;

	create_big_thunderstorm(blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset, alpha);
	}


# the convective layer

var strength = 0.5 * t_factor;
var n = int(4000 * strength) * 0.2;
local_weather.cumulus_exclusion_layer(blat, blon, alt+alt_offset, n, 20000.0, 20000.0, alpha, 0.3,1.4 , size(elat), elat, elon, erad);
local_weather.cumulus_exclusion_layer(blat, blon, alt+alt_offset, n, 20000.0, 20000.0, alpha, 1.9,2.5 , size(elat), elat, elon, erad);

# some turbulence in the convection layer

local_weather.create_effect_volume(3, blat, blon, 20000.0, 20000.0, alpha, 0.0, alt+3000.0+alt_offset, -1, -1, -1, 0.4, -1,0 ,-1);

} # end thundercloud placement

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}


####################################
# Coldfront
####################################


var set_coldfront_tile = func {

setprop(lw~"tiles/code","coldfront");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;



var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 20000.0 + rand() * 10000.0;
var T = 20.0 + rand() * 8.0;
var spread = 3.0 + 2.0 * rand();
var D = T - spread;
var p = 1005 + rand() * 10.0; p = adjust_p(p);

# first weather info for tile  (lat, lon, visibility, temperature, dew point, pressure)

# after the front

x = 15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T-3.0, D-3.0, p * hp_to_inhg);

x = -15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T-3.0, D-3.0, p * hp_to_inhg);

# before the front

x = 15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis*0.7, T+3.0, D+3.0, (p-2.0) * hp_to_inhg);

x = -15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis*0.7, T+3.0, D+3.0, (p-2.0) * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0;
var strength = 0.0;

# thunderstorms first

for (var i =0; i < 3; i=i+1)
	{
	x = 2.0 * (rand()-0.5) * 15000;
	y = 2.0 * (rand()-0.5) * 2000 + 5000.0;
	if (rand() > 0.7)
		{create_medium_thunderstorm(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt+alt_offset, alpha);}
	else	
		{create_small_thunderstorm(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt+alt_offset, alpha);}
	}

# next the dense cloud layer underneath the thunderstorms

x = 0.0;
y = 5000.0;

var strength = 0.3;
var n = int(4000 * strength) * 0.2;
local_weather.cumulus_exclusion_layer(blat+get_lat(x,y,phi), blon+ get_lon(x,y,phi), alt+alt_offset, n, 20000.0, 10000.0, alpha, 1.5,2.5 , size(elat), elat, elon, erad);

# then leading and traling Cumulus

x = 0.0;
y = 15500.0;

strength = 1.0;
n = int(4000 * strength) * 0.15;
local_weather.cumulus_exclusion_layer(blat+get_lat(x,y,phi), blon+ get_lon(x,y,phi), alt+alt_offset, n, 20000.0, 2000.0, alpha, 0.5,1.8 , size(elat), elat, elon, erad);

x = 0.0;
y = -5500.0;

strength = 1.0;
n = int(4000 * strength) * 0.15;
local_weather.cumulus_exclusion_layer(blat+get_lat(x,y,phi), blon+ get_lon(x,y,phi), alt+alt_offset, n, 20000.0, 2000.0, alpha, 0.5,1.8 , size(elat), elat, elon, erad);

# finally some thin stratus underneath the Cumulus

x = 0.0;
y = 13000.0;
local_weather.create_streak("Stratus (thin)",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset,0.0,20,2000.0,0.2,1200.0,3,1500.0,0.2,1200.0,alpha,1.0);


x = 0.0;
y = -3000.0;
local_weather.create_streak("Stratus (thin)",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset,0.0,20,2000.0,0.2,1200.0,3,1500.0,0.2,1200.0,alpha,1.0);


# some turbulence in the convection layer

x=0.0; y = 5000.0;
local_weather.create_effect_volume(3, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 20000.0, 11000.0, alpha, 0.0, alt+3000.0+alt_offset, -1, -1, -1, 0.4, -1,0 ,-1);

# some rain and reduced visibility in its core 

x=0.0; y = 5000.0;
local_weather.create_effect_volume(3, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 20000.0, 8000.0, alpha, 0.0, alt+alt_offset, 10000.0, 0.1, -1, -1, -1,0,-1 );

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}


####################################
# Warmfront 1
####################################


var set_warmfront1_tile = func {

setprop(lw~"tiles/code","warmfront1");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;



var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;

if (getprop(lw~"tmp/presampling-flag") == 0)
	{var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");}
else
	{var alt_offset = getprop(lw~"tmp/tile-alt-layered-ft");}

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 20000.0 + rand() * 5000.0;
var T = 10.0 + rand() * 8.0;
var spread = 3.0 + 3.0 * rand();
var D = T - spread;
var p = 1005 + rand() * 10.0; p = adjust_p(p);

# first weather info for tile  (lat, lon, visibility, temperature, dew point, pressure)

# after the front

x = 15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T+2.0, D+1.0, p * hp_to_inhg);

x = -15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T+2.0, D+1.0, p * hp_to_inhg);

# before the front

x = 15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T, D, p * hp_to_inhg);

x = -15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0;

# some weak Cumulus development

var strength = 0.1 + rand() * 0.1;
local_weather.create_cumosys(blat,blon, alt + alt_offset, get_n(strength), 20000.0);


# high Cirrus leading

x = 2.0 * (rand()-0.5) * 1000;
y = 2.0 * (rand()-0.5) * 1000 - 9000.0; 
	

local_weather.create_streak("Cirrus",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 25000.0+alt+alt_offset,1500.0,3,11000.0,0.0, 3000.0, 2,11000.0,0.0,3000.0,alpha ,1.0);


# followed by random patches of Cirrostratus

for (var i=0; i<6; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 15000;
	var y = 2.0 * (rand()-0.5) * 10000 + 10000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Cirrostratus",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 18000 + alt + alt_offset,300.0,4,2300.0,0.2,600.0,4,2300.0,0.2,600.0,alpha+beta,1.0);

	}

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}


####################################
# Warmfront 2
####################################


var set_warmfront2_tile = func {

setprop(lw~"tiles/code","warmfront2");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;



var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;

if (getprop(lw~"tmp/presampling-flag") == 0)
	{var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");}
else
	{var alt_offset = getprop(lw~"tmp/tile-alt-layered-ft");}

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 15000.0 + rand() * 5000.0;
var T = 13.0 + rand() * 8.0;
var spread = 2.5 + 2.5 * rand();
var D = T - spread;
var p = 1005 + rand() * 10.0; p = adjust_p(p);

# first weather info for tile  (lat, lon, visibility, temperature, dew point, pressure)

# after the front

x = 15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T+2.0, D+1.0, p * hp_to_inhg);

x = -15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T+2.0, D+1.0, p * hp_to_inhg);

# before the front

x = 15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T, D, p * hp_to_inhg);

x = -15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0;
var strength = 0.0;

# followed by random patches of Cirrostratus

for (var i=0; i<3; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 5000 - 15000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Cirrostratus",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 15000 + alt + alt_offset,300.0,4,2300.0,0.2,600.0,4,2300.0,0.2,600.0,alpha+beta,1.0);

	}

# patches of thin Altostratus

for (var i=0; i<14; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 9000 - 10000.0;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Stratus (thin)",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset +12000.0,300.0,4,950.0,0.2,500.0,6,950.0,0.2,500.0,alpha+beta,1.0);

	}

# patches of structured Stratus

for (var i=0; i<10; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 9000;
	var y = 2.0 * (rand()-0.5) * 9000 + 2000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Stratus (structured)",blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset+9000.0,300.0,5,900.0,0.2,500.0,7,900.0,0.2,500.0,alpha+beta,1.0);

	}


# merging with a broken Stratus layer

var x = 0.0;
var y = 8000.0;

local_weather.create_streak("Stratus",blat +get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset +5000.0,1000.0,30,0.0,0.2,20000.0,10,0.0,0.2,12000.0,alpha,1.0);

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}


####################################
# Warmfront 3
####################################


var set_warmfront3_tile = func {

setprop(lw~"tiles/code","warmfront3");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;



var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;

if (getprop(lw~"tmp/presampling-flag") == 0)
	{var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");}
else
	{var alt_offset = getprop(lw~"tmp/tile-alt-layered-ft");}

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 12000.0 + rand() * 3000.0;
var T = 15.0 + rand() * 7.0;
var spread = 2.5 + 1.5 * rand();
var D = T - spread;
var p = 1005 + rand() * 10.0; p = adjust_p(p);

# first weather info for tile  (lat, lon, visibility, temperature, dew point, pressure)

# after the front

x = 15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T+2.0, D+1.0, p * hp_to_inhg);

x = -15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T+2.0, D+1.0, p * hp_to_inhg);

# before the front

x = 15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T, D, p * hp_to_inhg);

x = -15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0 + local_weather.cloud_vertical_size_map["Nimbus"] * 0.5 * m_to_ft;
var strength = 0.0;

# closed Stratus layer

var x = 0.0;
var y = -8000.0;

local_weather.create_streak("Stratus",blat +get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset +1000.0,500.0,32,1250.0,0.2,400.0,20,1250.0,0.2,400.0,alpha,1.0);





# merging with a Nimbostratus layer

var x = 0.0;
var y = 8000.0;

local_weather.create_streak("Nimbus",blat +get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset,500.0,32,1250.0,0.0,200.0,20,1250.0,0.0,200.0,alpha,1.0);



# some rain beneath the stratus

x=0.0; y = -10000.0;
local_weather.create_effect_volume(3, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 20000.0, 10000.0, alpha, 0.0, alt+alt_offset+1000, vis * 0.7, 0.1, -1, -1, -1,0 ,-1);

# heavier rain beneath the Nimbostratus

x=0.0; y = 10000.0;
local_weather.create_effect_volume(3, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 20000.0, 10000.0, alpha, 0.0, alt+alt_offset, vis * 0.5, 0.3, -1, -1, -1,0,-1 );


# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}


####################################
# Warmfront 4
####################################


var set_warmfront4_tile = func {

setprop(lw~"tiles/code","warmfront4");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;



var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;

if (getprop(lw~"tmp/presampling-flag") == 0)
	{var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");}
else
	{var alt_offset = getprop(lw~"tmp/tile-alt-layered-ft");}

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# get probabilistic values for the weather parameters

var vis = 12000.0 + rand() * 3000.0;
var T = 17.0 + rand() * 6.0;
var spread = 2.0 + 1.0 * rand();
var D = T - spread;
var p = 1005 + rand() * 10.0; p = adjust_p(p);

# first weather info for tile  (lat, lon, visibility, temperature, dew point, pressure)

# after the front

x = 15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T+2.0, D+1.0, p * hp_to_inhg);

x = -15000.0; y = 15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T+2.0, D+1.0, p * hp_to_inhg);

# before the front

x = 15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T, D, p * hp_to_inhg);

x = -15000.0; y = -15000.0;
local_weather.set_weather_station(blat +get_lat(x,y,phi), blon + get_lon(x,y,phi), alt_offset, vis, T, D, p * hp_to_inhg);

# altitude for the lowest layer
var alt = spread * 1000.0 + local_weather.cloud_vertical_size_map["Nimbus"] * 0.5 * m_to_ft;
var strength = 0.0;

# low Nimbostratus layer

var x = 0.0;
var y = -5000.0;

local_weather.create_streak("Nimbus",blat +get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset,500.0,32,1250.0,0.0,200.0,24,1250.0,0.0,200.0,alpha,1.0);


# a little patchy structured Stratus above for effect

create_2_8_sstratus(blat, blon, alt+alt_offset+3000.0, alpha); 

# eventually breaking up

var x = 0.0;
var y = 14000.0;

local_weather.create_streak("Nimbus",blat +get_lat(x,y,phi), blon+get_lon(x,y,phi), alt+alt_offset,500.0,25,1600.0,0.2,200.0,9,1400.0,0.3,200.0,alpha,1.0);



# rain beneath the Nimbostratus

x=0.0; y = -5000.0;
local_weather.create_effect_volume(3, blat+get_lat(x,y,phi), blon+get_lon(x,y,phi), 20000.0, 15000.0, alpha, 0.0, alt+alt_offset, vis * 0.5, 0.3, -1, -1, -1,0 ,-1);


# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();

}









####################################
# Glider's sky
####################################

var set_gliders_sky_tile = func {

setprop(lw~"tiles/code","gliders_sky");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# first weather info for tile center (lat, lon, visibility, temperature, dew point, pressure)
local_weather.set_weather_station(blat, blon, alt_offset, 35000.0, 20.0, 16.0, 1018 * hp_to_inhg);



var alt = 3000.0;

# add convective clouds

var strength = 0.5;
var n = int(4000 * strength); # calculate the number of placement tries from tile size 20x20km and strength
local_weather.create_cumosys(blat,blon, alt+alt_offset,n, 20000.0);

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();


}

####################################
# Blue thermals
####################################

var set_blue_thermals_tile = func {

setprop(lw~"tiles/code","blue_thermals");

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;

var alpha = getprop(lw~"tmp/tile-orientation-deg");
var phi = alpha * math.pi/180.0;
var alt_offset = getprop(lw~"tmp/tile-alt-offset-ft");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

# first weather info for tile center (lat, lon, visibility, temperature, dew point, pressure)
local_weather.set_weather_station(blat, blon, alt_offset, 45000.0, 20.0, 15.0, 1018 * hp_to_inhg);

local_weather.generate_thermal_lift_flag = 3;

var alt = 5000.0;

# add convective clouds

# set flag to blue thermal generation
if (local_weather.generate_thermal_lift_flag !=0)
	{local_weather.generate_thermal_lift_flag = 3;}

var strength = 0.9;
var n = int(4000 * strength); # calculate the number of placement tries from tile size 20x20km and strength
local_weather.create_cumosys(blat,blon, 5000.0+alt_offset,n, 20000.0);

# set flag back to normal thermal generation
if (local_weather.generate_thermal_lift_flag !=0)
	{local_weather.generate_thermal_lift_flag = 0;}

# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();


}





####################################
# METAR
####################################

var set_METAR_tile = func {


setprop(lw~"tiles/code","METAR"); 

tile_start();

var x = 0.0;
var y = 0.0;
var lat = 0.0;
var lon = 0.0;



var alpha = getprop("/environment/metar/base-wind-dir-deg");
var phi = alpha * math.pi/180.0;
var metar_alt_offset = 700.0 + getprop("/environment/metar/station-elevation-ft");

# print("metar_alt_offset", metar_alt_offset);

# get the local time of the day in seconds

var t = getprop("sim/time/utc/day-seconds");
t = t + getprop("sim/time/local-offset");

# get tile center coordinates

var blat = getprop(lw~"tiles/tmp/latitude-deg");
var blon = getprop(lw~"tiles/tmp/longitude-deg");
calc_geo(blat);

var rain_norm = getprop("/environment/metar/rain-norm");
var snow_norm = getprop("/environment/metar/snow-norm");
var p = inhg_to_hp * getprop("/environment/metar/pressure-sea-level-inhg");

# now get the cloud layer info

var layers = props.globals.getNode("/environment/metar/clouds", 1).getChildren("layer");
var n_layers = size(layers); # the system initializes with  4 layers, but who knows...
var n = 0; # start with lowest layer

# now determine the nature of the lowest layer

var cumulus_flag = 1; # default assumption - the lowest layer is cumulus 
var thunderstorm_flag = 0;
var cover_low = 8 - 2 * layers[0].getNode("coverage-type").getValue(); # conversion to oktas
var alt_low = layers[0].getNode("elevation-ft").getValue();

# print("alt_low: ", alt_low);

if ((alt_low < 0.0) or (cover_low ==0)) # we have to guess a value for the convective altitude for the visibility model
	{alt_low = 8000.0;}

# first check a few obvious criteria

if (cover_low == 8) {cumulus_flag = 0;} # overcast sky is unlikely to be Cumulus, and we can't render it anyway
if ((rain_norm > 0.0) or (snow_norm > 0.0)) {cumulus_flag = 0;} # Cumulus usually doesn't rain
if (alt_low > 7000.0) {cumulus_flag = 0;} # Cumulus are low altitude clouds

# now try matching time evolution of cumuli

if ((cover_low == 5) or (cover_low == 6) or (cover_low == 7)) # broken
	{
	if ((t < 39600) or (t > 68400)) {cumulus_flag = 0;} # not before 11:00 and not after 19:00
	}

if ((cover_low == 3) or (cover_low == 4)) # scattered
	{
	if ((t < 32400) or (t > 75600)) {cumulus_flag = 0;} # not before 9:00 and not after 21:00
	}

# now see if there is a layer shading convective development

var coverage_above = 8 - 2 * layers[1].getNode("coverage-type").getValue(); 
var coverage_above2 = 8 - 2 * layers[2].getNode("coverage-type").getValue(); 

if (coverage_above2 > coverage_above)
	{coverage_above = coverage_above2;}

if (coverage_above > 6) {cumulus_flag = 0;} # no Cumulus with strong layer above

# never do Cumulus when there's a thunderstorm
if (getprop(lw~"METAR/thunderstorm-flag") ==1) {cumulus_flag = 0; thunderstorm_flag = 1;} 

# if cumulus_flag is still 1 at this point, the lowest layer is Cumulus
# see if we need to adjust its strength 

if ((cumulus_flag == 1) and (cover_low > 0))
	{
	if ((cover_low < 4) and (t > 39600) and (t < 68400)) {var strength = 0.4;}
	if ((cover_low < 2) and (t > 39600) and (t < 68400)) {var strength = 0.2;}
	else {var strength = 1.0;}
	local_weather.create_cumosys(blat,blon, alt_low+metar_alt_offset,get_n(strength), 20000.0);
	n = n + 1; # do not start parsing with lowest layer
	}	
else 	
	{var strength = 0.0;}


# if thunderstorm_flag is 1, we do the lowest layer as thunderstorm scenario, somewhat ignoring the coverage info

if (thunderstorm_flag == 1)
	{
	create_thunderstorm_scenario(blat, blon, alt_low+metar_alt_offset, alpha);
	n = n + 1; # do not start parsing with lowest layer
	}


for (var i = n; i <n_layers; i=i+1)
	{
	var altitude = layers[i].getNode("elevation-ft").getValue();
	# print("altitude: ",altitude);
	var cover = 8 - 2 * layers[i].getNode("coverage-type").getValue();

	if (cover == -2) {break;} # a clear cover layer indicates we are done

	if (n > 0) { rain_norm = 0.0; snow_norm = 0.0;} # rain and snow fall only from the lowest layer

	if (altitude < 9000.0) # draw Nimbostratus or Stratus models
		{	
		if (cover == 8) 
			{
			if ((altitude < 2000) or (rain_norm > 0.3))
				{create_8_8_nimbus_rain(blat, blon, altitude+metar_alt_offset, alpha, rain_norm);}
			else 
				{create_8_8_stratus_rain(blat, blon, altitude+metar_alt_offset, alpha, rain_norm);}
			}
		else if ((cover < 8) and (cover > 4))
			{
			if (cumulus_flag == 1)
				{
				create_4_8_sstratus_patches(blat, blon, altitude+metar_alt_offset, alpha);
				}
			else
				{
				if ((rain_norm > 0.1) and (altitude < 5000.0))
					{	
					create_6_8_nimbus_rain(blat, blon, altitude+metar_alt_offset, alpha, rain_norm);
					}
				else if (rain_norm > 0.0)
					{
					create_6_8_stratus_rain(blat, blon, altitude+metar_alt_offset, alpha, rain_norm);
					}
				else
					{
					if ((p > 1010.0) and (i == 0)) # the lowest layer may be Stratocumulus
						{
						create_6_8_stratocumulus(blat, blon, altitude+metar_alt_offset, alpha);
						}
					else
						{
						if (rand() > 0.5)					
							{create_6_8_stratus(blat, blon, altitude+metar_alt_offset, alpha);}
						else
							{create_6_8_stratus_undulatus(blat, blon, altitude+metar_alt_offset, alpha);}
						}
					}
				}
			}
		else if ((cover == 3) or (cover == 4))
			{
			if ((p > 1010.0) and (i == 0)) # the lowest layer may be Stratocumulus		
				{
				create_4_8_stratocumulus(blat, blon, altitude+metar_alt_offset, alpha);
				}
			else
				{
				var rn = rand();
				if (rn > 0.75)
					{create_4_8_stratus(blat, blon, altitude+metar_alt_offset, alpha);}
				else if (rn > 0.5)
					{create_4_8_stratus_patches(blat, blon, altitude+metar_alt_offset, alpha);}
				else if (rn > 0.25)
					{create_4_8_sstratus_patches(blat, blon, altitude+metar_alt_offset, alpha);}
				else if (rn > 0.0)
					{create_4_8_sstratus_undulatus(blat, blon, altitude+metar_alt_offset, alpha);}
				}
			}
		else 
			{
			if (cumulus_flag == 0)
				{
				var rn = rand();
				if (rn > 0.5)
					{create_2_8_stratus(blat, blon, altitude+metar_alt_offset, alpha);}
				else if (rn > 0.0)
					{create_2_8_sstratus(blat, blon, altitude+metar_alt_offset, alpha);}
				}
			else 
				{
				create_2_8_altocumulus_streaks(blat, blon, altitude+metar_alt_offset, alpha);
				}
			}
		} # end if altitude
	else if ((altitude > 9000.0) and (altitude < 20000.0)) # select thin cloud layers
		{
		if (cover == 8) 
			{
			if (altitude < 14000.0)
				{create_8_8_tstratus(blat, blon, altitude+metar_alt_offset, alpha);}
			else
				{create_8_8_cirrostratus(blat, blon, altitude+metar_alt_offset, alpha);}
			}
		else if (cover > 4)
			{
			if (altitude < 14000.0)
				{create_6_8_tstratus_undulatus(blat, blon, altitude+metar_alt_offset, alpha);}
			else
				{create_6_8_cirrostratus(blat, blon, altitude+metar_alt_offset, alpha);}
			}
		else if (cover > 2)
			{
			var rn = rand();
			if (rn > 0.75)
				{create_4_8_tstratus_patches(blat, blon, altitude+metar_alt_offset, alpha);}
			else if (rn > 0.5)
				{create_4_8_alttstratus_streaks(blat, blon, altitude+metar_alt_offset, alpha);}
			else if (rn > 0.25)
				{create_4_8_alttstratus_patches(blat, blon, altitude+metar_alt_offset, alpha);}
			else if (rn > 0.0)
				{create_4_8_tstratus_undulatus(blat, blon, altitude+metar_alt_offset, alpha);}
			}
		else
			{
			if (altitude < 14000.0)
				{	
				var rn = rand();
				if (rn > 0.66)			
					{create_2_8_tstratus(blat, blon, altitude+metar_alt_offset, alpha);}
				else if (rn > 0.33)
					{create_2_8_sstratus(blat, blon, altitude+metar_alt_offset, alpha);}
				else 
					{create_2_8_alttstratus(blat, blon, altitude+metar_alt_offset, alpha);}	
				}
			else 
				{
				var rn = rand();
				if (rn > 0.5)
					{create_2_8_cirrocumulus(blat, blon, altitude+metar_alt_offset, alpha);}
				else
					{create_2_8_alttstratus(blat, blon, altitude+metar_alt_offset, alpha);}	

				}
			}
		} # end if altitude
	else
		{
		if (cover == 8) 
			{create_8_8_cirrostratus(blat, blon, altitude+metar_alt_offset, alpha);}
		else if (cover > 4)
			{create_6_8_cirrostratus(blat, blon, altitude+metar_alt_offset, alpha);}
		else if (cover > 2)
			{
			var rn = rand();
			if (rn > 0.5)
				{create_4_8_cirrostratus_patches(blat, blon, altitude+metar_alt_offset, alpha);}
			else
				{create_4_8_cirrostratus_undulatus(blat, blon, altitude+metar_alt_offset, alpha);}
			}
		else
			{
			var rn = rand();
			if (rn > 0.5)
				{create_2_8_cirrostratus(blat, blon, altitude+metar_alt_offset, alpha);}
			else
				{create_1_8_cirrocumulus(blat, blon, altitude+metar_alt_offset, alpha);}

			}

			
		}
	} # end for
	


# store convective altitude and strength

append(weather_dynamics.tile_convective_altitude,alt_low);
append(weather_dynamics.tile_convective_strength,strength);

tile_finished();
}



####################################
# METAR station setup
####################################

var set_METAR_weather_station = func {


# get the METAR position info

	var station_lat = getprop("/environment/metar/station-latitude-deg");
	var station_lon = getprop("/environment/metar/station-longitude-deg");
	var metar_alt_offset = 700.0 + getprop("/environment/metar/station-elevation-ft");


	
	# get the weather parameters

	var vis = getprop("/environment/metar/max-visibility-m");
	var T = getprop("/environment/metar/temperature-sea-level-degc");
	var D = getprop("/environment/metar/dewpoint-sea-level-degc");
	var p = getprop("/environment/metar/pressure-sea-level-inhg");
	var rain_norm = getprop("/environment/metar/rain-norm");
	var snow_norm = getprop("/environment/metar/snow-norm");

	var windspeed = getprop("/environment/metar/base-wind-speed-kt");
	var wind_range_from = getprop("/environment/metar/base-wind-range-from");
	var wind_range_to = getprop("/environment/metar/base-wind-range-to");

	var gust_strength = getprop("/environment/metar/gust-wind-speed-kt");
	var alpha = getprop("/environment/metar/base-wind-dir-deg");


	# some METAR report just above max. visibility, if so we guess visibility based on pressure

	var is_visibility_max = 0;

	if (vis == 9999) {is_visibility_max = 1;}

	if ((vis > 16093) and (vis < 16094)) # that's 10 nm
		{is_visibility_max = 1;}

	if (is_visibility_max == 1) 
			{
		if (p * inhg_to_hp < 1000.0) {vis = 10000.0 + 5000 * rand();}	
		else if (p * inhg_to_hp < 1010.0) {vis = 15000.0 + 7000 * rand();}
		else if (p * inhg_to_hp < 1020.0) {vis = 22000.0 + 14000.0 * rand();}
		else {vis = 30000.0 + 15000.0 * rand();}
		}



	# set the station
	local_weather.set_weather_station(station_lat, station_lon, metar_alt_offset, vis, T, D, p);


	# if we use aloft interpolated winds with METAR, also set a new wind interpolation point
	
	if ((local_weather.wind_model_flag == 5) and (getprop(lw~"tiles/tile-counter") !=1))
		{
		# if zero winds are reported, we do not rotate the tile to face north but use the last value
	
		if ((alpha == 0.0) and (windspeed == 0.0))
			{
			alpha = getprop(lw~"tmp/tile-orientation-deg");	
			var phi = alpha * math.pi/180.0;
			}


		var boundary_correction = 1.0/local_weather.get_slowdown_fraction();
		local_weather.set_wind_ipoint_metar(station_lat, station_lon, alpha, boundary_correction * windspeed);
		}

	# also compute and set gust wind info

	var gust_angvar = 0.5 * weather_tile_management.relangle(wind_range_from, wind_range_to);
	
	if ((gust_strength > 0.0) or (gust_angvar > 0.0))
		{
		var gust_relative_strength = (gust_strength - windspeed)/windspeed;
		setprop(lw~"tmp/gust-frequency-hz", 0.2 + rand()*0.8);
		}
	else
		{
		var gust_relative_strength = 0.0;
		setprop(lw~"tmp/gust-frequency-hz", 0.0);
		}


	setprop(lw~"tmp/gust-relative-strength", gust_relative_strength);
	setprop(lw~"tmp/gust-angular-variation-deg", gust_angvar);
	

	# and mark that we have used this station
	setprop(lw~"METAR/station-id",getprop("/environment/metar/station-id"));


}


####################################
# mid-level cloud setup calls
####################################

var create_8_8_stratus = func (lat, lon, alt, alpha) {

local_weather.create_streak("Stratus",lat, lon, alt,500.0,32,1250.0,0.0,400.0,32,1250.0,0.0,400.0,alpha,1.0);

}

var create_8_8_tstratus = func (lat, lon, alt, alpha) {

local_weather.create_streak("Stratus (thin)",lat, lon, alt,500.0,32,1250.0,0.0,400.0,32,1250.0,0.0,400.0,alpha,1.0);

}

var create_8_8_cirrostratus = func (lat, lon, alt, alpha) {

local_weather.create_streak("Cirrostratus",lat,lon,alt,500.0,30,1250.0,0.0,400.0,30,1250.0,0.0,400.0,alpha,1.0);
}

var create_8_8_nimbus = func (lat, lon, alt, alpha) {

local_weather.create_streak("Nimbus",lat, lon, alt,500.0,32,1250.0,0.0,200.0,32,1250.0,0.0,200.0,alpha,1.0);


}

var create_8_8_nimbus_var1 = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

local_weather.create_streak("Nimbus",lat, lon, alt,500.0,35,1111.0,0.0,200.0,35,1111.0,0.0,200.0,alpha,1.0);

for (var i = 0; i < 3; i=i+1)
	{
	var x = -15000.0 + 30000.0 * rand();
	var y = -15000.0 + 30000.0 * rand();
	local_weather.create_streak("Stratocumulus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt+600.0,200.0,11,1100.0,0.1,800.0,8,1100.0,0.1,800.0,alpha,1.4);

	}
}

var create_8_8_nimbus_var2 = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

local_weather.create_streak("Nimbus",lat, lon, alt,500.0,35,1111.0,0.0,200.0,35,1111.0,0.0,200.0,alpha,1.0);

for (var i=0; i<8; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Stratus (structured)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt+1200.0,300.0,5,900.0,0.2,500.0,7,900.0,0.2,500.0,alpha+beta,1.0);

	}

}


var create_8_8_nimbus_var3 = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

local_weather.create_streak("Nimbus",lat, lon, alt,500.0,35,1111.0,0.0,200.0,35,1111.0,0.0,200.0,alpha,1.0);

for (var i=0; i<6; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Stratus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt+1600.0,300.0,6,1200.0,0.2,700.0,6,1200.0,0.2,700.0,alpha+beta,1.0);
	}

# reduced visibility in layer
#local_weather.create_effect_volume(3, lat, lon, 20000.0, 20000.0, alpha, alt-1500.0, alt+900.0, 2000.0, -1 , -1, -1, -1,0 ,-1);
# cloud shade
#local_weather.create_effect_volume(3, lat, lon, 20000.0, 20000.0, alpha, 0.0, alt, -1, -1 , -1, -1, -1,0 ,0.8);

}

var create_8_8_nimbus_rain = func (lat, lon, alt, alpha, rain) {

if (local_weather.detailed_clouds_flag == 0)
	{local_weather.create_streak("Nimbus",lat, lon, alt,500.0,32,1250.0,0.0,200.0,32,1250.0,0.0,200.0,alpha,1.0);}
else
	{
	var rn = rand();
	if (rn > 0.66) {create_8_8_nimbus_var1(lat, lon, alt, alpha);}
	else if (rn > 0.33) {create_8_8_nimbus_var2(lat, lon, alt, alpha);}
	else {create_8_8_nimbus_var3(lat, lon, alt, alpha);}
	}

if (rain > 0.1)
	{
	local_weather.create_effect_volume(3, lat, lon, 20000.0, 20000.0, alpha, 0.0, alt+900.0, 500.0 + (1.0 - 0.5 * rain) * 5500.0, 0.5 * rain , -1, -1, -1,0 ,0.95);
	local_weather.create_effect_volume(3, lat , lon, 16000.0, 16000.0, alpha, 0.0, alt - 300.0, 500.0 + (1.0-rain) * 5500.0, rain, -1, -1, -1,0 ,0.8);
	}
else
	{
	local_weather.create_effect_volume(3, lat, lon, 20000.0, 20000.0, alpha, alt-1500.0, alt+900.0, 2000.0, -1 , -1, -1, -1,0 ,-1);
	local_weather.create_effect_volume(3, lat, lon, 20000.0, 20000.0, alpha, 0.0, alt, -1, rain , -1, -1, -1,0 ,0.8);
	}

}


var create_8_8_stratus_rain = func (lat, lon, alt, alpha, rain) {

local_weather.create_streak("Stratus",lat, lon, alt,500.0,32,1250.0,0.0,400.0,32,1250.0,0.0,400.0,alpha,1.0);

if (rain > 0.1)	
	{
	local_weather.create_effect_volume(3, lat, lon, 20000.0, 20000.0, alpha, 0.0, alt, 500.0 + (1.0 - 0.5 * rain) * 5500.0, 0.5 * rain , -1, -1, -1,0 ,-1);
	local_weather.create_effect_volume(3, lat , lon, 16000.0, 16000.0, alpha, 0.0, alt - 300.0, 500.0 + (1.0-rain) * 5500.0, rain, -1, -1, -1,0 ,0.9);
	}
else
	{
	local_weather.create_effect_volume(3, lat, lon, 20000.0, 20000.0, alpha, 0.0, alt, -1, rain , -1, -1, -1,0 ,0.9);
	}
}


var create_6_8_stratus = func (lat, lon, alt, alpha) {

local_weather.create_streak("Stratus",lat, lon, alt,500.0,20,0.0,0.2,20000.0,20,0.0,0.2,20000.0,alpha,1.0);
}




var create_6_8_nimbus_rain = func (lat, lon, alt, alpha, rain) {

var phi = alpha * math.pi/180.0;


for (var i = 0; i < 3; i = i + 1)
	{
	var x = 2.0 * (rand()-0.5) * 2000.0 + i * 12000.0 - 12000.0;
	var y = 2.0 * (rand()-0.5) * 12000.0;
	var beta = rand() * 360.0;

	local_weather.create_layer("Nimbus", lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt, 500.0, 12000.0, 7000.0, beta, 1.0, 0.2, 1, 1.0);

	if (rain > 0.1)
		{
		local_weather.create_effect_volume(2, lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), 10000.0, 6000.0, beta, 0.0, alt+900, 500.0 + (1.0-0.5*rain) * 5500.0, 0.5 * rain, -1, -1, -1,0,0.95 );
		local_weather.create_effect_volume(2, lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), 9000.0, 5000.0, beta, 0.0, alt-300.0, 500.0 + (1.0-rain) * 5500.0, rain, -1, -1, -1,0,0.8);
		}
	else
		{
		local_weather.create_effect_volume(2, lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), 10000.0, 6000.0, beta, 0.0, alt, -1, rain, -1, -1, -1,0, 0.8 );
		local_weather.create_effect_volume(2, lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), 10000.0, 6000.0, beta, alt-1500.0, alt+900.0, 2000.0, -1, -1, -1, -1,0, 0.8 );
		}
	}


}


var create_6_8_stratus_rain = func (lat, lon, alt, alpha, rain) {

var phi = alpha * math.pi/180.0;


for (var i = 0; i < 3; i = i + 1)
	{
	var x = 2.0 * (rand()-0.5) * 2000.0 + i * 12000.0 - 12000.0;
	var y = 2.0 * (rand()-0.5) * 12000.0;
	var beta = rand() * 360.0;

	local_weather.create_layer("Stratus", lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt, 500.0, 12000.0, 7000.0, beta, 1.0, 0.2, 0, 0.0);

	if (rain > 0.1)
		{
		local_weather.create_effect_volume(2, lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), 10000.0, 6000.0, beta, 0.0, alt, 500.0 + (1.0-0.5*rain) * 5500.0, 0.5 * rain, -1, -1, -1,0,0.95 );
		local_weather.create_effect_volume(2, lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), 9000.0, 5000.0, beta, 0.0, alt-300.0, 500.0 + (1.0-rain) * 5500.0, rain, -1, -1, -1,0,0.8);
		}
	else
		{
		local_weather.create_effect_volume(2, lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), 10000.0, 6000.0, beta, 0.0, alt, -1, rain, -1, -1, -1,0, 0.8 );
		}
	}


}


var create_6_8_stratus_undulatus = func (lat, lon, alt, alpha) {

local_weather.create_undulatus("Stratus",lat, lon, alt,300.0,10,4000.0,0.1,400.0,50,800.0,0.1,100.0, 1000.0, alpha,1.0);
}

var create_6_8_tstratus_undulatus = func (lat, lon, alt, alpha) {

local_weather.create_undulatus("Stratus (thin)",lat, lon, alt,300.0,10,4000.0,0.1,400.0,50,800.0,0.1,100.0, 1000.0, alpha,1.0);
}

var create_6_8_cirrostratus = func (lat, lon, alt, alpha) {

local_weather.create_streak("Cirrostratus",lat,lon,alt,500.0,24,1500.0,0.0,900.0,24,1500.0,0.0,900.0,alpha,1.0);
}


var create_6_8_stratocumulus = func (lat, lon, alt, alpha) {

if (local_weather.detailed_clouds_flag == 1)
	{
	for (i=0; i< 2; i=i+1)
		{
		var phi = alpha * math.pi/180.0;
		var x = 2.0 * (rand()-0.5) * 4000;
		var y = 2.0 * (rand()-0.5) * 4000;
		var beta = rand() * 360.0;
		create_detailed_stratocumulus_bank(lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt, alpha+beta);
		}
	}
else
	{
	create_stratocumulus_bank(lat, lon, alt, alpha);
	create_stratocumulus_bank(lat, lon, alt, alpha);
	}

}


var create_4_8_stratus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 15000;
var y = 2.0 * (rand()-0.5) * 15000;
var beta = rand() * 360.0;

local_weather.create_streak("Stratus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,500.0,20,1200.0,0.3,400.0,12,1200.0,0.3,400.0,beta,1.2);


var x = 2.0 * (rand()-0.5) * 15000;
var y = 2.0 * (rand()-0.5) * 15000;
var beta = rand() * 360.0;

local_weather.create_streak("Stratus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,500.0,18,1000.0,0.3,400.0,10,1000.0,0.3,400.0,beta,1.5);


var x = 2.0 * (rand()-0.5) * 15000;
var y = 2.0 * (rand()-0.5) * 15000;
var beta = rand() * 360.0;

local_weather.create_streak("Stratus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,500.0,15,1000.0,0.3,400.0,18,1000.0,0.3,400.0,beta,2.0);

}

var create_4_8_stratus_patches = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<16; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Stratus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,4,950.0,0.2,500.0,6,950.0,0.2,500.0,alpha+beta,1.0);

	}

}

var create_4_8_tstratus_patches = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<22; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;

	var m = int(3 + rand() * 3);
	var n =	int(3 + rand() * 5);

	local_weather.create_streak("Stratus (thin)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,m,1000.0,0.2,500.0,n,1000.0,0.2,500.0,alpha+beta,1.0);

	}

}


var create_4_8_sstratus_patches = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<22; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	var m = int(3 + rand() * 5);
	var n = int(3 + rand() * 5);
	local_weather.create_streak("Stratus (structured)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,m,1000.0,0.2,500.0,n,1000.0,0.2,500.0,alpha+beta,1.0);

	}

}


var create_4_8_cirrostratus_patches = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<6; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 12000;
	var y = 2.0 * (rand()-0.5) * 12000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Cirrostratus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,4,2500.0,0.2,600.0,4,2500.0,0.2,600.0,alpha+beta,1.0);

	}

}

var create_4_8_cirrostratus_undulatus = func (lat, lon, alt, alpha) {

local_weather.create_undulatus("Cirrostratus",lat, lon, alt,300.0,5,8000.0,0.1,400.0,40,1000.0,0.1,100.0, 1500.0, alpha,1.0);
}


var create_4_8_stratus_undulatus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 5000;
var y = 2.0 * (rand()-0.5) * 5000;
var tri = 1.5 + 1.5*rand();
var beta = (rand() -0.5) * 60.0;

local_weather.create_streak("Stratus",lat+get_lat(x,y+4000,phi), lon+get_lon(x,y+4000,phi), alt,500.0,10,800.0,0.25,400.0,12,2800.0,0.15,600.0,alpha+90.0+beta,tri);

local_weather.create_streak("Stratus",lat+get_lat(x,y-4000,phi), lon+get_lon(x,y-4000,phi), alt,500.0,10,800.0,0.25,400.0,12,2800.0,0.15,600.0,alpha+270.0+beta,tri);

}

var create_4_8_tstratus_undulatus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 5000;
var y = 2.0 * (rand()-0.5) * 5000;
var tri = 1.5 + 1.5*rand();
var beta = (rand() -0.5) * 60.0;

local_weather.create_streak("Stratus (thin)",lat+get_lat(x,y+4000,phi), lon+get_lon(x,y+4000,phi), alt,500.0,10,800.0,0.25,400.0,12,2800.0,0.15,600.0,alpha+90.0+beta,tri);

local_weather.create_streak("Stratus (thin)",lat+get_lat(x,y-4000,phi), lon+get_lon(x,y-4000,phi), alt,500.0,10,800.0,0.25,400.0,12,2800.0,0.15,600.0,alpha+270.0+beta,tri);

}

var create_4_8_sstratus_undulatus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 5000;
var y = 2.0 * (rand()-0.5) * 5000;
var tri = 1 + 1.5*rand();
var beta = (rand() -0.5) * 60.0;

local_weather.create_streak("Stratus (structured)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,500.0,20,900.0,0.25,400.0,12,2800.0,0.15,600.0,alpha+90.0+beta,tri);

}


var create_4_8_cirrocumulus_bank = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 5000;
var y = 2.0 * (rand()-0.5) * 5000;
var tri = 1.5 + 1.5 *rand();
var beta = (rand() -0.5) * 60.0;

local_weather.create_streak("Cirrocumulus (cloudlet)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,400.0,12,750.0,0.25,400.0,24,750.0,0.2,400.0,alpha+90.0+beta,tri);

}


var create_4_8_cirrocumulus_undulatus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 5000;
var y = 2.0 * (rand()-0.5) * 5000;
var tri = 1.4 + 0.6 *rand();
var beta = (rand() -0.5) * 60.0;

local_weather.create_streak("Cirrocumulus (cloudlet)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,400.0,25,300.0,0.0,900.0,15,1400.0,0.0,300.0,alpha+90.0+beta,tri);

}


var create_4_8_cirrocumulus_streaks = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

var beta = 90.0 + (rand() -0.5) * 30.0;

for (var i=0; i<2; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 12000;
	var y = 2.0 * (rand()-0.5) * 12000;
	var tri = 1.5 + rand() * 1.5;
	local_weather.create_streak("Cirrocumulus (cloudlet)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,10,700.0,0.1,400.0,30,700.0,0.1,400.0,alpha+beta,tri);

	}

}


var create_4_8_altocumulus_perlucidus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<20; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Altocumulus perlucidus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,4,1400.0,0.1,900.0,4,1400.0,0.1,900.0,alpha+beta,1.0);

	}

}

var create_4_8_alttstratus_streaks = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<10; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 15000;
	var y = 2.0 * (rand()-0.5) * 15000;
	var beta = (rand() -0.5) * 20.0;
	var m = 20 + int(rand() * 20);
	var n = 3 + int(rand() * 3);

	local_weather.create_streak("Cirrocumulus (cloudlet)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,600.0,m,550.0,0.0,700.0,n,550.0,0.0,450.0,alpha+beta+90,1.0);

	}

}

var create_4_8_alttstratus_patches = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<14; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Cirrocumulus (cloudlet)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,600.0,10,550.0,0.0,250.0,8,550.0,0.0,250.0,alpha+beta,1.0);

	}

}

var create_4_8_stratocumulus = func (lat, lon, alt, alpha) {

if (local_weather.detailed_clouds_flag == 1)
	{
	create_detailed_stratocumulus_bank(lat, lon, alt, alpha);
	}
else
	{
	create_stratocumulus_bank(lat, lon, alt, alpha);
	}

}


var create_2_8_stratus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<8; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Stratus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,5,900.0,0.2,500.0,7,900.0,0.2,500.0,alpha+beta,1.0);

	}

}

var create_2_8_tstratus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<8; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Stratus (thin)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,5,900.0,0.2,500.0,7,900.0,0.2,500.0,alpha+beta,1.0);

	}

}


var create_2_8_sstratus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<8; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Stratus (structured)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,5,900.0,0.2,500.0,7,900.0,0.2,500.0,alpha+beta,1.0);

	}

}







var create_2_8_sstratus_streak = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

var x = 2.0 * (rand()-0.5) * 6000;
var y = 2.0 * (rand()-0.5) * 6000;
var beta = (rand() -0.5) * 180.0;

local_weather.create_streak("Stratus (structured)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,100.0,20,1800.0,0.1,500.0,5,1700.0,0.0,500.0,alpha+beta,1.2);

}

var create_2_8_cirrostratus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<3; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 12000;
	var y = 2.0 * (rand()-0.5) * 12000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Cirrostratus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,4,2300.0,0.2,600.0,4,2300.0,0.2,600.0,alpha+beta,1.0);

	}

}

var create_2_8_cirrocumulus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<25; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Cirrocumulus (cloudlet)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,300.0,3,600.0,0.1,500.0,3,600.0,0.1,500.0,alpha+beta,1.0);

	}

}

var create_2_8_cirrus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

var x = 2.0 * (rand()-0.5) * 3000;
var y = 2.0 * (rand()-0.5) * 3000; 
	

local_weather.create_streak("Cirrus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,1500.0,3,12000.0,0.0, 4000.0, 3,12000.0,0.0,4000.0,alpha,1.0);

}

var create_2_8_alttstratus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<4; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 18000;
	var y = 2.0 * (rand()-0.5) * 18000;
	var beta = (rand() -0.5) * 180.0;
	local_weather.create_streak("Cirrocumulus (cloudlet)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,600.0,10,550.0,0.0,250.0,8,550.0,0.0,250.0,alpha+beta,1.0);

	}

}

var create_2_8_altocumulus_streaks = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i=0; i<2; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 10000;
	var y = 2.0 * (rand()-0.5) * 10000;
	var tri = 1.0 + rand();	

	local_weather.create_streak("Altocumulus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,1500.0,22,750.0,0.2,1000.0,8,750.0,0.2,1000.0,alpha ,tri);
	}
}


var create_1_8_altocumulus_scattered = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;


local_weather.create_streak("Altocumulus",lat, lon, alt,1500.0,15,0.0,0.2,19000.0,15,0.0,0.2,19000.0,alpha ,0.0);

for (var i=0; i<6; i=i+1)	
{
	var x = 2.0 * (rand()-0.5) * 14000;
	var y = 2.0 * (rand()-0.5) * 14000;
	var tri = 1.0 + rand();	

	local_weather.create_streak("Altocumulus",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt,1500.0,10,750.0,0.1,800.0,4,550.0,0.1,500.0,alpha ,tri);
	}

}


var create_1_8_cirrocumulus = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

for (var i = 0; i < 2; i = i + 1)
		{
		var x = 2.0 * (rand()-0.5) * 10000;
		var y = -6000 + i * 12000 + 2.0 * (rand()-0.5) * 1000;

		var beta = rand() * 90;
		var alt_variation = rand() * 2000;

		var path = local_weather.select_cloud_model("Cirrocumulus", "large");
		compat_layer.create_cloud(path, lat + get_lat(x,y,phi), lon+get_lon(x,y,phi),  alt + alt_variation,alpha+ beta);
		}


}


var create_1_8_cirrostratus_undulatus = func (lat, lon, alt, alpha) {

local_weather.create_undulatus("Cirrostratus",lat, lon, alt,300.0,1,8000.0,0.0,400.0,40,1000.0,0.1,100.0, 1500.0, alpha,1.0);
}


var create_1_8_contrails = func (lat, lon, alt, alpha) {


var phi = alpha * math.pi/180.0;

var n_contrails = int(rand() * 3.0) + 1;

for (var i=0; i<n_contrails; i=i+1)
	{
	var x = 2.0 * (rand()-0.5) * 5000;
	var y = 2.0 * (rand()-0.5) * 5000;
	var alt_variation = 2.0 * (rand()-0.5) * 4000.0;
	var beta = rand() * 180;
	var contrail_length = 20 + int(rand() * 30);

	local_weather.create_streak("Cirrocumulus (cloudlet)",lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt+alt_variation,100.0,contrail_length,500.0,0.2,50.0,2,100.0,0.0,300.0,alpha+beta,1.0);
	}

}

var create_thunderstorm_scenario = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
x = 2.0 * (rand()-0.5) * 12000;
y = 2.0 * (rand()-0.5) * 12000;

if (rand() > 0.6)
	{create_medium_thunderstorm(lat +get_lat(x,y,phi), lon + get_lon(x,y,phi), alt, alpha);}
else	
	{create_small_thunderstorm(lat +get_lat(x,y,phi), lon + get_lon(x,y,phi), alt, alpha);}

if (rand() > 0.5) # we do a second thunderstorm
	{
	x = 2.0 * (rand()-0.5) * 12000;
	y = 2.0 * (rand()-0.5) * 12000;
	if (rand() > 0.8)
		{create_medium_thunderstorm(lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt, alpha);}
	else
		{create_small_thunderstorm(lat+get_lat(x,y,phi), lon+get_lon(x,y,phi), alt, alpha);}
	}

# the convective layer

var strength = 0.3;
var n = int(4000 * strength) * 0.5;
local_weather.cumulus_exclusion_layer(lat, lon, alt, n, 20000.0, 20000.0, alpha, 0.3,2.5 , size(elat), elat, elon, erad);


# some turbulence in the convection layer

local_weather.create_effect_volume(3, lat, lon, 20000.0, 20000.0, alpha, 0.0, alt+3000.0, -1, -1, -1, 0.4, -1,0 ,-1);


}

var create_stratocumulus_bank = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 10000;
var y = 2.0 * (rand()-0.5) * 10000;
var tri = 1.5 + 1.5*rand();
var beta = (rand() -0.5) * 60.0;

local_weather.create_streak("Cumulus",lat+get_lat(x,y+6000,phi), lon+get_lon(x,y+6000,phi), alt,500.0,15,600.0,0.2,400.0,20,600.0,0.2,400.0,alpha+90.0+beta,tri);

local_weather.create_streak("Cumulus",lat+get_lat(x,y-6000,phi), lon+get_lon(x,y-6000,phi), alt,500.0,15,600.0,0.2,400.0,20,600.0,0.2,400.0,alpha+270.0+beta,tri);

}

var create_detailed_stratocumulus_bank = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 6000;
var y = 2.0 * (rand()-0.5) * 6000;
var tri = 1.5 + 1.5*rand();
var beta = (rand() -0.5) * 60.0;

var m = int(7 + rand() * 7);
var n = int(9 + rand() * 7);

var alt_offset = 0.5 * local_weather.cloud_vertical_size_map["Cumulus"] * ft_to_m;

local_weather.create_streak("Stratocumulus",lat+get_lat(x,y+7500,phi), lon+get_lon(x,y+7500,phi), alt + alt_offset,500.0,m,1100.0,0.1,400.0,n,1100.0,0.1,400.0,alpha+90.0+beta,tri);

local_weather.create_streak("Stratocumulus",lat+get_lat(x,y-7500,phi), lon+get_lon(x,y-7500,phi), alt + alt_offset,500.0,m,1100.0,0.1,400.0,n,1100.0,0.1,400.0,alpha+270.0+beta,tri);


local_weather.create_streak("Stratocumulus bottom",lat+get_lat(x,y+5250,phi), lon+get_lon(x,y+5250,phi), alt,0.0,m+1,700.0,0.2,400.0,n+1,700.0,0.0,400.0,alpha+90.0+beta,tri);

local_weather.create_streak("Stratocumulus bottom",lat+get_lat(x,y-5250,phi), lon+get_lon(x,y-5250,phi), alt,0.0,m+1,700.0,0.2,400.0,n+1,700.0,0.0,400.0,alpha+270.0+beta,tri);

}


var create_detailed_small_stratocumulus_bank = func (lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;
var x = 2.0 * (rand()-0.5) * 12000;
var y = 2.0 * (rand()-0.5) * 12000;
var tri = 1.5 + 1.5*rand();
var beta = (rand() -0.5) * 60.0;

var m = int(5 + rand() * 5);
var n = int(6 + rand() * 5);

var alt_offset = 0.5 * local_weather.cloud_vertical_size_map["Cumulus"] * ft_to_m;

local_weather.create_streak("Stratocumulus",lat+get_lat(x,y+7500,phi), lon+get_lon(x,y+7500,phi), alt + alt_offset,500.0,m,1100.0,0.12,400.0,n,1100.0,0.12,400.0,alpha+90.0+beta,tri);

local_weather.create_streak("Stratocumulus",lat+get_lat(x,y-7500,phi), lon+get_lon(x,y-7500,phi), alt + alt_offset,500.0,m,1100.0,0.12,400.0,n,1100.0,0.12,400.0,alpha+270.0+beta,tri);


local_weather.create_streak("Stratocumulus bottom",lat+get_lat(x,y+7050,phi), lon+get_lon(x,y+7050,phi), alt,0.0,m,700.0,0.2,400.0,n,700.0,0.0,400.0,alpha+90.0+beta,tri);

local_weather.create_streak("Stratocumulus bottom",lat+get_lat(x,y-7050,phi), lon+get_lon(x,y-7050,phi), alt,0.0,m,700.0,0.2,400.0,n,700.0,0.0,400.0,alpha+270.0+beta,tri);

}


var create_cloud_bank = func (type, lat, lon, alt, x1, x2, height, n, alpha) {

local_weather.create_streak(type,lat,lon, alt+ 0.5* height,height,n,0.0,0.0,x1,1,0.0,0.0,x2,alpha,1.0);


}

var create_small_thunderstorm = func(lat, lon, alt, alpha) {

var scale = 0.7 + rand() * 0.3;

local_weather.create_layer("Stratus", lat, lon, alt, 1000.0, 4000.0 * scale, 4000.0 * scale, 0.0, 1.0, 0.3, 1, 1.0);

local_weather.create_layer("Cumulonimbus (cloudlet)", lat, lon, alt+2000, 15000.0, 3000.0 * scale, 3000.0 * scale, 0.0, 2.0, 0.0, 0, 0.0);

# set the exclusion region for the Cumulus layer
append(elat, lat); append(elon, lon); append(erad, 4000.0 * scale * 1.2);

# set precipitation, visibility, updraft and turbulence in the cloud

local_weather.create_effect_volume(1, lat, lon, 4000.0 * 0.7 * scale, 4000.0 * 0.7 * scale , 0.0, 0.0, 20000.0, 600.0, 0.8, -1, 0.6, 15.0,1 ,-1);

}

var create_medium_thunderstorm = func(lat, lon, alt, alpha) {

var scale = 0.7 + rand() * 0.3;

local_weather.create_layer("Nimbus", lat, lon, alt, 500.0, 6000.0 * scale, 6000.0 * scale, 0.0, 1.0, 0.3, 1, 1.5);

#local_weather.create_layer("Stratus", lat, lon, alt+1500, 1000.0, 5500.0 * scale, 5500.0 * scale, 0.0, 1.0, 0.3, 0, 0.0);
local_weather.create_hollow_layer("Stratus", lat, lon, alt+1500, 1000.0, 5500.0 * scale, 5500.0 * scale, 0.0, 1.0, 0.3, 0.5);

local_weather.create_layer("Fog (thick)", lat, lon, alt+4000, 6000.0, 3400.0 * scale, 3400.0 * scale, 0.0, 1.5, 0.3, 0, 0.0);


local_weather.create_layer("Cumulonimbus (cloudlet)", lat, lon, alt+10000, 10000.0, 3600.0 * scale, 3600.0 * scale, 0.0, 1.2, 0.0, 0, 0.0);

# set the exclusion region for the Cumulus layer
append(elat, lat); append(elon, lon); append(erad, 6000.0 * scale * 1.2);

# set precipitation, visibility, updraft and turbulence in the cloud

local_weather.create_effect_volume(1, lat, lon, 6000.0 * 0.7 * scale, 6000.0 * 0.7 * scale , 0.0, 0.0, 20000.0, 500.0, 1.0, -1, 0.8, 20.0,1,-1 );

}

var create_big_thunderstorm = func(lat, lon, alt, alpha) {

var phi = alpha * math.pi/180.0;

var scale = 0.8;

local_weather.create_layer("Nimbus", lat, lon, alt, 500.0, 7500.0 * scale, 7500.0 * scale, 0.0, 1.0, 0.25, 1, 1.5);

#local_weather.create_layer("Stratus", lat, lon, alt+1500, 1000.0, 7200.0 * scale, 7200.0 * scale, 0.0, 1.0, 0.3, 0, 0.0);
local_weather.create_hollow_layer("Stratus", lat, lon, alt+1500, 1000.0, 7200.0 * scale, 7200.0 * scale, 0.0, 1.0, 0.3, 0.7);

local_weather.create_layer("Fog (thick)", lat, lon, alt+5000, 3000.0, 5500.0 * scale, 5500.0 * scale, 0.0, 0.7, 0.3, 0, 0.0);


local_weather.create_layer("Fog (thick)", lat+get_lat(0,-1000,phi), lon+get_lon(0,-1000,phi), alt+12000, 4000.0, 6300.0 * scale, 6300.0 * scale, 0.0, 0.7, 0.3, 0, 0.0);

#local_weather.create_layer("Stratus", lat+get_lat(0,-2000,phi), lon+get_lon(0,-2000,phi), alt+17000, 1000.0, 7500.0 * scale, 7500.0 * scale, 0.0, 1.0, 0.3, 0, 0.0);
local_weather.create_hollow_layer("Stratus", lat+get_lat(0,-2000,phi), lon+get_lon(0,-2000,phi), alt+17000, 1000.0, 7500.0 * scale, 7500.0 * scale, 0.0, 1.0, 0.3, 0.5);

#local_weather.create_layer("Stratus", lat+get_lat(0,-3000,phi), lon+get_lon(0,-3000,phi), alt+20000, 1000.0, 9500.0 * scale, 9500.0 * scale, 0.0, 1.0, 0.3, 0, 0.0);
local_weather.create_hollow_layer("Stratus", lat+get_lat(0,-3000,phi), lon+get_lon(0,-3000,phi), alt+20000, 1000.0, 9500.0 * scale, 9500.0 * scale, 0.0, 1.0, 0.3, 0.5);

local_weather.create_layer("Stratus (thin)", lat+get_lat(0,-4000,phi), lon+get_lon(0,-4000,phi), alt+24000, 1000.0, 11500.0 * scale, 11500.0 * scale, 0.0, 2.0, 0.3, 0, 0.0);

# set the exclusion region for the Cumulus layer
append(elat, lat); append(elon, lon); append(erad, 7500.0 * scale * 1.2);

local_weather.create_effect_volume(1, lat, lon, 7500.0 * 0.7 * scale, 7500.0 * 0.7 * scale , 0.0, 0.0, 20000.0, 500.0, 1.0, -1, 1.0, 25.0,1,-1 );

}

###################
# helper functions
###################

var calc_geo = func(clat) {

lon_to_m  = math.cos(clat*math.pi/180.0) * lat_to_m;
m_to_lon = 1.0/lon_to_m;
}

var get_lat = func (x,y,phi) {

return (y * math.cos(phi) - x * math.sin(phi)) * m_to_lat;
}

var get_lon = func (x,y,phi) {

return (x * math.cos(phi) + y * math.sin(phi)) * m_to_lon;
}


var get_n = func(strength) {

return int(4000 * strength);
}


##################################
# continuity condition of pressure
##################################

var adjust_p = func (p) {

if (last_pressure == 0.0) {last_pressure = p; return p;}

var pressure_difference = p - last_pressure;

if (pressure_difference > 2.0) {var pout = last_pressure + 3.0;}
else if (pressure_difference < -2.0) {var pout = last_pressure - 3.0;}
else {var pout = p;}

last_pressure = pout;

return pout;
}


###################
# global variables
###################



var lat_to_m = 110952.0; # latitude degrees to meters
var m_to_lat = 9.01290648208234e-06; # meters to latitude degrees
var ft_to_m = 0.30480;
var m_to_ft = 1.0/ft_to_m;
var inhg_to_hp = 33.76389;
var hp_to_inhg = 1.0/inhg_to_hp;

var last_pressure = 0.0;

var lon_to_m = 0.0; # needs to be calculated dynamically
var m_to_lon = 0.0; # we do this on startup
var lw = "/local-weather/";

var small_scale_persistence = getprop(lw~"config/small-scale-persistence");
var rnd_store = 0.0;

var elat = [];
var elon = [];
var erad = [];
