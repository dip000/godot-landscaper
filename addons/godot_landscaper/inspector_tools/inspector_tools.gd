extends EditorInspectorPlugin
class_name InspectorTools


func _can_handle(object:Object):
	return object is LandscaperTool


# Creates and connects tabs according to 'LandscaperTool.TABS_CONFIG' settings
func _parse_category(tool:Object, category:String):
	var configs:Dictionary[String, Dictionary] = _get_safe_config( tool )
	if not (category in configs):
		return
	
	if not tool.CURRENT_TAB:
		_press_tab( tool, category, _get_first_tab(category, tool) )
	
	var tabs:Control = _create_tabs( tool )
	add_custom_control( tabs )
	
	var info_box:InfoBox = AssetsManager.INFO_BOX.instantiate()
	var info:String = _get_safe_property( configs, category, tool.CURRENT_TAB, "info" )
	info_box.set_info( info )
	add_custom_control( info_box )


# Hides/Shows each property according to 'LandscaperTool.TABS_CONFIG' settings
func _parse_property(tool:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	var configs:Dictionary[String, Dictionary] = _get_safe_config( tool )
	for category in configs:
		var hide_properties:Array = _get_safe_property( configs, category, tool.CURRENT_TAB, "hide_properties", [] )
		return name in hide_properties


func _press_tab(tool:LandscaperTool, category:String, tab:String):
	GLDebug.internal("Pressed %s/%s/%s" %[tool.name, category, tab])
	var configs:Dictionary[String, Dictionary] = _get_safe_config( tool )
	var method:Callable = _get_safe_property( configs, category, tab, "method", Callable() )
	if method:
		tool.CURRENT_TAB = tab
		method.call()
		tool.notify_property_list_changed()


func _create_tabs(tool:LandscaperTool) -> Control:
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset( Control.PRESET_TOP_WIDE )
	
	var configs:Dictionary[String, Dictionary] = _get_safe_config( tool )
	for category in configs:
		for tab_name in configs[category]:
			var tab:Button = AssetsManager.INSPECTOR_TAB.instantiate()
			tabs.add_child( tab )
			tab.text = tab_name
			tab.icon.icon = _get_safe_property( configs, category, tab_name, "icon", 0 )
			tab.button_pressed = (tool.CURRENT_TAB == tab_name)
			tab.pressed.connect( _press_tab.bind(tool, category, tab_name) )
	return tabs


# In case i change the varaible again..
func _get_safe_config(tool:LandscaperTool) -> Dictionary[String, Dictionary]:
	if "TABS_CONFIG" in tool:
		return tool.TABS_CONFIG
	var default:Dictionary[String, Dictionary]
	return default

func _get_first_tab(category:String, tool:LandscaperTool) -> String:
	return tool.TABS_CONFIG[category].keys()[0]

func _get_safe_property(configs:Dictionary[String,Dictionary], category:String, tab:String, property:String, default:Variant=null) -> Variant:
	if not (category in configs): return default
	var categories:Dictionary = configs[category]
	
	if not (tab in categories): return default
	var tabs:Dictionary = categories[tab]
	
	if not (property in tabs): return default
	return tabs[property]
