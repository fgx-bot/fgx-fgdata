# debug.nas -- debugging helpers
#------------------------------------------------------------------------------
#
# debug.dump(<variable>)               ... dumps contents of variable to terminal;
#                                          abbreviation for print(debug.string(v))
#
# debug.local([<frame:int>])           ... dump local variables of current
#                                          or given frame
#
# debug.backtrace([<comment:string>]}  ... writes backtrace with local variables
#                                          (similar to gdb's "bt full)
#
# debug.proptrace([<property [, <frames>]]) ... trace property write/add/remove
#                                          events under the <property> subtree for
#                                          a number of frames. Defaults are "/" and
#                                          2 frames (of which the first one is incomplete).
#
# debug.tree([<property> [, <mode>])   ... dump property tree under property path
#                                          or props.Node hash (default: root). If
#                                          <mode> is unset or 0, use flat mode
#                                          (similar to props.dump()), otherwise
#                                          use space indentation
#
# debug.bt()                           ... abbreviation for debug.backtrace()
#
# debug.string(<variable>)             ... returns contents of variable as string
#
# debug.attributes(<property> [, <verb>]) ... returns attribute string for a given property.
#                                          <verb>ose is by default 1, and suppressed the
#                                          node's refcounter if 0.
#
# debug.isnan()                            returns 1 if argument is an invalid number (NaN),
#                                          0 if it's a valid number, and nil in all other cases
#
# debug.benchmark(<label:string>, <func> [, <repeat:int>])
#                                      ... runs function <repeat> times (default: 1)
#                                          and prints execution time in seconds,
#                                          prefixed with <label>.
#
# debug.printerror(<err-vector>)       ... prints error vector as set by call()
#
# debug.warn(<message>, <level>)       ... generate debug message followed by caller stack trace
#                                          skipping <level> caller levels (default: 0).
#
# debug.propify(<variable>)            ... turn about everything into a props.Node
#
# CAVE: this file makes extensive use of ANSI color codes. These are
#       interpreted by UNIX shells and MS Windows with ANSI.SYS extension
#       installed. If the color codes aren't interpreted correctly, then
#       set property /sim/startup/terminal-ansi-colors=0
#

# ANSI color code wrappers  (see  $ man console_codes)
#
var _title       = func(s) globals.string.color("33;42;1", s); # backtrace header
var _section     = func(s) globals.string.color("37;41;1", s); # backtrace frame
var _error       = func(s) globals.string.color("31;1",    s); # internal errors
var _bench       = func(s) globals.string.color("37;45;1", s); # benchmark info

var _nil         = func(s) globals.string.color("32", s);      # nil
var _string      = func(s) globals.string.color("31", s);      # "foo"
var _num         = func(s) globals.string.color("31", s);      # 0.0
var _bracket     = func(s) globals.string.color("", s);        # [ ]
var _brace       = func(s) globals.string.color("", s);        # { }
var _angle       = func(s) globals.string.color("", s);        # < >
var _vartype     = func(s) globals.string.color("33", s);      # func ghost
var _proptype    = func(s) globals.string.color("34", s);      # BOOL INT LONG DOUBLE ...
var _path        = func(s) globals.string.color("36", s);      # /some/property/path
var _internal    = func(s) globals.string.color("35", s);      # me parents
var _varname     = func(s) s;                                  # variable_name


##
# Turn p into props.Node (if it isn't yet), or return nil.
#
var propify = func(p, create = 0) {
	var type = typeof(p);
	if (type == "ghost" and ghosttype(p) == "prop")
		return props.wrapNode(p);
	if (type == "scalar" and num(p) == nil)
		return props.globals.getNode(p, create);
	if (isa(p, props.Node))
		return p;
	return nil;
}


var tree = func(n = "", graph = 1) {
	n = propify(n);
	if (n == nil)
		return dump(n);
	_tree(n, graph);
}


var _tree = func(n, graph = 1, prefix = "", level = 0) {
	var path = n.getPath();
	var children = n.getChildren();
	var s = "";

	if (graph) {
		s = prefix ~ n.getName();
		var index = n.getIndex();
		if (index)
			s ~= "[" ~ index ~ "]";
	} else {
		s = n.getPath();
	}

	if (size(children)) {
		s ~= "/";
		if (n.getType() != "NONE")
			s ~= " = " ~ debug.string(n.getValue()) ~ " " ~ attributes(n)
					~ "    " ~ _section(" PARENT-VALUE ");
	} else {
		s ~= " = " ~ debug.string(n.getValue()) ~ " " ~ attributes(n);
	}

	if ((var a = n.getAliasTarget()) != nil)
		s ~= "  " ~ _title(" alias to ") ~ "  " ~ a.getPath();

	print(s);

	if (n.getType() != "ALIAS")
		forindex (var i; children)
			_tree(children[i], graph, prefix ~ ".   ", level + 1);
}


var attributes = func(p, verbose = 1) {
	var r = p.getAttribute("readable")    ? "" : "r";
	var w = p.getAttribute("writable")    ? "" : "w";
	var R = p.getAttribute("trace-read")  ? "R" : "";
	var W = p.getAttribute("trace-write") ? "W" : "";
	var A = p.getAttribute("archive")     ? "A" : "";
	var U = p.getAttribute("userarchive") ? "U" : "";
	var P = p.getAttribute("preserve")    ? "P" : "";
	var T = p.getAttribute("tied")        ? "T" : "";
	var attr = r ~ w ~ R ~ W ~ A ~ U ~ P ~ T;
	var type = "(" ~ p.getType();
	if (size(attr))
		type ~= ", " ~ attr;
	if (var l = p.getAttribute("listeners"))
		type ~= ", L" ~ l;
	if (verbose and (var c = p.getAttribute("references")) > 2)
		type ~= ", #" ~ (c - 2);
	return _proptype(type ~ ")");
}


var _dump_prop = func(p) {
	_path(p.getPath()) ~ " = " ~ debug.string(p.getValue()) ~ " " ~ attributes(p);
}


var _dump_var = func(v) {
	if (v == "me" or v == "parents")
		return _internal(v);
	else
		return _varname(v);
}


var _dump_string = func(str) {
	var s = "'";
	for (var i = 0; i < size(str); i += 1) {
		var c = str[i];
		if (c == `\``)
			s ~= "\\`";
		elsif (c == `\n`)
			s ~= "\\n";
		elsif (c == `\r`)
			s ~= "\\r";
		elsif (c == `\t`)
			s ~= "\\t";
		elsif (globals.string.isprint(c))
			s ~= chr(c);
		else
			s ~= sprintf("\\x%02x", c);
	}
	return _string(s ~ "'");
}


# dump hash keys as variables if they are valid variable names, or as string otherwise
var _dump_key = func(s) {
	if (num(s) != nil)
		return _num(s);
	if (!size(s))
		return _dump_string(s);
	if (!globals.string.isalpha(s[0]) and s[0] != `_`)
		return _dump_string(s);
	for (var i = 1; i < size(s); i += 1)
		if (!globals.string.isalnum(s[i]) and s[i] != `_`)
			return _dump_string(s);
	_dump_var(s);
}


var string = func(o) {
	var t = typeof(o);
	if (t == "nil") {
		return _nil("nil");

	} elsif (t == "scalar") {
		return num(o) == nil ? _dump_string(o) : _num(o);

	} elsif (t == "vector") {
		var s = "";
		forindex (var i; o)
			s ~= (i == 0 ? "" : ", ") ~ debug.string(o[i]);
		return _bracket("[") ~ s ~ _bracket("]");

	} elsif (t == "hash") {
		if (contains(o, "parents") and typeof(o.parents) == "vector"
				and size(o.parents) == 1 and o.parents[0] == props.Node)
			return _angle("<") ~ _dump_prop(o) ~ _angle(">");

		var k = keys(o);
		var s = "";
		forindex (var i; k)
			s ~= (i == 0 ? "" : ", ") ~ _dump_key(k[i]) ~ ": " ~ debug.string(o[k[i]]);
		return _brace("{") ~ " " ~ s ~ " " ~ _brace("}");

	} elsif (t == "ghost") {
		return _angle("<") ~ _nil(ghosttype(o)) ~ _angle(">");

	} else {
		return _angle("<") ~ _vartype(t) ~ _angle(">");
	}
}


var dump = func(vars...) {
	if (!size(vars))
		return local(1);
	if (size(vars) == 1)
		return print(debug.string(vars[0]));
	forindex (var i; vars)
		print(globals.string.color("33;40;1", "#" ~ i) ~ " ", debug.string(vars[i]));
}


var local = func(frame = 0) {
	var v = caller(frame + 1);
	print(v == nil ? _error("<no such frame>") : debug.string(v[0]));
	return v;
}


var backtrace = func(desc = nil) {
	var d = desc == nil ? "" : " '" ~ desc ~ "'";
	print("\n" ~ _title("\n### backtrace" ~ d ~ " ###"));
	for (var i = 1; 1; i += 1) {
		if ((var v = caller(i)) == nil)
			return;
		print(_section(sprintf("#%-2d called from %s, line %s:", i - 1, v[2], v[3])));
		dump(v[0]);
	}
}
var bt = backtrace;


var proptrace = func(root = "/", frames = 2) {
	var events = 0;
	var trace = setlistener(propify(root), func(this, base, type) {
		events += 1;
		if (type > 0)
			print(_nil("ADD "), this.getPath());
		elsif (type < 0)
			print(_num("DEL "), this.getPath());
		else
			print("SET ", this.getPath(), " = ", debug.string(this.getValue()), " ", attributes(this));
	}, 0, 2);
	var mark = setlistener("/sim/signals/frame", func {
		print("-------------------- FRAME --------------------");
		if (!frames) {
			removelistener(trace);
			removelistener(mark);
			print("proptrace: stop (", events, " calls)");
		}
		frames -= 1;
	});
}


##
# Executes function fn "repeat" times and prints execution time in seconds. Examples:
#
#     var test = func { getprop("/sim/aircraft"); }
#     debug.benchmark("test()/1", test, 1000);
#     debug.benchmark("test()/2", func setprop("/sim/aircraft", ""), 1000);
#
var benchmark = func(label, fn, repeat = 1) {
	var start = systime();
	for (var i = 0; i < repeat; i += 1)
		fn();
	print(_bench(sprintf(" %s --> %.6f s ", label, systime() - start)));
}


##
# print error vector as set by call(). By using call() one can execute
# code that catches "exceptions" (by a die() call or errors). The Nasal
# code doesn't abort in this case. Example:
#
#     var possibly_buggy = func { ... }
#     call(possibly_buggy, nil, var err = []);
#     debug.printerror(err);
#
var printerror = func(err) {
	if (!size(err))
		return;
	printf("%s:\n at %s, line %d", err[0], err[1], err[2]);
	for (var i = 3; i < size(err); i += 2)
		printf("  called from: %s, line %d", err[i], err[i + 1]);
}


# like die(), but code execution continues. The level argument defines
# how many caller() levels to omit. One is automatically omitted, as
# this would only point to debug.warn(), where the event in question
# didn't happen.
#
var warn = func(msg, level = 0) {
	var c = caller(level += 1);
	if (c == nil)
		die("debug.warn with invalid level argument");
	printf("%s:\n  at %s, line %d", msg, c[2], c[3]);
	while ((c = caller(level += 1)) != nil)
		printf("  called from: %s, line %d", c[2], c[3]);
}


var isnan = func {
	call(math.sin, arg, var err = []);
	return !!size(err);
}


# --prop:debug=1 enables debug mode with additional warnings
#
_setlistener("sim/signals/nasal-dir-initialized", func {
	if (!getprop("debug"))
		return;
	var writewarn = func(f, p, r) {
		if (!r) {
			var hint = "";
			if ((var n = props.globals.getNode(p)) != nil) {
				if (!n.getAttribute("writable"))
					hint = " (write protected)";
				elsif (n.getAttribute("tied"))
					hint = " (tied)";
			}
			warn("Warning: " ~ f ~ " -> writing to " ~ p ~ " failed" ~ hint, 2);
		}
		return r;
	}
	setprop = (func { var _ = setprop; func writewarn("setprop",
			globals.string.join("", arg[:-2]), call(_, arg)) })();
	props.Node.setDoubleValue = func writewarn("setDoubleValue", me.getPath(),
			props._setDoubleValue(me._g, arg));
	props.Node.setBoolValue = func writewarn("setBoolValue", me.getPath(),
			props._setBoolValue(me._g, arg));
	props.Node.setIntValue = func writewarn("setIntValue", me.getPath(),
			props._setIntValue(me._g, arg));
	props.Node.setValue = func writewarn("setValue", me.getPath(),
			props._setValue(me._g, arg));
});


