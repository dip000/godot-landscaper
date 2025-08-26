extends EditorInspectorPlugin
class_name InspectorTools


func _can_handle(object:Object):
	return object is LandscaperTool


# Creates and connects tabs according to 'LandscaperTool.TABS_CONFIG' settings
func _parse_category(tool:Object, category:String):
	if category != "Actions":
		return
	
	if not tool.CURRENT_TAB:
		_press_tab( tool, tool.TABS_CONFIG[0] )
	
	var tabs:Control = _create_tabs( tool )
	add_custom_control( tabs )
	
	var info_box:InfoBox = AssetsManager.INFO_BOX.instantiate()
	info_box.set_info( tool.CURRENT_TAB.info )
	add_custom_control( info_box )


# Hides/Shows each property according to 'LandscaperTool.CURRENT_TAB' settings
func _parse_property(tool:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	var current_tab:InspectorTab = tool.CURRENT_TAB
	return name in current_tab.hide_properties


func _press_tab(tool:LandscaperTool, tab:InspectorTab):
	GLDebug.internal("Pressed %s/Actions/%s" %[tool.name, tab.name])
	var configs:Array[InspectorTab] = tool.TABS_CONFIG
	var method:Callable = Callable(tool, tab.method)
	if method.is_valid():
		tool.CURRENT_TAB = tab
		method.call()
		tool.notify_property_list_changed()
		Landscaper.scene.select_action( tool, tab )


func _create_tabs(tool:LandscaperTool) -> Control:
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset( Control.PRESET_TOP_WIDE )
	
	for tab in tool.TABS_CONFIG:
		var tab_ui:Button = AssetsManager.INSPECTOR_TAB.instantiate()
		tabs.add_child( tab_ui )
		tab_ui.text = tab.name
		tab_ui.icon.icon = tab.icon
		tab_ui.button_pressed = (tool.CURRENT_TAB == tab)
		tab_ui.pressed.connect( _press_tab.bind(tool, tab) )
	return tabs
