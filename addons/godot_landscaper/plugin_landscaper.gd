@tool
extends EditorPlugin
class_name Landscaper

static var scene:SceneManager
static var assets:AssetsManager
static var inspector:GLInspectorManager
static var undo_redo:GLUndoRedo
static var is_enabled:bool

var _active_controller:GLController


static func running() -> bool:
	return Engine.is_editor_hint() and is_enabled


func _enter_tree():
	GLDebug.state("Starting GodotLandscaper..")
	assets = AssetsManager.ASSETS_MANAGER.instantiate()
	scene = AssetsManager.SCENE_MANAGER.instantiate()
	inspector = GLInspectorManager.new()
	add_inspector_plugin( inspector )
	undo_redo = GLUndoRedo.new( get_undo_redo() )
	
	await get_tree().process_frame
	var viewport:SubViewport = EditorInterface.get_editor_viewport_3d()
	viewport.add_child( assets )
	viewport.add_child( scene )
	is_enabled = true
	GLDebug.state("Started GodotLandscaper!")
	

func _exit_tree():
	GLDebug.state("Closing GodotLandscaper..")
	is_enabled = false
	remove_inspector_plugin( inspector )
	assets.queue_free()
	scene.queue_free()
	undo_redo.free()
	GLDebug.state("Closed GodotLandscaper")
	

# Raycasts terrain colliders to track mouse pointer and sends input to an active 'SceneLandscaper' node
func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	if not _active_controller or not _active_controller.is_ready:
		return
	
	# Accepted inputs
	var is_motion:bool = (event is InputEventMouseMotion)
	var is_button:bool = (event is InputEventMouseButton)
	
	if not (is_motion or is_button):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	# Raycast
	var hit_info:Dictionary = scene.raycaster.cam_to_surface( cam, event.get_position() )
	if not hit_info:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	scene.over_surface( _active_controller, hit_info.position )
	
	# Paint
	var mbl:bool = is_button and event.button_index == MOUSE_BUTTON_LEFT
	var mbr:bool = is_button and event.button_index == MOUSE_BUTTON_RIGHT
	var pressed:bool = is_button and event.is_pressed()
	
	if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
		if pressed:
			_active_controller.stroke_start( hit_info )
			scene.stroke_start( _active_controller, hit_info )
		_active_controller.stroke_primary( hit_info )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	elif Input.is_mouse_button_pressed( MOUSE_BUTTON_RIGHT ):
		if pressed:
			_active_controller.stroke_start( hit_info )
			scene.stroke_start( _active_controller, hit_info )
		_active_controller.stroke_secondary( hit_info )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	elif (mbl or mbr) and not pressed:
		_active_controller.stroke_end()
		scene.stroke_end( _active_controller )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	# Scale with any special key + Mouse Wheel
	if event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
		if Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_UP ):
			scene.scale_up( _active_controller )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_DOWN ):
			scene.scale_down( _active_controller )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif not event is InputEventMouseMotion: # Pass Panning and Zoom with special keys
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _edit(controller:Object):
	if controller:
		inspector.selected( controller )
		scene.selected( controller )
	else:
		scene.deselected( controller )
	_active_controller = controller



func _handles(object:Object):
	return object is GLController
	
	
