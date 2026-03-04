extends EditorInspectorPlugin
class_name GLInspectorManager

var landscaper:GLandscaper
var _layers:GLUILayers


func _can_handle(object:Object):
	return object is GLController


# Re select the canvas's tab
func selected(controller:GLController):
	if controller is GLController and controller.is_ready:
		if controller.current_brush:
			_press_tab( controller, controller.current_brush )
		else:
			_press_tab( controller, controller.brushes[0] )


func deselected(controller:GLController):
	clear_layers_panel()


func clear_layers_panel():
	if _layers:
		landscaper.remove_control_from_container( EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, _layers )
		_layers.clear()
		_layers.queue_free()
		_layers = null


func load_layers_panel(layers:Array[GLPaintLayer]):
	_layers = GLAssetsManager.UI_LAYERS.instantiate()
	landscaper.add_control_to_container( EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, _layers )
	_layers.load_layers( layers )


func reload_layers_panel(layers:Array[GLPaintLayer]):
	_layers.clear()
	if _layers:
		_layers.load_layers( layers )


# Creates and connects tabs according to 'GLController.brushes' settings
func _parse_category(controller:Object, category:String):
	if category == "Scan Configs":
		_create_info_box( "Auto detection options for detecting your custom nodes and resources" )
		return
	elif category == "controller.gd":
		_create_info_box( "[b]Source[/b] is the raw save data, try saving backups. [b]Effects[/b] are non-destructive, chunkify at the end", "Build Data and Effects" )
		return
	if not category.ends_with("_controller.gd") or not controller is GLController or not controller.brushes or not controller.is_ready:
		return
	
	if not controller.current_brush:
		_press_tab( controller, controller.brushes[0] )
	
	var tabs:Control = _create_tabs( controller )
	add_custom_control( tabs )
	_create_info_box( controller.current_brush.info )
	
	if not _layers and controller is GLControllerTerrain and controller.current_brush is GLBrushTerrainPaint:
		load_layers_panel( controller.layers )
	if not controller is GLControllerTerrain or not controller.current_brush is GLBrushTerrainPaint:
		clear_layers_panel()
	

 #Hides/Shows each property according to 'GLController.current_brush' settings
func _parse_property(controller:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	if controller is GLController and controller.current_brush and controller.is_ready:
		var current_tab:GLBrush = controller.current_brush
		return name in current_tab.hide_properties if current_tab else false
	return false


func _create_info_box(info:String, title:String=""):
	var info_box:GLInfoBox = GLAssetsManager.INFO_BOX.instantiate()
	info_box.set_info( info )
	if title:
		info_box.set_title( title )
	add_custom_control( info_box )


func _press_tab(controller:GLController, brush:GLBrush):
	controller.select_brush( brush )
	landscaper.scene.select_brush( brush )
	controller.notify_property_list_changed()


func _create_tabs(controller:GLController) -> Control:
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset( Control.PRESET_TOP_WIDE )
	
	for brush in controller.brushes:
		var tab_ui:Button = GLAssetsManager.INSPECTOR_TAB.instantiate()
		tabs.add_child( tab_ui )
		tab_ui.text = brush.title
		tab_ui.icon = brush.icon
		tab_ui.button_pressed = (controller.current_brush == brush)
		tab_ui.pressed.connect( _press_tab.bind(controller, brush) )
	return tabs




	
