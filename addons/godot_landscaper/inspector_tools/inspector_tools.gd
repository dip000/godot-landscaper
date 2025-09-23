extends EditorInspectorPlugin
class_name InspectorTools


func _can_handle(object:Object):
	return object is SceneElement

# Re select the canvas's tab
func selected(element:SceneElement):
	_press_tab( element, element.CURRENT_TAB )


# Creates and connects tabs according to 'Grass3D.TABS_CONFIG' settings
func _parse_category(element:Object, category:String):
	if category == "Add Instances":
		var info_box:InfoBox = AssetsManager.INFO_BOX.instantiate()
		info_box.set_info( "Select individual Scene Tree instances for more configurations" )
		add_custom_control( info_box )
	
	if category != "Brushes":
		return
	if not element.CURRENT_TAB:
		_press_tab( element, element.TABS_CONFIG[0] )
	
	var tabs:Control = _create_tabs( element )
	add_custom_control( tabs )
	
	var info_box:InfoBox = AssetsManager.INFO_BOX.instantiate()
	info_box.set_info( element.CURRENT_TAB.info )
	add_custom_control( info_box )
	

# Hides/Shows each property according to 'LandscaperTool.CURRENT_TAB' settings
func _parse_property(canvas:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	var current_tab:InspectorTab = canvas.CURRENT_TAB
	return name in current_tab.hide_properties if current_tab else false


func _press_tab(element:SceneElement, tab:InspectorTab):
	var configs:Array[InspectorTab] = element.TABS_CONFIG
	element.CURRENT_TAB = tab
	element.select_brush(tab.brush_name)
	Landscaper.scene.select_brush( tab.icon )

func _create_tabs(element:SceneElement) -> Control:
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset( Control.PRESET_TOP_WIDE )
	
	for tab in element.TABS_CONFIG:
		var tab_ui:Button = AssetsManager.INSPECTOR_TAB.instantiate()
		tabs.add_child( tab_ui )
		tab_ui.text = tab.name
		tab_ui.icon.icon = tab.icon
		tab_ui.button_pressed = (element.CURRENT_TAB == tab)
		tab_ui.pressed.connect( _press_tab.bind(element, tab) )
	return tabs
