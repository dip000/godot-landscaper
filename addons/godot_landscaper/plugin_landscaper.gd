@tool
extends EditorPlugin
class_name Landscaper

static var scene:SceneManager
static var assets:AssetsManager
static var inspector:InspectorTools
static var undo_redo:EditorUndoRedoManager
static var is_enabled:bool

static var element:SceneElement


static func running() -> bool:
	return Engine.is_editor_hint() and is_enabled


func _enter_tree():
	assets = preload("res://addons/godot_landscaper/assets_manager/assets_manager.tscn").instantiate()
	scene = preload("res://addons/godot_landscaper/scene_manager/scene_manager.tscn").instantiate()
	inspector = InspectorTools.new()
	add_inspector_plugin( inspector )
	undo_redo = get_undo_redo()
	
	await get_tree().process_frame
	var viewport:SubViewport = EditorInterface.get_editor_viewport_3d()
	viewport.add_child( assets )
	viewport.add_child( scene )
	is_enabled = true
	

func _exit_tree():
	is_enabled = false
	remove_inspector_plugin( inspector )
	assets.queue_free()
	scene.queue_free()
	undo_redo.clear_history()
	

# Raycasts terrain colliders to track mouse pointer and sends input to an active 'SceneLandscaper' node
func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	if not element or not element.is_ready:
		return
	
	# Accepted inputs
	var is_motion:bool = (event is InputEventMouseMotion)
	var is_button:bool = (event is InputEventMouseButton)
	
	if not (is_motion or is_button):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	# Raycast
	var hit_info:Dictionary = scene.raycaster.update_hit_info( cam, event.get_position() )
	if not hit_info:
		scene.not_over_surface()
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	scene.over_surface( hit_info.position )
	
	# Paint
	var mbl:bool = is_button and event.button_index == MOUSE_BUTTON_LEFT
	var mbr:bool = is_button and event.button_index == MOUSE_BUTTON_RIGHT
	var pressed:bool = is_button and event.is_pressed()
	
	if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
		if pressed:
			element.stroke_start( hit_info )
			scene.stroke_start( element, hit_info )
		element.stroke_primary( hit_info )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	elif Input.is_mouse_button_pressed( MOUSE_BUTTON_RIGHT ):
		if pressed:
			element.stroke_start( hit_info )
			scene.stroke_start( element, hit_info )
		element.stroke_secondary( hit_info )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	elif (mbl or mbr) and not pressed:
		element.stroke_end()
		scene.stroke_end( element )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	# Scale with any special key + Mouse Wheel
	if event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
		if Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_UP ):
			scene.scale_by( 0.1 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_DOWN ):
			scene.scale_by( -0.1 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif not event is InputEventMouseMotion: # Pass Panning and Zoom with special keys
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _edit(elem:Object):
	element = elem
	if element:
		inspector.selected( element )
		scene.selected( element )


func _handles(object:Object):
	return object is SceneElement
