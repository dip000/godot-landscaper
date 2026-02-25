@tool
extends EditorPlugin
class_name GLandscaper

enum Action {PRIMARY, SECONDARY}

const DEEP_OCEAN:Color=Color("#067972")
const VERDIGIRS:Color=Color("#0AA298")
const DUSTY_ROSE:Color=Color("#CC8375")
const LEMON_CHIFFON:Color=Color("#FEF6C9")

static var scene:GLSceneManager
static var assets:GLAssetsManager
static var inspector:GLInspectorManager
static var undo_redo:GLUndoRedo
static var is_enabled:bool

var _active_controller:GLController


static func running() -> bool:
	return Engine.is_editor_hint() and is_enabled


func _enter_tree():
	GLDebug.state("Starting GodotLandscaper..")
	assets = GLAssetsManager.ASSETS_MANAGER.instantiate()
	scene = GLAssetsManager.SCENE_MANAGER.instantiate()
	inspector = GLInspectorManager.new()
	inspector.landscaper = self
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
	inspector.deselected( _active_controller )
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
	
	# Surface Scanner with raycasting
	var hit_info:Dictionary = scene.raycaster.cam_to_surface( cam, event.get_position() )
	if not hit_info:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	var scan_data:GLScanData = GLScanData.new()
	scan_data.set_hit_info( hit_info )
	scene.over_surface( _active_controller, scan_data )
	
	# Paint
	var mbl:bool = is_button and event.button_index == MOUSE_BUTTON_LEFT
	var mbr:bool = is_button and event.button_index == MOUSE_BUTTON_RIGHT
	var pressed:bool = is_button and event.is_pressed()
	
	if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
		if pressed:
			_active_controller.stroke_start( Action.PRIMARY, scan_data )
			scene.stroke_start( Action.PRIMARY, _active_controller, scan_data )
		_active_controller.stroking( Action.PRIMARY, scan_data )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	elif Input.is_mouse_button_pressed( MOUSE_BUTTON_RIGHT ):
		if pressed:
			_active_controller.stroke_start( Action.SECONDARY, scan_data )
			scene.stroke_start( Action.SECONDARY, _active_controller, scan_data )
		_active_controller.stroking( Action.SECONDARY, scan_data )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	elif (mbl or mbr) and not pressed:
		_active_controller.stroke_end( Action.SECONDARY, scan_data )
		scene.stroke_end( Action.SECONDARY, _active_controller )
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
	if controller == _active_controller:
		return
	
	if controller:
		if not controller.is_ready:
			await Engine.get_main_loop().process_frame
			await Engine.get_main_loop().process_frame
			await Engine.get_main_loop().process_frame
		if controller.is_ready:
			inspector.selected( controller )
			scene.selected( controller )
		else:
			GLDebug.error("Can't select a controller: The controller timed out. Try re-selecting it from the scene tree, or restarting the editor")
	else:
		scene.deselected( _active_controller )
		scene.deselected( _active_controller )
		inspector.deselected( _active_controller )
	_active_controller = controller


func _handles(object:Object):
	return object is GLController
	







	
