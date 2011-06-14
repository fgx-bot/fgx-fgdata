var Radio = gui.Dialog.new("/sim/gui/dialogs/radios/dialog",
        "Aircraft/b1900d/Systems/tranceivers.xml");
var ap_settings = gui.Dialog.new("/sim/gui/dialogs/collins-autopilot/dialog",
        "Aircraft/b1900d/Systems/autopilot-dlg.xml");

gui.menuBind("radio", "dialogs.Radio.open()");
gui.menuBind("autopilot-settings", "dialogs.ap_settings.open()");
