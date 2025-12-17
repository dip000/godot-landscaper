extends EditorInspectorPlugin
class_name InspectorManager


func _can_handle(object:Object):
	return object is GLControllerGrass

# Re select the canvas's tab
func selected(controller:GLControllerGrass):
	_press_tab( controller, controller.current_brush_tab )


# Creates and connects tabs according to 'GLController.brush_tabs' settings
func _parse_category(controller:Object, category:String):
	if category != "Brushes":
		return
	
	if not controller.current_brush_tab:
		_press_tab( controller, controller.brush_tabs[0] )
	
	var tabs:Control = _create_tabs( controller )
	add_custom_control( tabs )
	
	var info_box:InfoBox = AssetsManager.INFO_BOX.instantiate()
	info_box.set_info( controller.current_brush_tab.info )
	add_custom_control( info_box )
	

 #Hides/Shows each property according to 'GLController.current_brush_tab' settings
func _parse_property(canvas:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	var current_tab:InspectorTab = canvas.current_brush_tab
	return name in current_tab.hide_properties if current_tab else false


func _press_tab(controller:GLControllerGrass, tab:InspectorTab):
	var configs:Array[InspectorTab] = controller.brush_tabs
	controller.current_brush_tab = tab
	controller.select_brush(tab.brush)
	controller.notify_property_list_changed()
	Landscaper.scene.select_brush( tab.icon )

func _create_tabs(controller:GLControllerGrass) -> Control:
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset( Control.PRESET_TOP_WIDE )
	
	for tab in controller.brush_tabs:
		var tab_ui:Button = AssetsManager.INSPECTOR_TAB.instantiate()
		tabs.add_child( tab_ui )
		tab_ui.text = tab.title
		tab_ui.icon.icon = tab.icon
		tab_ui.button_pressed = (controller.current_brush_tab == tab)
		tab_ui.pressed.connect( _press_tab.bind(controller, tab) )
	return tabs
