# Cockpit view: translate view along x axis when look far right or far left.
var xAxisViewLowpass = aircraft.lowpass.new(0.15);
xAxisViewLowpass.set(0.0);

var pilot_view_limiter = {
	init : func {
		me.hdgN = props.globals.getNode("/sim/current-view/heading-offset-deg", 1);
		me.xViewAxisN = props.globals.getNode("/sim/current-view/x-offset-m", 1);
		me.currViewNumbN = props.globals.getNode("sim/current-view/view-number", 1);
	},
	update : func {
		var hdg = view.normdeg(me.hdgN.getValue());
		var xAxisVal = me.xViewAxisN.getValue();
#		var currViewNumb = me.currViewNumbN.getValue();
		var updateHdg = 0;
		var updateXaxis = 0;

		# set min/max heading view degree.
		var headingMax = view.current.getNode("config/heading-normdeg-max").getValue();
		var headingMin = view.current.getNode("config/heading-normdeg-min").getValue();

		#set the static x offset
		var norm_offset = view.current.getNode("config/x-offset-m").getValue();

		if((headingMax != nil) and (hdg > headingMax)) {
			hdg = headingMax;
			updateHdg = 1;
		} elsif((headingMin != nil) and (hdg < headingMin)) {
			hdg = headingMin;
			updateHdg = 1;
		}

		if(updateHdg)
			me.hdgN.setDoubleValue(hdg);
		
		# translate view on X axis to look far right or far left.
		var xAxisTranslate = view.current.getNode("config/x-trans-m").getValue();
		var xAxisHeadingMax = view.current.getNode("config/x-trans-heading-normdeg-max").getValue();
		var xAxisHeadingMin = view.current.getNode("config/x-trans-heading-normdeg-min").getValue();

		if((xAxisTranslate != nil) and (xAxisHeadingMax != nil) and (xAxisHeadingMin != nil)) {
			if((hdg <= xAxisHeadingMin) and (xAxisVal != xAxisTranslate)) {
				updateXaxis = 1;
				xAxisVal = xAxisTranslate;
			} elsif((hdg >= xAxisHeadingMax) and (xAxisVal != (xAxisTranslate * -1))) {
				updateXaxis = 1;
				xAxisVal = xAxisTranslate * -1;
			} elsif((hdg > xAxisHeadingMin) and (hdg < xAxisHeadingMax) and (xAxisVal != 0.0)) {
				updateXaxis = 1;
				xAxisVal = norm_offset;
#       print (me.xViewAxisN.getValue(), norm_offset);
			}
		}

		if(updateXaxis) {
			xAxisVal = xAxisViewLowpass.filter(xAxisVal);
			if((xAxisVal > norm_offset- 0.05) 
				and (xAxisVal < norm_offset + 0.05)) {
				xAxisVal = norm_offset; 
			}
			me.xViewAxisN.setDoubleValue(xAxisVal);
		}

		return 0;
	},
};

view.panViewDir = func(step) {
	if(getprop("/sim/freeze/master"))
		var prop = "/sim/current-view/heading-offset-deg";
	else
		var prop = "/sim/current-view/goal-heading-offset-deg";
	var viewVal = getprop(prop);
	var delta = step * view.VIEW_PAN_RATE * getprop("/sim/time/delta-realtime-sec");
	var viewValSlew = viewVal + delta;
	viewValSlew = view.normdeg(viewValSlew);
#var currViewNumb = getprop("sim/current-view/view-number");
	var headingMax = view.current.getNode("config/heading-normdeg-max");
	var headingMin = view.current.getNode("config/heading-normdeg-min");
	if((headingMax != nil) and (viewValSlew > headingMax))
		viewValSlew = headingMax;
	elsif((headingMin != nil) and (viewValSlew < headingMin))
		viewValSlew = headingMin;
	setprop(prop, viewValSlew);
}

setlistener("/sim/signals/fdm-initialized", func {
	view.manager.register("Cockpit View", pilot_view_limiter);
	}
);