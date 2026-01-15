extends EditorInspectorPlugin
class_name GLInspectorManager


func _can_handle(object:Object):
	return object is GLControllerGrass

# Re select the canvas's tab
func selected(controller:GLControllerGrass):
	_press_tab( controller, controller.current_brush )


# Creates and connects tabs according to 'GLController.brushes' settings
func _parse_category(controller:Object, category:String):
	if category != "Brushes" or not controller.brushes:
		return
	
	if not controller.current_brush:
		_press_tab( controller, controller.brushes[0] )
	
	var tabs:Control = _create_tabs( controller )
	add_custom_control( tabs )
	
	var info_box:InfoBox = AssetsManager.INFO_BOX.instantiate()
	info_box.set_info( controller.current_brush.info )
	add_custom_control( info_box )
	

 #Hides/Shows each property according to 'GLController.current_brush' settings
func _parse_property(controller:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	var current_tab:GLBrush = controller.current_brush
	return name in current_tab.hide_properties if current_tab else false


func _press_tab(controller:GLControllerGrass, brush:GLBrush):
	controller.select_brush( brush )
	controller.notify_property_list_changed()
	Landscaper.scene.select_brush( brush.icon )

func _create_tabs(controller:GLControllerGrass) -> Control:
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset( Control.PRESET_TOP_WIDE )
	
	for brush in controller.brushes:
		var tab_ui:Button = AssetsManager.INSPECTOR_TAB.instantiate()
		tabs.add_child( tab_ui )
		tab_ui.text = brush.title
		tab_ui.icon.icon = brush.icon
		tab_ui.button_pressed = (controller.current_brush == brush)
		tab_ui.pressed.connect( _press_tab.bind(controller, brush) )
	return tabs
