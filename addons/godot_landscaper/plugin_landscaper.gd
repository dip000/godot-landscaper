@tool
extends EditorPlugin
class_name PluginLandscaper
## MAIN CLASSES:
##  * PluginLandscaper: 3D world inputs controller like scale, paint_brushing, etc.. Routes control to 'UIControl'
##  * UIControl: UI Dock inputs controller. Works as a state machine for brushes. Routes controll to 'AssetsManager'
##  * SceneLandscaper: Creates or updates scene references and hosts a 'ProjectLandscaper' resource
##  * ProjectLandscaper: Project data for each individual landscaping project. It's the saved project.tres file
##[TODO] Add a global "Settings" panel somewhere

# Internal collisions for spawning instances
#[TODO] Add these properties to global settings
const COLLISION_LAYER_TERRAIN:int = 32
const COLLISION_LAYER_OVERLAY:int = 31

var _ui_control:UIControl
var _scene_landscaper_template:PackedScene = load("res://addons/godot_landscaper/scenes/ui_control.tscn")
var _scene_landscaper:SceneLandscaper


func _enter_tree():
	_ui_control = _scene_landscaper_template.instantiate()
	add_control_to_dock.call_deferred( EditorPlugin.DOCK_SLOT_RIGHT_UL, _ui_control )
	add_custom_type( "SceneLandscaper", "Node", preload("scripts/scene_landscaper.gd"), preload("icon.svg") )

func _exit_tree():
	remove_custom_type( "SceneLandscaper" )
	remove_control_from_docks( _ui_control )
	_ui_control.queue_free()


# Raycasts terrain colliders to track mouse pointer and sends input to an active 'SceneLandscaper' node
func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	# Accepted inputs
	var is_motion:bool = (event is InputEventMouseMotion)
	var is_button:bool = (event is InputEventMouseButton)
	
	if not (is_motion or is_button):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	
	# Raycast to terrain
	var mouse = event.get_position()
	var space:PhysicsDirectSpaceState3D = get_tree().get_edited_scene_root().get_world_3d().direct_space_state
	var from:Vector3 = cam.project_ray_origin( mouse )
	var to:Vector3 =  from + (cam.project_ray_normal( mouse ) * cam.far)
	var ray: = PhysicsRayQueryParameters3D.create(from, to, 1<<(COLLISION_LAYER_TERRAIN-1)) #layer to value
	var result = space.intersect_ray( ray )
	
	
	# Try with overlay collider if terrain was not detected
	if not result:
		ray.collision_mask = 1 << (COLLISION_LAYER_OVERLAY-1) #layer to value
		result = space.intersect_ray( ray )
		if not result:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	_ui_control.over_terrain( result.position )
	
	
	# Paint
	var mbl:bool = is_button and event.button_index == MOUSE_BUTTON_LEFT
	var mbr:bool = is_button and event.button_index == MOUSE_BUTTON_RIGHT
	var pressed:bool = is_button and event.is_pressed()
	
	if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
		if pressed:
			_ui_control.paint_start( result.position )
		_ui_control.paint_primary( result.position )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	elif Input.is_mouse_button_pressed( MOUSE_BUTTON_RIGHT ):
		if pressed:
			_ui_control.paint_start( result.position )
		_ui_control.paint_secondary( result.position )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	elif (mbl or mbr) and not pressed:
		_ui_control.paint_end()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	# Scale with any special key + Mouse Wheel
	if event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
		if Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_UP ):
			_ui_control.scale_by( 0.005 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_DOWN ):
			_ui_control.scale_by( -0.005 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif not event is InputEventMouseMotion: # Pass Panning and Zoom with special keys
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


# Quick-saves UI properties with "Ctrl+S"
func _save_external_data():
	if _scene_landscaper:
		_ui_control.save_ui()

# Clean up on disable
func _disable_plugin():
	if _scene_landscaper:
		_ui_control.save_ui()
		_ui_control.deselected_scene( _scene_landscaper )
		_scene_landscaper = null

func _handles(object):
	return object is SceneLandscaper


func _edit(new_scene_landscaper:Variant):
	# This function gets called multiple times so just make sure not to spam it
	if new_scene_landscaper == _scene_landscaper:
		return
	
	if new_scene_landscaper:
		if _scene_landscaper:
			_ui_control.deselected_scene( _scene_landscaper )
		_scene_landscaper = new_scene_landscaper
		_ui_control.selected_scene( new_scene_landscaper )
	else:
		_ui_control.deselected_scene( _scene_landscaper )
		_scene_landscaper = null
