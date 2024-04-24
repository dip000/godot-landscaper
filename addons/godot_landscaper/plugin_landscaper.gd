@tool
extends EditorPlugin
class_name PluginLandscaper
# ABOUT THIS ADDON:
#  * Creates, paints and heightens terrain
#  * Spawns and paints grass
#  * Based in textures and 'paint brushing' over terrain
#
# ABOUT LANDSCAPER CLASSES:
#  * PluginLandscaper: 3D world inputs controller like scale, paint, etc..
#  * UILandscaper: UI Dock inputs controller. Works as a state machine for brushes
#  * SceneLandscaper: Creates and mantains scene references and 'RawLandscaper' data
#  * RawLandscaper: Raw data for each individual landscaping project


const COLLISION_LAYER_TERRAIN:int = 32
const COLLISION_LAYER_OVERLAY:int = 31

var _ui_template:PackedScene = load("res://addons/godot_landscaper/scenes/ui_landscaper.tscn")
var _ui_inst:UILandscaper
var _scene_inst:SceneLandscaper


func _enter_tree():
	_ui_inst = _ui_template.instantiate()
	add_control_to_dock.call_deferred( EditorPlugin.DOCK_SLOT_RIGHT_UL, _ui_inst )
	add_custom_type( "SceneLandscaper", "Node", preload("scripts/scene_landscaper.gd"), preload("icon.svg") )

func _exit_tree():
	remove_custom_type( "SceneLandscaper" )
	remove_control_from_docks( _ui_inst )


# Raycasts terrain colliders to track mouse pointer and sends input to an active 'SceneLandscaper' node
func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	# Accepted inputs
	var is_motion:bool = (event is InputEventMouseMotion)
	var is_button:bool = (event is InputEventMouseButton)
	
	if not _scene_inst or not (is_motion or is_button):
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
	
	_ui_inst.over_terrain( result.position )
	
	# Paint
	var mbl:bool = is_button and event.button_index == MOUSE_BUTTON_LEFT
	var mbr:bool = is_button and event.button_index == MOUSE_BUTTON_RIGHT
	var pressed:bool = is_button and event.is_pressed()
	
	if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
		_ui_inst.paint( result.position, true )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	elif Input.is_mouse_button_pressed( MOUSE_BUTTON_RIGHT ):
		_ui_inst.paint( result.position, false )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	elif (mbl or mbr) and not pressed:
		_ui_inst.paint_end()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	# Scale with any special key + Mouse Wheel
	if event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
		var up:bool = Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_UP )
		var down:bool = Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_DOWN )
		if up:
			_ui_inst.scale_by( 0.005 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif down:
			_ui_inst.scale_by( -0.005 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif not event is InputEventMouseMotion: # Pass Panning and Zoom with special keys
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


# Quick-saves UI properties with "Ctrl+S"
func _save_external_data():
	if _scene_inst:
		_ui_inst.save_ui()


func _handles(object):
	return object is SceneLandscaper


func _edit(new_scene:Variant):
	if new_scene == _scene_inst:
		return
	
	if new_scene:
		if _scene_inst:
			_ui_inst.deselected_scene( _scene_inst )
		_ui_inst.selected_scene.call_deferred( new_scene )
		_scene_inst = new_scene
	else:
		_ui_inst.deselected_scene( _scene_inst )
		_scene_inst = null

