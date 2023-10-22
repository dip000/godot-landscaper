@tool
extends EditorPlugin

var instanced_tool:TerraBrush
var inspector_plugin:EditorInspectorPlugin


func _enter_tree():
	add_custom_type("TerraBrush", "MeshInstance3D", preload("tool_terra_brush.gd"), preload("icon.svg"))
	
	inspector_plugin = load("res://addons/terra_brush/plugin_inspector.gd").new( get_tree() )
	add_inspector_plugin( inspector_plugin )
	
func _exit_tree():
	remove_custom_type("TerraBrush")
	remove_inspector_plugin(inspector_plugin)


func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	if instanced_tool and is_instance_valid(instanced_tool) and event is InputEventMouse:
		var root = get_tree().get_edited_scene_root()
		var space = root.get_world_3d().direct_space_state
		var mouse = event.get_position() #mouse position from viewport might not work properly. Use event's mouse position instead
		var origin = cam.project_ray_origin(mouse)
		var dir = cam.project_ray_normal(mouse)
		var ray = PhysicsRayQueryParameters3D.create(origin, origin + dir * cam.far)
		var result = space.intersect_ray(ray)
		
		if not result:
			instanced_tool.exit_terrain()
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		instanced_tool.over_terrain( result.position )
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			instanced_tool.paint(result.position, true)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			instanced_tool.paint(result.position, false)
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			instanced_tool.scale(-5)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			instanced_tool.scale(5)
		
		if event is InputEventMouseButton:
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _handles(object):
	if object is TerraBrush:
		instanced_tool = object
		instanced_tool.scene_active()
		return true
	else:
		return false
