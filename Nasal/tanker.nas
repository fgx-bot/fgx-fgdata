if (globals["tanker"] != nil) {
	# reload with io.load_nasal(getprop("/sim/fg-root") ~ "/Nasal/tanker.nas");
	print("reloading " ~ caller(0)[2]);
	var _setlistener = reinit;
	reinit();
}
#--------------------------------------------------------------------------------------------------


var boom_tanker = "Models/Geometry/KC135/KC135.xml";
var probe_tanker = "Models/Geometry/KA6-D/KA6-D.xml";


var oclock = func(bearing) int(0.5 + geo.normdeg(bearing) / 30) or 12;


var tanker_msg = func setprop("sim/messages/ai-plane", call(sprintf, arg));
var pilot_msg = func setprop("/sim/messages/pilot", call(sprintf, arg));
var atc_msg = func setprop("sim/messages/atc", call(sprintf, arg));


var skip_cloud_layer = func(alt) {
	var c = [];
	foreach (var layer; props.globals.getNode("/environment/clouds").getChildren("layer")) {
		var elev = (layer.getNode("elevation-ft", 1).getValue() or -9999) * FT2M;
		var thck = (layer.getNode("thickness-ft", 1).getValue() or 0) * FT2M;
		if (elev > -1000)
			append(c, { bottom: elev - thck * 0.5 - 100, top: elev + thck * 0.5 + 100 });
	}
	while (check; 1) {
		foreach (var layer; c) {
			if (alt > layer.bottom and alt < layer.top) {
				alt += 1000;
				continue check;
			}
		}
		return alt;
	}
}


var identity = {
	get: func {
		# return free AI id number and least used, free callsign/channel pair
		var data = {};     # copy of me.pool
		var revdata = {};  # channel->callsign
		foreach (var k; keys(me.pool)) {
			data[k] = me.pool[k];
			revdata[me.pool[k][0]] = k;
		}
		var id_used = {};
		foreach (var t; props.globals.getNode("ai/models", 1).getChildren()) {
			if ((var c = t.getNode("callsign")) != nil)
				delete(data, c.getValue() or "");
			if ((var c = t.getNode("navaids/tacan/channel-ID")) != nil)
				delete(data, revdata[c.getValue() or ""]);
			if ((var c = t.getNode("id")) != nil)
				id_used[c.getValue()] = 1;
		}
		for (var aiid = -2; aiid; aiid -= 1)
			if (!id_used[aiid])
				break;
		if (!size(data))
			return [aiid, "MOBIL3", "062X"];
		var d = sort(keys(data), func(a, b) data[a][1] - data[b][1])[0];
		me.pool[d][1] += 1;
		return [aiid, d, data[d][0]];
	},
	pool: {
		ESSO1: ["040X", rand()], ESSO2: ["041X", rand()], ESSO3: ["042X", rand()],
		TEXACO1: ["050X", rand()], TEXACO2: ["051X", rand()], TEXACO3: ["052X", rand()],
		MOBIL1: ["060X", rand()], MOBIL2: ["061X", rand()], MOBIL3: ["062X", rand()],
	},
};


var Tanker = {
	new: func(aiid, callsign, tacan, type, kias, heading, coord) {
		var m = { parents: [Tanker] };
		m.callsign = callsign;
		m.tacan = tacan;
		m.kias = kias;
		m.heading = m.course = m.track_course = heading;
		m.out_of_range_time = 0;
		m.interval = 10;
		m.length = (getprop("tanker/pattern-length-nm") or 50) * NM2M;
		m.roll = 0;
		m.coord = geo.Coord.new(coord);
		m.anchor = geo.Coord.new(coord).apply_course_distance(m.track_course, m.length); # ARCP
		m.goal = [nil, m.anchor];
		m.lastmode = "none";
		m.mode = "leg";
		m.rollrate = 2; # deg/s
		m.maxbank = 25;

		var n = props.globals.getNode("models", 1);
		for (var i = 0; 1; i += 1)
			if (n.getChild("model", i, 0) == nil)
				break;
		m.model = n.getChild("model", i, 1);

		var n = props.globals.getNode("ai/models", 1);
		for (var i = 0; 1; i += 1)
			if (n.getChild("tanker", i, 0) == nil)
				break;
		m.ai = n.getChild("tanker", i, 1);

		m.ai.getNode("id", 1).setIntValue(aiid);
		m.ai.getNode("callsign", 1).setValue(m.callsign ~ "");
		m.ai.getNode("tanker", 1).setBoolValue(1);
		m.ai.getNode("valid", 1).setBoolValue(1);
		m.ai.getNode("navaids/tacan/channel-ID", 1).setValue(m.tacan);
		m.ai.getNode("refuel/type", 1).setValue(type);
		m.ai.getNode("refuel/contact", 1).setBoolValue(0);

		m.latN = m.ai.getNode("position/latitude-deg", 1);
		m.lonN = m.ai.getNode("position/longitude-deg", 1);
		m.altN = m.ai.getNode("position/altitude-ft", 1);
		m.hdgN = m.ai.getNode("orientation/true-heading-deg", 1);
		m.pitchN = m.ai.getNode("orientation/pitch-deg", 1);
		m.rollN = m.ai.getNode("orientation/roll-deg", 1);
		m.ktasN = m.ai.getNode("velocities/true-airspeed-kt", 1);
		m.vertN = m.ai.getNode("velocities/vertical-speed-fps", 1);
		m.rangeN = m.ai.getNode("radar/range-nm", 1);
		m.brgN = m.ai.getNode("radar/bearing-deg", 1);
		m.elevN = m.ai.getNode("radar/elevation-deg", 1);
		m.contactN = m.ai.getNode("refuel/contact", 1);

		m.update();
		m.model.getNode("path", 1).setValue(type == "boom" ? boom_tanker : probe_tanker);
		m.model.getNode("latitude-deg-prop", 1).setValue(m.latN.getPath());
		m.model.getNode("longitude-deg-prop", 1).setValue(m.lonN.getPath());
		m.model.getNode("elevation-ft-prop", 1).setValue(m.altN.getPath());
		m.model.getNode("heading-deg-prop", 1).setValue(m.hdgN.getPath());
		m.model.getNode("pitch-deg-prop", 1).setValue(m.pitchN.getPath());
		m.model.getNode("roll-deg-prop", 1).setValue(m.rollN.getPath());
		m.model.getNode("load", 1).remove();
		m.identify();
		return Tanker.active[m.callsign] = m;
	},
	del: func {
		tanker_msg(me.callsign ~ " returns to base");
		me.model.remove();
		me.ai.remove();
		delete(Tanker.active, me.callsign);
	},
	update: func {
		var dt = getprop("sim/time/delta-sec");
		var alt = me.coord.alt();

		if ((me.interval += dt) >= 5) {
			me.interval -= 5;
			me.headwind = aircraft.wind_speed_from(me.course);
			me.ktas = aircraft.kias_to_ktas(me.kias, alt);
		}

		var distance = dt * (me.ktas - me.headwind) * NM2M / 3600;
		var deviation = me.roll ? 0.5 * dt * 1085.941 * math.tan(me.roll * D2R) / me.ktas : 0;

		if (me.mode == "leg") {
			if (me.lastmode != "leg") {
				me.lastmode = "leg";
				# swap ARCP anchor and tanker exit point as leg end points
				var g = me.goal[0];
				me.goal[0] = me.goal[1];
				me.goal[1] = g;

				me.course = me.coord.course_to(me.goal[0]);
				me.leg_remaining = me.coord.distance_to(me.goal[0]);
				me.roll_target = 0;
				me.leg_warning = 0;
			}
			if ((me.leg_remaining -= distance) < 0)
				me.mode = "turn";

		} else { # me.mode == "turn"
			if (me.lastmode != "turn") {
				me.lastmode = "turn";
				me.full_bank_turn_angle = 0;
				me.turn_remaining = 180;
				me.roll_target = 25;
			}
			if (!me.full_bank_turn_angle and me.roll >= me.roll_target)
				me.full_bank_turn_angle = geo.normdeg(180 - me.turn_remaining);

			if (me.turn_remaining < me.full_bank_turn_angle)
				me.roll_target = 0;

			if ((me.turn_remaining -= deviation) < 0) {
				if (me.goal[1] == nil)  # define tanker exit point (opposite of anchor point/ARCP)
					me.goal[1] = geo.Coord.new(me.coord).apply_course_distance(me.track_course - 180,
							me.length);
				me.mode = "leg";
			}
		}

		me.coord.apply_course_distance(me.course -= deviation, distance);

		me.ac = geo.aircraft_position();
		me.distance = me.ac.distance_to(me.coord);
		me.bearing = me.ac.course_to(me.coord);

		var dalt = alt - me.ac.alt();
		var ac_hdg = getprop("/orientation/heading-deg");

		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(alt * M2FT);
		me.hdgN.setDoubleValue(me.heading = me.course);
		me.pitchN.setDoubleValue(0);
		me.rollN.setDoubleValue(-me.roll);
		me.ktasN.setDoubleValue(me.ktas);
		me.vertN.setDoubleValue(0);
		me.rangeN.setDoubleValue(me.distance * M2NM);
		me.brgN.setDoubleValue(me.bearing);
		me.elevN.setDoubleValue(math.atan2(dalt, me.distance) * R2D);
		me.contactN.setBoolValue(me.distance < 76 and dalt > 0  # 250 ft
				and abs(view.normdeg(me.bearing - ac_hdg)) < 20);

		var droll = me.roll_target - me.roll;
		if (droll > 0) {
			me.roll += me.rollrate * dt;
			if (me.roll > me.roll_target)
				me.roll = me.roll_target;
		} elsif (droll < 0) {
			me.roll -= me.rollrate * dt;
			if (me.roll < me.roll_target)
				me.roll = me.roll_target;
		}

		if (!me.leg_warning and me.leg_remaining < NM2M) {
			tanker_msg(me.callsign ~ ", turn in one mile");
			me.leg_warning = 1;
		}

		me.now = getprop("/sim/time/elapsed-sec");
		if (me.distance < 90000)
			me.out_of_range_time = me.now;
		elsif (me.now - me.out_of_range_time > 600)
			return me.del();
		settimer(func me.update(), 0);
	},
	identify: func {
		me.out_of_range_time = me.now;
		var alt = int((me.coord.alt() * M2FT + 50) / 100) * 100;
		tanker_msg("%s at %.0f, heading %.0f with %.0f knots, TACAN %s",
				me.callsign, alt, me.course, me.kias, me.tacan);
	},
	report: func {
		me.out_of_range_time = me.now;
		var dist = int(me.distance * M2NM);
		var hdg = getprop("orientation/heading-deg");
		var diff = (me.coord.alt() - me.ac.alt()) * M2FT;
		var qual = diff > 3000 ? " well" : abs(diff) > 1000 ? " slightly" : "";
		var rel = diff > 1000 ? " above" : diff < -1000 ? " below" : "";
		atc_msg("Tanker %s is at %s o'clock%s",
				me.callsign, oclock(me.ac.course_to(me.coord) - hdg),
				qual ~ rel);
	},
	active: {},
};



var request = func {
	var tanker = values(Tanker.active);
	if (size(tanker))
		return tanker[0].identify();

	var type = props.globals.getNode("systems/refuel", 1).getChildren("type");
	if (!size(type))
		return;
	type = type[rand() * size(type)].getValue();

	var (aiid, callsign, tacanid) =_= identity.get();
	var hdg = getprop("orientation/heading-deg");
	var course = hdg + (rand() - 0.5) * 60;
	var dist = 6000 + rand() * 4000;
	var alt = int(10 + rand() * 15) * 1000;  # FL100--FL250
	alt = skip_cloud_layer(alt * FT2M);
	var coord = geo.aircraft_position().apply_course_distance(course, dist).set_alt(alt);
	Tanker.new(aiid, callsign, tacanid, type, 250, hdg, coord);
}


var request_random = func {
        var tanker = values(Tanker.active);
        if (size(tanker))
                return tanker[0].identify();

        var type = props.globals.getNode("systems/refuel", 1).getChildren("type");
        if (!size(type))
                return;
        type = type[rand() * size(type)].getValue();

        var (aiid, callsign, tacanid) =_= identity.get();
        var hdg = rand() * 360;
        var course = rand() * 360;
        var dist = 6000 + rand() * 4000;
        var alt = int(10 + rand() * 15) * 1000;  # FL100--FL250
        alt = skip_cloud_layer(alt * FT2M);
        var coord = geo.aircraft_position().apply_course_distance(course, dist).set_alt(alt);
        Tanker.new(aiid, callsign, tacanid, type, 250, hdg, coord);
}


var report = func {
	var tanker = values(Tanker.active);
	if (size(tanker))
		tanker[0].report();
}


var reinit = func {
	foreach (var t; values(Tanker.active))
		t.del();
}


_setlistener("/sim/signals/nasal-dir-initialized", func {
	var aar_capable = size(props.globals.getNode("systems/refuel", 1).getChildren("type"));
	gui.menuEnable("tanker", aar_capable);
	if (!aar_capable)
		request = func { atc_msg("no tanker in range") }; # braces mandatory

	setlistener("/sim/signals/reinit", reinit, 1);
});

