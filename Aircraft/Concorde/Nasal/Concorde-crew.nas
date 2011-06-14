# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron
# HUMAN : functions ending by human are called by artificial intelligence



# This file contains checklist tasks.


# ============
# VIRTUAL CREW
# ============

Virtualcrew = {};

Virtualcrew.new = func {
   var obj = { parents : [Virtualcrew,System], 

               generic : Generic.new(),

               GROUNDSEC : 15.0,                               # to reach the ground
               CREWSEC : 10.0,                                 # to complete the task
               TASKSEC : 2.0,                                  # between 2 tasks
               DELAYSEC : 1.0,                                 # random delay

               task : constant.FALSE,
               taskend : constant.TRUE,
               taskground : constant.FALSE,
               taskcrew : constant.FALSE,
  
               activ : constant.FALSE,
               running : constant.FALSE,

               state : ""
         };

    return obj;
}

Virtualcrew.inherit_virtualcrew = func( path ) {
    me.inherit_system( path );

    var obj = Virtualcrew.new();

    me.generic = obj.generic;

    me.GROUNDSEC = obj.GROUNDSEC;
    me.CREWSEC = obj.CREWSEC;
    me.TASKSEC = obj.TASKSEC;
    me.DELAYSEC = obj.DELAYSEC;

    me.task = obj.task;
    me.taskend = obj.taskend;
    me.taskground = obj.taskground;
    me.taskcrew = obj.taskcrew;

    me.activ = obj.activ;
    me.running = obj.running;
    me.state = obj.state;
}

Virtualcrew.toggleclick = func( message = "" ) {
    me.done( message );

    me.generic.toggleclick();
}

Virtualcrew.done = func( message = "" ) {
    if( message != "" ) {
        me.log( message );
    }

    # first task to do.
    me.task = constant.TRUE;

    # still something to do, must wait.
    me.reset_end();
}

Virtualcrew.done_ground = func( message = "" ) {
    # procedure to execute with delay
    me.taskground = constant.TRUE;

    me.done( message );
}

Virtualcrew.done_crew = func( message = "" ) {
    # procedure to execute with delay
    me.taskcrew = constant.TRUE;

    me.done( message );
}

Virtualcrew.log = func( message ) {
    me.state = me.state ~ " " ~ message;
}

Virtualcrew.getlog = func {
    return me.state;
}

Virtualcrew.reset = func {
    me.state = "";
    me.activ = constant.FALSE;
    me.running = constant.FALSE;

    me.task = constant.FALSE;
    me.taskend = constant.TRUE;
}

Virtualcrew.set_activ = func {
    me.activ = constant.TRUE;
}

Virtualcrew.is_activ = func {
    return me.activ;
}

Virtualcrew.set_running = func {
    me.running = constant.TRUE;
}

Virtualcrew.is_running = func {
    return me.running;
}

Virtualcrew.wait_ground = func {
    return me.taskground;
}

Virtualcrew.reset_ground = func {
    me.taskground = constant.FALSE;
}

Virtualcrew.wait_crew = func {
    return me.taskcrew;
}

Virtualcrew.reset_crew = func {
    me.taskcrew = constant.FALSE;
}

Virtualcrew.reset_end = func {
    me.taskend = constant.FALSE;
}

Virtualcrew.can = func {
    return !me.task;
}

Virtualcrew.randoms = func( steps ) {
    # doesn't overwrite, if no task to do
    if( !me.taskend ) {
        var margins  = rand() * me.DELAYSEC;

        if( me.taskground ) {
            steps = me.GROUNDSEC;
        }

        elsif( me.taskcrew ) {
            steps = me.CREWSEC;
        }

        else {
            steps = me.TASKSEC;
        }

        steps = steps + margins;
    }

    return steps;
} 

Virtualcrew.timestamp = func {
    var action = me.itself["root"].getChild("state").getValue();

    # save last real action
    if( action != "" ) {
        me.itself["root"].getChild("state-last").setValue(action);
    }

    me.itself["root"].getChild("state").setValue(me.getlog());
    me.itself["root"].getChild("time").setValue(getprop("/sim/time/gmt-string"));
}

# other crew member tells, that he has completed
Virtualcrew.completed = func {
    if( me.can() ) {
        me.set_completed();
    }
}

Virtualcrew.has_completed = func {
    var result = constant.FALSE;

    if( me.can() ) {
        result = me.is_completed();
    }

    return result;
}


# =======
# CALLOUT
# =======

Callout = {};

Callout.new = func {
   var obj = { parents : [Callout], 

               callout : "holding"                   # otherwise startup is a long time without callout
             };

   return obj;
}

Callout.inherit_callout = func {
    var obj = Callout.new();

    me.callout = obj.callout;
}

Callout.is_flight = func {
    var result = constant.FALSE;

    if( me.callout == "flight" ) {
        result = constant.TRUE;
    }

    return result;
}

Callout.is_landing = func {
    var result = constant.FALSE;

    if( me.callout == "landing" ) {
        result = constant.TRUE;
    }

    return result;
}

Callout.is_goaround = func {
    var result = constant.FALSE;

    if( me.callout == "goaround" ) {
        result = constant.TRUE;
    }

    return result;
}

Callout.is_taxiway = func {
    var result = constant.FALSE;

    if( me.callout == "taxiway" ) {
        result = constant.TRUE;
    }

    return result;
}

Callout.is_terminal = func {
    var result = constant.FALSE;

    if( me.callout == "terminal" ) {
        result = constant.TRUE;
    }

    return result;
}

Callout.is_gate = func {
    var result = constant.FALSE;

    if( me.callout == "gate" ) {
        result = constant.TRUE;
    }

    return result;
}

Callout.is_holding = func {
    var result = constant.FALSE;

    if( me.callout == "holding" ) {
        result = constant.TRUE;
    }

    return result;
}

Callout.is_takeoff = func {
    var result = constant.FALSE;

    if( me.callout == "takeoff" ) {
        result = constant.TRUE;
    }

    return result;
}


# =========
# CHECKLIST
# =========

Checklist = {};

Checklist.new = func {
   var obj = { parents : [Checklist,System], 

               checklist : ""
             };

   return obj;
}

Checklist.inherit_checklist = func( path ) {
    var obj = Checklist.new();

    me.checklist = obj.checklist;

    me.inherit_system( path );
}

Checklist.set_checklist = func {
    me.checklist = me.dependency["voice"].getChild("checklist").getValue();
}

Checklist.is_nochecklist = func {
    var result = constant.FALSE;

    if( me.checklist == "" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_aftertakeoff = func {
    var result = constant.FALSE;

    if( me.checklist == "aftertakeoff" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_climb = func {
    var result = constant.FALSE;

    if( me.checklist == "climb" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_transsonic = func {
    var result = constant.FALSE;

    if( me.checklist == "transsonic" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_cruiseclimb = func {
    var result = constant.FALSE;

    if( me.checklist == "cruiseclimb" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_descent = func {
    var result = constant.FALSE;

    if( me.checklist == "descent" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_approach = func {
    var result = constant.FALSE;

    if( me.checklist == "approach" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_beforelanding = func {
    var result = constant.FALSE;

    if( me.checklist == "beforelanding" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_afterlanding = func {
    var result = constant.FALSE;

    if( me.checklist == "afterlanding" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_parking = func {
    var result = constant.FALSE;

    if( me.checklist == "parking" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_stopover = func {
    var result = constant.FALSE;

    if( me.checklist == "stopover" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_external = func {
    var result = constant.FALSE;

    if( me.checklist == "external" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_preliminary = func {
    var result = constant.FALSE;

    if( me.checklist == "preliminary" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_cockpit = func {
    var result = constant.FALSE;

    if( me.checklist == "cockpit" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_beforestart = func {
    var result = constant.FALSE;

    if( me.checklist == "beforestart" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_enginestart = func {
    var result = constant.FALSE;

    if( me.checklist == "enginestart" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_pushback = func {
    var result = constant.FALSE;

    if( me.checklist == "pushback" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_started = func {
    var result = constant.FALSE;

    if( me.checklist == "started" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_afterstart = func {
    var result = constant.FALSE;

    if( me.checklist == "afterstart" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_taxi = func {
    var result = constant.FALSE;

    if( me.checklist == "taxi" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_runway = func {
    var result = constant.FALSE;

    if( me.checklist == "runway" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_beforetakeoff = func {
    var result = constant.FALSE;

    if( me.checklist == "beforetakeoff" ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.set_startup = func {
    me.dependency["crew"].getChild("startup").setValue( constant.TRUE );
}

Checklist.not_startup = func {
    me.dependency["crew"].getChild("startup").setValue( constant.FALSE );
}

Checklist.set_completed = func {
    me.dependency["crew"].getChild("completed").setValue( constant.TRUE );
}

Checklist.not_completed = func {
    me.dependency["crew"].getChild("completed").setValue( constant.FALSE );

    # reset keyboard detection
    me.dependency["crew-ctrl"].getChild("recall").setValue( constant.FALSE );
}

Checklist.is_completed = func {
    var result = constant.FALSE;

    if( me.dependency["crew"].getChild("completed").getValue() ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_busy = func {
    var result = constant.FALSE;

    if( me.dependency["crew-ctrl"].getChild("captain-busy").getValue() ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_recall = func {
    var result = constant.FALSE;

    if( me.dependency["crew-ctrl"].getChild("recall").getValue() ) {
        result = constant.TRUE;
    }

    return result;
}

Checklist.is_startup = func {
    var result = constant.FALSE;

    if( me.dependency["crew"].getChild("startup").getValue() ) {
        result = constant.TRUE;
    }

    return result;
}


# =========
# EMERGENCY
# =========

Emergency = {};

Emergency.new = func {
   var obj = { parents : [Emergency,System], 

               emergency : ""
             };

   return obj;
}

Emergency.inherit_emergency = func( path ) {
    var obj = Emergency.new();

    me.emergency = obj.emergency;

    me.inherit_system( path );
}

Emergency.set_emergency = func {
    me.emergency = me.dependency["voice"].getChild("emergency").getValue();
}

Emergency.is_emergency = func {
    var result = constant.FALSE;

    if( me.emergency != "" ) {
        result = constant.TRUE;
    }

    return result;
}

Emergency.is_fourengineflameout = func {
    var result = constant.FALSE;

    if( me.emergency == "fourengineflameout" ) {
        result = constant.TRUE;
    }

    return result;
}

Emergency.is_fourengineflameoutmach1 = func {
    var result = constant.FALSE;

    if( me.emergency == "fourengineflameoutmach1" ) {
        result = constant.TRUE;
    }

    return result;
}


# =============
# COMMON CHECKS
# =============

CommonCheck = {};

CommonCheck.new = func {
    var obj = { parents : [CommonCheck,System] 
              };

    return obj;
}

CommonCheck.inherit_commoncheck = func( path ) {
    me.inherit_system( path );
}

# ----------
# NAVIGATION
# ----------
CommonCheck.ins = func( index, mode ) {
    if( me.can() ) {
        if( me.dependency["ins"][index].getNode("msu").getChild("mode").getValue() != mode ) {
            me.dependency["ins"][index].getNode("msu").getChild("mode").setValue(mode);
            me.toggleclick("ins-" ~ index);
        }
    }
}


# ===================
# ASYNCHRONOUS CHECKS
# ===================

AsynchronousCheck = {};

AsynchronousCheck.new = func {
   var obj = { parents : [AsynchronousCheck],

               completed : constant.TRUE
             };

   return obj;
}

AsynchronousCheck.inherit_asynchronouscheck = func( path ) {
   me.inherit_system( path );

   var obj = AsynchronousCheck.new();

   me.completed = obj.completed;
}

AsynchronousCheck.is_change = func {
   var change = constant.FALSE;

   return change;
}

# once night lighting, virtual crew must switch again lights.
AsynchronousCheck.set_task = func {
   me.completed = constant.FALSE;
}

AsynchronousCheck.has_task = func {
   var result = constant.FALSE;

   if( me.is_change() or !me.completed ) {
       result = constant.TRUE;
   }
   else {
       result = constant.FALSE;
   }

   return result;
}

AsynchronousCheck.set_completed = func {
   me.completed = constant.TRUE;
}


# ==============
# NIGHT LIGHTING
# ==============

Nightlighting = {};

Nightlighting.new = func {
   var obj = { parents : [Nightlighting,AsynchronousCheck,System],

               lightingsystem : nil,

               COMPASSDIM : 0.5,
               DAYNORM : 0.0,
   
               lightlevel : 0.0,
               lightcompass : 0.0,
               lightlow : constant.FALSE,

               night : constant.FALSE
         };

  obj.init();

  return obj;
}

Nightlighting.init = func {
    me.inherit_asynchronouscheck("/systems/human");
}

Nightlighting.set_relation = func( lighting ) {
    me.lightingsystem = lighting;
}

Nightlighting.copilot = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("night-lighting").getValue() ) {

       # only once, can be customized by user
       if( me.has_task() ) {
           me.light( "copilot" );

           me.set_task();

           # flood lights
           if( task.can() ) {
               if( me.dependency["lighting-copilot"].getChild("flood-norm").getValue() != me.lightlevel ) {
                   me.dependency["lighting-copilot"].getChild("flood-norm").setValue( me.lightlevel );
                   me.lightingsystem.floodexport();
                   task.toggleclick("flood-light");
               }
           }

           # level of warning lights
           if( task.can() ) {
               if( me.dependency["lighting-copilot"].getChild("low").getValue() != me.lightlow ) {
                   me.dependency["lighting-copilot"].getChild("low").setValue( me.lightlow );
                   task.toggleclick("panel-light");
               }
           }
           if( task.can() ) {
               if( me.dependency["lighting"].getNode("center").getChild("low").getValue() != me.lightlow ) {
                   me.dependency["lighting"].getNode("center").getChild("low").setValue( me.lightlow );
                   task.toggleclick("center-light");
               }
           }
           if( task.can() ) {
               if( me.dependency["lighting"].getNode("afcs").getChild("low").getValue() != me.lightlow ) {
                   me.dependency["lighting"].getNode("afcs").getChild("low").setValue( me.lightlow );
                   task.toggleclick("afcs-light");
               }
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

Nightlighting.captain = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("night-lighting").getValue() ) {

       # only once, can be customized by user
       if( me.has_task() ) {
           me.light( "captain" );

           me.set_task();

           # flood lights
           if( task.can() ) {
               if( me.dependency["lighting-captain"].getChild("flood-norm").getValue() != me.lightlevel ) {
                   me.dependency["lighting-captain"].getChild("flood-norm").setValue( me.lightlevel );
                   me.lightingsystem.floodexport();
                   task.toggleclick("flood-light");
               }
           }

           # level of warning lights
           if( task.can() ) {
               if( me.dependency["lighting-captain"].getChild("low").getValue() != me.lightlow ) {
                   me.dependency["lighting-captain"].getChild("low").setValue( me.lightlow );
                   task.toggleclick("panel-light");
               }
           }

           # compass light
           if( task.can() ) {
               if( me.dependency["lighting"].getNode("overhead").getChild("compass-norm").getValue() != me.lightcompass ) {
                   me.dependency["lighting"].getNode("overhead").getChild("compass-norm").setValue( me.lightcompass );
                   me.lightingsystem.compassexport( me.lightcompass );
                   task.toggleclick("compass-light");
               }
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

Nightlighting.engineer = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("night-lighting").getValue() ) {

       # only once, can be customized by user
       if( me.has_task() ) {
           me.light( "engineer" );

           me.set_task();

           # flood lights
           if( task.can() ) {
               if( me.dependency["lighting-engineer"].getChild("flood-norm").getValue() != me.lightlevel ) {
                   me.dependency["lighting-engineer"].getChild("flood-norm").setValue( me.lightlevel );
                   me.lightingsystem.floodexport();
                   task.toggleclick("flood-light");
               }
           }

           # level of warning lights
           if( task.can() ) {
               if( me.dependency["lighting-engineer"].getNode("forward").getChild("low").getValue() != me.lightlow ) {
                   me.dependency["lighting-engineer"].getNode("forward").getChild("low").setValue( me.lightlow );
                   task.toggleclick("forward-light");
               }
           }
           if( task.can() ) {
               if( me.dependency["lighting-engineer"].getNode("center").getChild("low").getValue() != me.lightlow ) {
                   me.dependency["lighting-engineer"].getNode("center").getChild("low").setValue( me.lightlow );
                   task.toggleclick("center-light");
               }
           }
           if( task.can() ) {
               if( me.dependency["lighting-engineer"].getNode("aft").getChild("low").getValue() != me.lightlow ) {
                   me.dependency["lighting-engineer"].getNode("aft").getChild("low").setValue( me.lightlow );
                   task.toggleclick("aft-light");
               }
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

Nightlighting.light = func( path ) {
   if( me.night ) {
       me.lightlevel = me.itself["lighting"].getChild(path).getValue();
       me.lightlow = constant.TRUE;
       me.lightcompass = me.COMPASSDIM;
   }
   else {
       me.lightlevel = me.DAYNORM;
       me.lightlow = constant.FALSE;
       me.lightcompass = me.DAYNORM;
   }
}

Nightlighting.is_change = func {
   var change = constant.FALSE;

   if( me.is_night() ) {
       if( !me.night ) {
           me.night = constant.TRUE;
           change = constant.TRUE;
       }
   }
   else {
       if( me.night ) {
           me.night = constant.FALSE;
           change = constant.TRUE;
       }
   }

   return change;
}

Nightlighting.is_night = func {
   var result = constant.FALSE;

   if( me.noinstrument["sun"].getValue() > constant.NIGHTRAD ) {
       result = constant.TRUE;
   }

   return result;
}


# ================
# RADIO MANAGEMENT
# ================

RadioManagement = {};

RadioManagement.new = func {
   var obj = { parents : [RadioManagement,AsynchronousCheck,System],

               autopilotsystem : nil,

               DESCENTFPM : -100,

               tower : "",
               landing : constant.FALSE,

               NOENTRY : -1,
               entry : -1
         };

   obj.init();

   return obj;
};

RadioManagement.init = func {
   me.inherit_asynchronouscheck("/systems/human");
}

RadioManagement.set_relation = func( autopilot ) {
    me.autopilotsystem = autopilot;
}

RadioManagement.copilot = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("radio").getValue() ) {
       if( me.has_task() ) {
           me.set_task();

           # VOR 1
           if( task.can() ) {
               me.set_vor( 1, task );
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

RadioManagement.captain = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("radio").getValue() ) {
       if( me.has_task() ) {
           me.set_task();

           # VOR 0
           if( task.can() ) {
               me.set_vor( 0, task );
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

RadioManagement.engineer = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("radio").getValue() ) {
       if( me.has_task() ) {
           me.set_task();

           # ADF 1
           if( task.can() ) {
               me.set_adf( 0, task );
           }

           # ADF 2
           if( task.can() ) {
               me.set_adf( 1, task );
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

RadioManagement.set_vor = func( index, task ) {
    var phase = me.get_phase();

    if( phase != nil ) {
        var vor = phase.getChildren("vor");

        # NAV 0 is reserved
        var radio = index + 1;

        if( index < size( vor ) ) {
            var change = constant.FALSE;
            var currentmhz = 0.0;
            var frequencymhz = 0.0;
            var frequency = nil;

            # not real : no NAV standby frequency
            frequency = vor[ index ].getChild("standby-mhz");
            if( frequency != nil ) {
                frequencymhz = frequency.getValue();
                currentmhz = me.dependency["vor"][radio].getNode("frequencies/standby-mhz").getValue();

                if( currentmhz != frequencymhz ) {
                    me.dependency["vor"][radio].getNode("frequencies/standby-mhz").setValue(frequencymhz);
                    change = constant.TRUE;
                }
            }

            frequency = vor[ index ].getChild("selected-mhz");
            if( frequency != nil ) {
                frequencymhz = frequency.getValue();
                currentmhz = me.dependency["vor"][radio].getNode("frequencies/selected-mhz").getValue();

                if( currentmhz != frequencymhz ) {
                    me.dependency["vor"][radio].getNode("frequencies/selected-mhz").setValue(frequencymhz);
                    change = constant.TRUE;
                    task.toggleclick("vor " ~ index);
                }
            }

            if( change ) {
                me.autopilotsystem.apsendnavexport();
            }
        }
    }
}

RadioManagement.set_adf = func( index, task ) {
    var phase = me.get_phase();

    if( phase != nil ) {
        var adf = phase.getChildren("adf");

        if( index < size( adf ) ) {
            var frequency = nil;
            var frequencykhz = 0;
            var currentkhz = 0;

            # not real : no ADF standby frequency
            frequency = adf[ index ].getChild("standby-khz");
            if( frequency != nil ) {
                frequencykhz = frequency.getValue();
                currentkhz = me.dependency["adf"][index].getNode("frequencies/standby-khz").getValue();

                if( currentkhz != frequencykhz ) {
                    me.dependency["adf"][index].getNode("frequencies/standby-khz").setValue(frequencykhz);
                }
            }

            frequency = adf[ index ].getChild("selected-khz");
            if( frequency != nil ) {
                frequencykhz = frequency.getValue();
                currentkhz = me.dependency["adf"][index].getNode("frequencies/selected-khz").getValue();

                if( currentkhz != frequencykhz ) {
                    me.dependency["adf"][index].getNode("frequencies/selected-khz").setValue(frequencykhz);
                    task.toggleclick("adf " ~ index);
                }
            }
        }
    }
}

RadioManagement.get_phase = func {
    var phase = nil;

    if( me.entry > me.NOENTRY ) {
        if( me.landing ) {
            phase = me.itself["airport"][ me.entry ].getNode("arrival");
        }

        else {
            phase = me.itself["airport"][ me.entry ].getNode("departure");
        }
    }

    return phase;
}

# tower changed by dialog (destination or airport location)
RadioManagement.is_change = func {
   var result = constant.FALSE;

   var target = me.noinstrument["tower"].getValue();

   if( me.tower != target ) {
       var airport = "";

       for(var i=0; i<size(me.itself["airport"]); i=i+1) {
           airport = me.itself["airport"][ i ].getChild("airport-id").getValue();
           if( airport == target ) {
               me.entry = i;

               result = constant.TRUE;
               break;
           }
       }
   }

   if( !result ) {
       var phase = me.is_landing();

       if( me.landing != phase ) {
           var speedkt = me.noinstrument["airspeed"].getValue();

           # do not change frequencies, just after landing 
           if( me.landing and speedkt > constantaero.TAXIKT ) {
           }

           else {
               me.landing = phase;

               result = constant.TRUE;
           }
       }
   }

   return result;
}

RadioManagement.is_landing = func {
   var result = constant.FALSE;
   var rateftpm = me.dependency["ivsi"].getChild("indicated-speed-fps").getValue() * constant.MINUTETOSECOND;

   if( rateftpm < me.DESCENTFPM ) {
       result = constant.TRUE;
   }

   return result;
}

RadioManagement.set_completed = func {
   me.tower = me.noinstrument["tower"].getValue();

   me.completed = constant.TRUE;
}
