
      var debug_enabled = 0;
     
      ## helpers
      #
      var FT2M=0.30480;
      var KT2MPS=1852/3600;
      var square=func(x) return x*x;
      var get_delta=func (current,previous) {return (current-previous);} 
      var state = {new:func {return{parents:[state]};},altitude_m:0,airspeed_mps:0,timestamp:0,te_read:0};
      var samples = []; setsize(samples, 30);
      var te_needle =0;

      setprop("/instrumentation/ilec-sc7/te-reading-mps",0);   
      setprop("/instrumentation/ilec-sc7/volume",0.8);  
      setprop("/instrumentation/ilec-sc7/audio",2); 
      setprop("/instrumentation/ilec-sc7/mode",1); 
      setprop("/instrumentation/ilec-sc7/sensitivity",1); 
      setprop("/instrumentation/ilec-sc7/filter",0.05);

      var update_state = func {
         var s = state.new();
         s.altitude_m=getprop("/position/altitude-ft")*FT2M;
        s.airspeed_mps=getprop("/velocities/airspeed-kt")*KT2MPS;
        s.timestamp=systime();
        return s;
    }

      var push30 = func  {
         var i = 0;
           while ( i < 30 ) { 
             samples[i]=0;
             i += 1;
           };
    }

    ##
    # debug info
    var s_dump = func(s) {
       print(s.timestamp," ", s.altitude_m, " ", s.airspeed_mps);
    }

    var averager = func {
          var sum = 0 ;
          var i = 0;
          while ( i < 29 ) { 
             samples[i] = samples[i+1]; # shift everything to the "left"
             i += 1;
          };
          samples[29] = te_needle; # and set last sample to current
          i = 0;
          while ( i < 30 ) { 
             sum = sum + samples[i]; 
             i += 1;
          };
          var average30 = sum / 30;
          setprop("/instrumentation/ilec-sc7/average",math.abs(average30));
          setprop("/instrumentation/ilec-sc7/average-sign",math.sgn(average30));
          if (debug_enabled) print (" average ",average30);
          settimer(averager, 1); # update rate
    }        
      

    var tvario = {   
      new: func {return {parents:[tvario]};},
      state:{previous:,current:},
      init: func {state.previous=state.new(); state.current=state.new();}, 
      update:func {
       if (debug_enabled) print("\nUpdating TEV:");
       state.current = update_state();   
       if (debug_enabled) {
        s_dump(state.current);
        s_dump(state.previous);
       }
       var delta_t = get_delta(state.current.timestamp, state.previous.timestamp);
       # TE reading = (h2-h1)/t + (v2^2 - v1^2) / 19.62*t 
       if (debug_enabled) print("delta_t:",delta_t);
       var uncompensated = get_delta(state.current.altitude_m,state.previous.altitude_m) / delta_t;
       if (debug_enabled) print(" uncompensated:",uncompensated);
       var adjustment = get_delta(square(state.current.airspeed_mps),square(state.previous.airspeed_mps)) / (19.62 * delta_t);
       if (debug_enabled) print("  adjustment:",adjustment,"\n");
       var te_reading = uncompensated + adjustment;
       if (debug_enabled) print ("   te_reading:",te_reading);
       
       te_needle = getprop("/instrumentation/ilec-sc7/te-reading-mps");
       var filter =  0.01 + 0.02 * getprop("/instrumentation/ilec-sc7/sensitivity");
       setprop("/instrumentation/ilec-sc7/filter",filter); 

       te_needle = te_needle * (1-filter) + filter * te_reading;          
       setprop("/instrumentation/ilec-sc7/te-reading-mps",te_needle);  
	setprop("/instrumentation/ilec-sc7/te-reading-neg",-te_needle);  
       state.previous = state.current; # save current state for next call
       settimer(func me.update(), 1/20); # update rate
      }
    };

    var tv = tvario.new();
    tv.init();
    tv.update();
    push30();
    averager();
 
