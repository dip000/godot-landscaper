extends EditorInspectorPlugin
class_name InspectorLandscaper

# Calling notify_property_list_changed() will erase tab data
# That's why we store the tab name instead of the instance
var _tab_pressed:String


func selected(instancer:BaseInstancer):
	var tabs_config:Dictionary[String,Dictionary] = instancer.TABS_CONFIG
	var method:Callable = tabs_config[_tab_pressed].method
	method.call()


func _can_handle(object):
	return object is BaseInstancer


func _parse_category(base_instancer:Object, category:String):
	base_instancer = base_instancer as BakedQuadGrass
	var tabs_config:Dictionary[String,Dictionary] = base_instancer.TABS_CONFIG
	
	if not _tab_pressed and tabs_config:
		_tab_pressed = tabs_config.keys()[0]
	
	if tabs_config and category == "Actions":
		var tabs:Control = _create_tabs( tabs_config )
		add_custom_control( tabs )
		
		var info:Control = AssetsManager.ui.info_box.instantiate()
		info.get_node("PanelContainer/HBoxContainer/Info").text = tabs_config[_tab_pressed].info
		add_custom_control( info )


func _parse_property(base_instancer:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	base_instancer = base_instancer as BakedQuadGrass
	var tabs_config:Dictionary[String,Dictionary] = base_instancer.TABS_CONFIG
	var selected_tab_config:Dictionary = tabs_config[_tab_pressed]
	return name in selected_tab_config.hide_properties


func _create_tabs(tabs_config:Dictionary[String,Dictionary]) -> Control:
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset(Control.PRESET_TOP_WIDE)
	
	for tab_name in tabs_config:
		var tab:Button = AssetsManager.ui.inspector_tab.instantiate()
		tabs.add_child( tab )
		tab.text = tab_name
		tab.icon.icon = tabs_config[tab_name].icon
		tab.button_pressed = (_tab_pressed == tab_name)
		
		var method:Callable = tabs_config[tab_name].method
		tab.pressed.connect( _update_button.bind(method, tab_name) )
	return tabs


func _update_button(method:Callable, tab_name:String):
	_tab_pressed = tab_name
	method.get_object().notify_property_list_changed()
	method.call()
