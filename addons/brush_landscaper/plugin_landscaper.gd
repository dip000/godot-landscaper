@tool
extends EditorPlugin
class_name PluginLandscaper
# MAIN PLUGIN:
#  Controls any selected TerraBrush node instance from the scene and sends the user inputs to paint, scale, etc..
#
# ABOUT CODE TAGS:
#  * [WARNING] Possibly problematic operations
#  * [TEST] Under testing, should not be in main branch
#  * [NOT IMPLEMENTED] Placeholder for a future feature


const COLLISION_LAYER:int = 32

var _ui_template:PackedScene = load("res://addons/brush_landscaper/scenes/dock_ui.tscn")
var _ui_inst:UILandscaper
var _scene_inst:SceneLandscaper


func _enter_tree():
	# Instantiate on tree enter so its ready cycle works
	_ui_inst = _ui_template.instantiate()
	
	add_control_to_dock.call_deferred( EditorPlugin.DOCK_SLOT_RIGHT_UL, _ui_inst )
	add_custom_type( "SceneLandscaper", "Node", preload("scripts/scene_landscaper.gd"), preload("icon.svg") )

func _exit_tree():
	remove_custom_type( "SceneLandscaper" )
	remove_control_from_docks( _ui_inst )


# Raycasts terrain colliders to track mouse pointer and sends input to an active TerraBrush node
func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	
	# Ignore if not _landscaper or mouse is idle
	if not _scene_inst or not is_instance_valid( _scene_inst ) or not event is InputEventMouse:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	# Raycast
	var mouse = event.get_position()
	var space:PhysicsDirectSpaceState3D = get_tree().get_edited_scene_root().get_world_3d().direct_space_state
	var from:Vector3 = cam.project_ray_origin( mouse )
	var to:Vector3 =  from + (cam.project_ray_normal( mouse ) * cam.far)
	var ray: = PhysicsRayQueryParameters3D.create(from, to, 1<<(COLLISION_LAYER-1)) #layer to value
	var result = space.intersect_ray( ray )
	
	# Mouse actions
	var is_button:bool = event is InputEventMouseButton
	var pressed:bool = is_button and event.is_pressed()
	var lbm:bool = is_button and (event.button_index == MOUSE_BUTTON_LEFT)
	var rbm:bool = is_button and (event.button_index == MOUSE_BUTTON_RIGHT)
	var wheel_up:bool = is_button and (event.button_index == MOUSE_BUTTON_WHEEL_UP)
	var wheel_down:bool = is_button and (event.button_index == MOUSE_BUTTON_WHEEL_DOWN)
	
	# Left clicking by default is box select and it's very anoying while drawing
	if not result:
		_ui_inst.exit_terrain()
		if lbm:
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	# Ignore colliders that aren't from the current SceneLandscaper instance
	if result.collider != _scene_inst.terrain_body and result.collider != _scene_inst.overlay_body:
		if lbm:
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	_ui_inst.over_terrain( result.position )
	
	# Paint and scale
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_ui_inst.paint( result.position, true )
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_ui_inst.paint( result.position, false )
	elif not pressed and (rbm or lbm):
		_ui_inst.paint_end()
	
	if pressed and wheel_up:
		_ui_inst.scale_by( -2 )
	elif pressed and wheel_down:
		_ui_inst.scale_by( 2 )
	
	if is_button:
		return EditorPlugin.AFTER_GUI_INPUT_STOP


func _handles(object):
	if object is SceneLandscaper:
		if _scene_inst != object:
			_scene_inst = object
			_ui_inst.update_from_scene.call_deferred( _scene_inst )
		_ui_inst.set_enable( true )
		return true
	else:
		_ui_inst.set_enable( false )
		return false

func _edit(object):
	if not object:
		_ui_inst.set_enable( false )
