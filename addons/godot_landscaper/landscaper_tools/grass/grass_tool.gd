@tool
extends LandscaperTool
class_name GrassTool

#region ExportBrushes
@export_category("Brushes")
## How many grass instances coincides to hit over the surface per frame
@export_range(1.0, 10.0, 1.0, "or_greater") var spawn_ratio:float = 1.0
## How many grass instances attempt to erase per frame
@export_range(0.1, 1.0, 0.1) var erase_ratio:float = 1.0
## The parent for the generated MultiMeshInstance3D grass. Grass will be anchored to this node's position
## Consider using multiple Grass3DTool for non-static objects. Like a golem that will move at some point
@export var anchor_node:Node3D

## The transition between the terrain color and the top hand-painted color.
@export_range(-1.0, 1.0, 0.01) var splash_height:float = 0.0:
	set(v): if _project: _project.set_shader_parameter("splash_height", v, false)
	get: return _project.get_shader_parameter("splash_height", 0.0, false) if _project else 0.0

## Grass color with left button mouse
@export var primary_color:Color = Color.PALE_GOLDENROD
## Grass color with right button mouse
@export var secondary_color:Color = Color.PALE_VIOLET_RED
#endregion


#region ExportGroundColoring
@export_group("Ground Coloring")
@export var paint_with_sencondary_color:bool = false:
	set(v): 
		paint_with_sencondary_color = v
		_notify_property_list_changed_once()
## Clears ghost colliders and cached brush data in case of errors
@export_tool_button("Clear Scanner Cache", "Clear") var clear_cache:Callable = Scanner.clear_cache

@export_subgroup("Scan Physics Bodies:")
## The collision_layer to scan for any developer-made PhysicsBody3D 
@export_flags_3d_physics var scan_layer:int = 0xFFFFFFFF
## The collision_layer for internal PhysicsBody3D. Set one that you're not using anywhere else
@export_flags_3d_physics var scan_layer_internal:int = (1<<31)
@export_subgroup("Scan Meshes:")
## Attempts to find the mesh of the scanned PhysicsBody3D in its parent
@export var parent_of_physics_body:bool = true
## Attempts to find the mesh of the scanned PhysicsBody3D from any MeshInstance3D children
@export var children_of_physics_body:bool = true
## NodePath from the scanned PhysicsBody3D to its mesh
@export var relative_path_from_physics_body:StringName = ""

@export_subgroup("Scan Color Sources:")
## Property path from the scanned standar material to the source of color, can be a texture, vec3, or a vec4 
@export var paths_in_standar_materials:Array[String] = ["albedo_texture", "albedo_color"]
## Property path from the scanned shader material to the source of color, can be a texture, vec3, or a vec4 
@export var paths_in_shader_materials:Array[String] = ["texture", "color"]
## Color when the scanner couldn't find any color source
@export var fallback_color:Color = Color.MAGENTA
#endregion


#region ExportGrassInstances
@export_category("Quad Grass")
@export var grass_0:GrassQuadConfigs:
	get: return get_instance(_project, 0)
	set(v): set_instance(_project, v, 0)
@export var grass_1:GrassQuadConfigs:
	get: return get_instance(_project, 1)
	set(v): set_instance(_project, v, 1)
@export var grass_2:GrassQuadConfigs:
	get: return get_instance(_project, 2)
	set(v): set_instance(_project, v, 2)
@export var grass_3:GrassQuadConfigs:
	get: return get_instance(_project, 3)
	set(v): set_instance(_project, v, 3)
#endregion


#region Executables
@export_category("Optimization Tools")
@export var chunkify:ExecMMIChunkify = ExecMMIChunkify.new()
@export var level_of_detail:ExecMMILoD = ExecMMILoD.new()
@export_category("Rebuild And Fix Tools")
@export var rescan_level:ExecMMIRescanLevel = ExecMMIRescanLevel.new()
@export var rescan_color:ExecMMIRescanColor = ExecMMIRescanColor.new()
#endregion


#region ExportSaveLoad
@export_category("Save Or Load Project")
var _project:GrassSaveQuad
## Where the spawned instances be hosted.
## Please save them in your file system.
@export var project:GrassSaveQuad:
	get: return _project
	set(v): _set_project(GrassSaveQuad, _project, v)
#endregion


func _validate_property(property):
	_validate_configs(_project, GrassQuadConfigs.CAP, property)
	if paint_with_sencondary_color:
		_validate_paint_with_sencondary_color( property )

func run_executable(executable:Executable) -> void:
	if _project and executable:
		_project.run_executable( executable, self )
		GLDebug.state("Executable executabled executably")

func reset_executable(executable:Executable) -> void:
	if _project and executable:
		_project.reset_executable( executable, self )
		GLDebug.state("Executable reseted")


func select_brush(brush:Brush) -> void:
	if _project:
		_project.select_brush( brush, self )
		GLDebug.internal("Selected: %s/%s" %[name, brush.resource_name])
		_notify_property_list_changed_once()


func action_start(hit_info:Dictionary) -> void:
	if not anchor_node:
		anchor_node = Scanner.scan_mesh(
			SceneRaycaster.hit_info.collider if SceneRaycaster.hit_info else null,
			parent_of_physics_body, children_of_physics_body, relative_path_from_physics_body
		)
		if not anchor_node:
			GLDebug.error("Please select an anchor node")
			return
		GLDebug.warning("'%s' Was auto-selected as anchor node" %anchor_node)
	_project.action_start(hit_info)

func action_primary(hit_info:Dictionary) -> void:
	if _project: _project.action_primary(hit_info)

func action_secondary(hit_info:Dictionary) -> void:
	if _project: _project.action_secondary(hit_info)

func action_end() -> void:
	if _project: _project.action_end()

func scale_by(value:float):
	pass
