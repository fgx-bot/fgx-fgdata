#### Syd Adams --- 3D Flight Manual ####
var poh = nil;
var enabled = nil;
var x = nil;
var y = nil;
var z = nil;
var movement_factor = nil;
var move_page = nil;
var pitch = nil;
var page_num = nil;
var total_pages = nil;
var page_texture = nil;

var mouse_x = nil;
var mouse_y = nil;
var mouse_x_old = 0;
var mouse_y_old = 0;
var mouse_x_new = 0;
var mouse_y_new = 0;

setlistener("/sim/signals/fdm-initialized", func {
    poh = props.globals.getNode("sim/model/manual",1);
    enabled = poh.initNode("enabled",0,"BOOL");
    x = poh.initNode("x-offset",0,"DOUBLE");
    y = poh.initNode("y-offset",0,"DOUBLE");
    z = poh.initNode("z-offset",0,"DOUBLE");
    movement_factor = poh.initNode("m-factor",0.0005,"DOUBLE");
    move_page = poh.initNode("move",0,"BOOL");
    pitch = poh.initNode("pitch",0,"DOUBLE");
    page_num = poh.initNode("page-num",0,"INT");
    total_pages = poh.initNode("total-pages",1,"INT");
    page_texture = poh.initNode("page-texture","page0.png","STRING");
    mouse_x = props.globals.getNode("devices/status/mice/mouse/x");
    mouse_y = props.globals.getNode("devices/status/mice/mouse/y");
    mouse_x_new=mouse_x.getValue() or 0;
    mouse_y_new=mouse_y.getValue() or 0;
    mouse_x_old=mouse_x_new;
    mouse_y_old=mouse_y_new;
    settimer(mouse_update,5);
});


var flip_page = func(dir) {
    if(enabled.getValue()){
        var pg = page_num.getValue();
        var ttl = total_pages.getValue();
        pg +=dir;
        if(pg >= ttl) pg -= 1;
        if(pg< 0 ) pg = 0;
        page_num.setValue(pg);
        var newtex = "page"~pg~".png";
        page_texture.setValue(newtex);
    }
}

var page_adjust = func(mx,my) {
    var scale= movement_factor.getValue(); 
    mx = mx * scale;
    my = my * scale;
    var px = 0;
    var py = 0;
    var pz = 0;
    if(getprop("devices/status/keyboard/shift")){
        px = x.getValue();
        px += my;
        if(px > 0.5)px=0.2;
        if(px < -0.5)px=-0.2;
        x.setValue(px);
    }else{
        py = y.getValue();
        py += mx;
        if(py > 0.2)py=0.2;
        if(py < -0.2)py=-0.2;
        y.setValue(py);
        pz = z.getValue();
        pz += (-1 * my);
        if(pz > 0.2)pz=0.2;
        if(pz < -0.2)pz=-0.2;
        z.setValue(pz);
    }
}


var mouse_update= func {
    mouse_x_new=mouse_x.getValue() or 0;
    mouse_y_new=mouse_y.getValue() or 0;
    var mmx = mouse_x_new - mouse_x_old;
    var mmy = mouse_y_new - mouse_y_old;
    mouse_x_old =mouse_x_new;
    mouse_y_old =mouse_y_new;
    if(move_page.getValue())page_adjust(mmx,mmy);
    settimer(mouse_update, 0.05);
}