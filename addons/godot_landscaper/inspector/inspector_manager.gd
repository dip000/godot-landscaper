extends EditorInspectorPlugin
class_name GLInspectorManager


func _can_handle(object:Object):
	return object is GLController


# Re select the canvas's tab
func selected(controller:GLController):
	if controller is GLController and controller.is_ready:
		if controller.current_brush:
			_press_tab( controller, controller.current_brush )
		else:
			_press_tab( controller, controller.brushes[0] )


# Creates and connects tabs according to 'GLController.brushes' settings
func _parse_category(controller:Object, category:String):
	if category == "Scan Configs":
		_create_info_box( "Auto detect your own setups like mesh-over-body or body-over-mesh" )
		return
	elif category == "controller.gd":
		_create_info_box( "Effects are non-destructive. To save effects permanently: Apply, move 'processed' to 'source' and Clear." )
		return
	if category != "Brushes" or not controller is GLController or not controller.brushes or not controller.is_ready:
		return
	
	if not controller.current_brush:
		_press_tab( controller, controller.brushes[0] )
	
	var tabs:Control = _create_tabs( controller )
	add_custom_control( tabs )
	_create_info_box( controller.current_brush.info )
	

 #Hides/Shows each property according to 'GLController.current_brush' settings
func _parse_property(controller:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	if controller is GLController and controller.current_brush and controller.is_ready:
		var current_tab:GLBrush = controller.current_brush
		return name in current_tab.hide_properties if current_tab else false
	return false

func _create_info_box(info:String):
	var info_box:InfoBox = AssetsManager.INFO_BOX.instantiate()
	info_box.set_info( info )
	add_custom_control( info_box )


func _press_tab(controller:GLController, brush:GLBrush):
	controller.select_brush( brush )
	controller.notify_property_list_changed()
	Landscaper.scene.select_brush( brush )

func _create_tabs(controller:GLController) -> Control:
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset( Control.PRESET_TOP_WIDE )
	
	for brush in controller.brushes:
		var tab_ui:Button = AssetsManager.INSPECTOR_TAB.instantiate()
		tabs.add_child( tab_ui )
		tab_ui.text = brush.title
		tab_ui.icon = brush.icon
		tab_ui.button_pressed = (controller.current_brush == brush)
		tab_ui.pressed.connect( _press_tab.bind(controller, brush) )
	return tabs
