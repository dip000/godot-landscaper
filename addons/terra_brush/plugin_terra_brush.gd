@tool
extends EditorPlugin
# MAIN PLUGIN CONTROLLER:
#  Controls any selected TerraBrush node instance from the scene and sends the user inputs to paint, scale, etc..
#
# GLOBAL SCEHME:
#  1. This script gets the user input, sends it to the current TerraBrush node
#  2. TerraBrush will route the input action to an active TBrush
#  3. The TBrush will ultimately draw over the 'TBrush.texture' that will represent either height, color or spawn area
#  4. TBrush then sends that information to the shaders to visualize it
#  5. Finally, user will press the "Save Assets To Folder" and AssetsManager will save the progress in given folder


var _terra_brush:TerraBrush
var _inspector_plugin:AssetsManager


func _enter_tree():
	add_custom_type( "TerraBrush", "Node", preload("tool_terra_brush.gd"), preload("icon.svg") )
	
	_inspector_plugin = load("res://addons/terra_brush/plugin_assets_manager.gd").new( get_tree() )
	add_inspector_plugin( _inspector_plugin )
	
func _exit_tree():
	remove_custom_type( "TerraBrush" )
	remove_inspector_plugin( _inspector_plugin )


# Raycasts terrain colliders to track mouse pointer and sends input to an active TerraBrush node
func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	if _terra_brush and is_instance_valid( _terra_brush ) and event is InputEventMouse:
		var mouse = event.get_position()
		var space:PhysicsDirectSpaceState3D = get_tree().get_edited_scene_root().get_world_3d().direct_space_state
		var from:Vector3 = cam.project_ray_origin( mouse )
		var to:Vector3 =  from + (cam.project_ray_normal( mouse ) * cam.far)
		var ray: = PhysicsRayQueryParameters3D.create(from, to)
		var result = space.intersect_ray( ray )
		
		# Left clicking by default is box select and it's very anoying while drawing
		if not result:
			_terra_brush.exit_terrain()
			if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		_terra_brush.over_terrain( result.position )
		
		if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
			_terra_brush.paint( result.position, true )
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_terra_brush.paint( result.position, false )
		
		if Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_UP ):
			_terra_brush.scale( -2 )
		elif Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_DOWN ):
			_terra_brush.scale( 2 )
		
		if event is InputEventMouseButton and event.is_released():
			_terra_brush.paint_end()
		
		if event is InputEventMouseButton:
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _handles(object):
	if object is TerraBrush:
		_terra_brush = object
		return true
	else:
		return false
