## Grass based of a quad mesh
## This Color-Bakes the painting done into each blade of grass using
## MultiMesh.use_colors and MultiMesh.use_custom_data

@tool
extends LandscaperTool
class_name QuadGrassTool

# Increase grass_n and set shaders capacity to this value as well
# [TODO] make it dynamic, of course..
const INSTANCES_CAP:int = 4

# Managed by InspectorTools
# Category Name > Tab Name > Tab Property Name > Tab Property Value
var CURRENT_TAB:String
var TABS_CONFIG:Dictionary[String,Dictionary] = {
	"Actions":{
		"Spawn":{
			"info": "Left click to spawn, right click to erase",
			"icon": AtlasIcon.Icon.GRASS_SCATTER,
			"method": spawn_select,
			"hide_properties": ["primary_color", "secondary_color", "splash_height"],
		},
		"Paint":{
			"info": "left cick to paint with primary color, right click for secondary",
			"icon": AtlasIcon.Icon.COLOR,
			"method": paint_select,
			"hide_properties": ["spawn_ratio", "erase_ratio", "ground_mesh"],
		}
	}
}


@export_category("Actions")
## How many grass instances coincides to hit over the surface per frame
@export_range(1.0, 10.0, 1.0, "or_greater") var spawn_ratio:float = 1.0
## How many grass instances attempt to erase per frame
@export_range(0.1, 1.0, 0.1) var erase_ratio:float = 0.7
## The parent for the generated MultiMeshInstance3D grass. Grass be anchored to this node's position
@export var ground_mesh:MeshInstance3D


## The transition between the terrain color and the top hand-painted color.
@export_range(0.0, 2.0, 0.01) var splash_height:float = 1.0:
	set(v):
		if project and project.material:
			project.material.set_shader_parameter("splash_height", v)
	get:
		if project and project.material:
			return project.material.get_shader_parameter("splash_height")
		return 0.0

## Grass color with left button mouse
@export var primary_color:Color = Color.PALE_GREEN
## Grass color with right button mouse
@export var secondary_color:Color = Color.PALE_VIOLET_RED


@export_group("Ground Coloring")
@export var paint_with_sencondary_color:bool = false:
	set(v): 
		paint_with_sencondary_color = v
		notify_property_list_changed()

@export_subgroup("Scan Physics Bodies:")
## The collision_layer to scan for any PhysicsBody3D 
@export_flags_3d_physics var scan_layer:int = 0xFFFFFFFF
## [NOT-IMPLEMENTED] Creates a temporal Trimesh collision to perfectly place the grass over the actual mesh surface
@export var create_temporal_perfect_colliders:bool = false
@export_subgroup("Scan Meshes:")
## Attempts to find the mesh of the scanned PhysicsBody3D in its parent
@export var parent_of_physics_body:bool = true
## Attempts to find the mesh of the scanned PhysicsBody3D from any MeshInstance3D children
@export var children_of_physics_body:bool = true
## NodePath from the scanned PhysicsBody3D to its mesh
@export var relative_path_from_physics_body:StringName = ""
@export_subgroup("Scan Materials:")
## Index order to find a material in a scanned mesh. See MeshInstance3D.get_active_material(index)
@export var active_material_indexes:Array[int] = [0, 1]
@export_subgroup("Scan Color Sources:")
## Property path from the scanned standar material to the source of color, can be a texture, vec3, or a vec4 
@export var paths_in_standar_materials:Array[String] = ["albedo_texture", "albedo_color"]
## Property path from the scanned shader material to the source of color, can be a texture, vec3, or a vec4 
@export var paths_in_shader_materials:Array[String] = ["texture", "color"]
## Color when the scanner couldn't find any color source
@export var fallback_color:Color = Color.MAGENTA

func _validate_property(property:Dictionary):
	if paint_with_sencondary_color:
		var hide_properties:Array[String] = [
			"parent_of_physics_body", "children_of_physics_body", "relative_path_from_physics_body",
			"active_material_indexes",
			"paths_in_standar_materials", "paths_in_shader_materials", "fallback_color",
		]
		if property.name in hide_properties:
			property.usage = PROPERTY_USAGE_NONE




# Cleanly link them to the project, just so the array doesn't clutter the inspector
# Capping them to four, for fear of saturating the GPU with texture variants
@export_category("Grass Instances")
## Use 'Resource Name' as the MultimeshInstance3D scene node. Defaults to 'Grass 0'
@export var grass_0:QuadGrassConfigs:
	get: return _get_instance(0)
	set(v): _set_instance(0, v)
## Use 'Resource Name' as the MultimeshInstance3D scene node. Defaults to 'Grass 1'
@export var grass_1:QuadGrassConfigs:
	get: return _get_instance(1)
	set(v): _set_instance(1, v)
## Use 'Resource Name' as the MultimeshInstance3D scene node. Defaults to 'Grass 2'
@export var grass_2:QuadGrassConfigs:
	get: return _get_instance(2)
	set(v): _set_instance(2, v)
## Use 'Resource Name' as the MultimeshInstance3D scene node. Defaults to 'Grass 3'
@export var grass_3:QuadGrassConfigs:
	get: return _get_instance(3)
	set(v): _set_instance(3, v)

func _get_instance(index:int) -> QuadGrassConfigs:
	if not is_inside_tree(): return
	if not project: return
	if index >= project.grass_configs.size(): return null
	return project.grass_configs[index]

func _set_instance(index:int, inst:QuadGrassConfigs):
	if not is_inside_tree(): return
	if not project:
		_create_project_template()
	project.grass_configs.resize(INSTANCES_CAP)
	project.grass_configs[index] = inst
	project.notify_property_list_changed()
	if inst and CURRENT_TAB: # Update the currently selected action
		GLDebug.state("Loaded new instance: %s" %inst)
		inst.current_action = inst.color_action if "Paint"==CURRENT_TAB else inst.spawn_action


@export_category("Save Or Load Files")
## Where the spawned instances be hosted.
## Please save them in your file system.
@export var project:QuadGrassSave:
	set(v):
		project = v
		if not is_inside_tree(): return
		if not (project and CURRENT_TAB): return
		
		# Update every QuadGrassConfigs.current_action to the currently selected tab
		GLDebug.state("Loaded new project: '%s'" %project.resource_path)
		_force_fill_dependencies()
		TABS_CONFIG["Actions"][CURRENT_TAB].method.call()
		
		# Rebuild loaded project
		for config in project.grass_configs:
			if config:
				config.current_action.unpack( self, project, config )
				config.current_action.rebuild()


@export_category("Optimization Tools")
@export_group("Chunkify Grass")
@export var chunk_size:int = 32
@export_tool_button("     Chunkify     ", "Grid") var chunkify:Callable = OptimizationQuadGrass.chunkify
@export_tool_button("        Reset        ", "Object") var reset_chunks:Callable = OptimizationQuadGrass.reset_chunks

@export_group("Visibility And Level Of Detail")
@export_range(0.0, 1.0, 0.01) var visible_instances:float = 1.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32
@export_tool_button("      Update      ", "UndoRedo") var change_visible:Callable = OptimizationQuadGrass.update_visiblity
@export_tool_button("        Reset        ", "Object") var reset_visible:Callable = OptimizationQuadGrass.reset_visible


@export_category("Rebuild And Fix Tools")
@export_group("Rescan Terrain Level")
## Range in meters on Y axis that the grass will try to scan for a surface to sit on
@export var rescan_range_y:float = 10
@export_tool_button(" Rescan Terrain Level ", "UndoRedo") var _rescan_position_y:Callable = rescan_position_y

@export_group("Rescan Bottom Colors")
@export_tool_button("Rescan Bottom Colors", "UndoRedo") var _rescan_colors:Callable = rescan_colors




func _exit_tree():
	if Landscaper.running():
		_clear_undo_redo()


func rescan_position_y():
	if not project:
		return
	
	_create_undo_redo("rescan_position_y")
	for config in project.grass_configs:
		if config and config.enable:
			_add_undo( config )
			config.spawn_action.unpack( self, project, config )
			config.spawn_action.rescan_position_y( rescan_range_y )
			config.spawn_action.rebuild()
			_add_redo( config )
	_commit_undo_redo()


func rescan_colors():
	if not project:
		return
	
	_create_undo_redo("rescan_colors")
	for config in project.grass_configs:
		if config and config.enable:
			_add_undo( config )
			config.spawn_action.unpack( self, project, config )
			config.spawn_action.rescan_bottom_colors( rescan_range_y )
			config.spawn_action.rebuild()
			_add_redo( config )
	_commit_undo_redo()


# Selects the "Spawn" config resource
func spawn_select():
	if not project:
		return
		
	Landscaper.scene.raycaster.set_collision_mask( scan_layer )
	Landscaper.scene.brush.select_action( AtlasIcon.Icon.GRASS_SCATTER )
	for config in project.grass_configs:
		if config:
			config.current_action = config.spawn_action


# Selects the "Paint" config resource
func paint_select():
	if not project:
		return
	
	Landscaper.scene.brush.select_action( AtlasIcon.Icon.COLOR )
	for config in project.grass_configs:
		if config:
			config.current_action = config.color_action


# Called on stroke start from the main Landscaper class on 3D world inputs
func action_start(hit_info:Dictionary):
	if not _validate_action():
		return
	
	if OptimizationQuadGrass.chunkified:
		OptimizationQuadGrass.reset_chunks()
		GLDebug.warning("Chunks were reseted to be modified")
	
	_create_undo_redo( CURRENT_TAB )
	for config in project.grass_configs:
		if config and config.enable:
			config.current_action.unpack( self, project, config )
			config.current_action.start( hit_info )
			_add_undo( config )


# Called every frame after the start of the stroke. LMB action
func action_primary(hit_info:Dictionary):
	if not project:
		return
	
	GLDebug.spam("Painting with primary at: %s" %hit_info.position)
	for config in project.grass_configs:
		if config and config.enable:
			config.current_action.primary( hit_info )


# Called every frame after the start of the stroke.  RMB action
func action_secondary(hit_info:Dictionary):
	if not project:
		return
	
	GLDebug.spam("Painting with secondary at: %s" %hit_info.position)
	for config in project.grass_configs:
		if config and config.enable:
			config.current_action.secondary( hit_info )


# Called on stroke end
func action_end():
	if not project:
		return
	
	for config in project.grass_configs:
		if config and config.enable:
			config.current_action.end()
			_add_redo(config)
	_commit_undo_redo()


func _validate_action() -> bool:
	if not ground_mesh:
		ground_mesh = SceneManager.scan_mesh_from_hit_info(parent_of_physics_body, children_of_physics_body, relative_path_from_physics_body)
		if not ground_mesh:
			GLDebug.error("No ground mesh was selected")
			return false
	
	if project:
		_force_fill_dependencies()
	else:
		_create_project_template()
	return true


func _force_fill_dependencies():
	var resources_added:String
	if not project.shader:
		project.shader = AssetsManager.grass.color_baked.duplicate()
		resources_added += "Grass Shader, "
	
	if not project.material:
		project.material = AssetsManager.grass.material.duplicate()
		resources_added += "Grass Material, "
	project.material.shader = project.shader
	
	if not project.mesh:
		project.mesh = QuadMesh.new()
		project.mesh.orientation = PlaneMesh.FACE_Y
		project.mesh.center_offset.z = -0.48 #pivot is on its bottom (minus a small margin)
		resources_added += "Grass Mesh, "
	project.mesh.material = project.material
	
	if resources_added:
		GLDebug.warning("The following resources were added: %s" %resources_added)
	
	# Force fill shader parameters
	if not project.material["shader_parameter/grass_textures"]:
		project.material["shader_parameter/grass_textures"] = []
	project.material["shader_parameter/grass_textures"].resize(INSTANCES_CAP)
	project.material.set_shader_parameter("splash_height", splash_height)
	project.material.notify_property_list_changed()


# Resource.duplicate() cannot fully duplicate a stored template so..
func _create_project_template():
	project = QuadGrassSave.new()
	_force_fill_dependencies()
	
	project.grass_configs.resize(INSTANCES_CAP)
	project.grass_configs[0] = QuadGrassConfigs.new()
	project.grass_configs[0].grass_texture = AssetsManager.grass.tall.duplicate()
	project.grass_configs[0].resource_name = "GrassTall"
	project.grass_configs[0].rotation_randomize.y = TAU
	project.grass_configs[1] = QuadGrassConfigs.new()
	project.grass_configs[1].grass_texture = AssetsManager.grass.sunflower.duplicate()
	project.grass_configs[1].resource_name = "Sunflower"
	project.grass_configs[1].rotation_randomize.y = TAU
	project.grass_configs[1].detail_enable = true
	project.grass_configs[1].detail_color = Color(0.184, 0.31, 0.31)
	project.notify_property_list_changed()
	
	# Update every QuadGrassConfigs.current_action to the currently selected tab
	if CURRENT_TAB:
		TABS_CONFIG["Actions"][CURRENT_TAB].method.call()
	GLDebug.state("Created a new template project. Please save your resources manually")


func _create_undo_redo(action:String):
	Landscaper.undo_redo.create_action("godot_landscaper/quad_grass_tool/"+action.to_snake_case(), UndoRedo.MERGE_DISABLE)

func _commit_undo_redo():
	Landscaper.undo_redo.commit_action(false)

func _clear_undo_redo():
	Landscaper.undo_redo.clear_history( EditorUndoRedoManager.GLOBAL_HISTORY )

func _add_redo(config:QuadGrassConfigs):
	var undo_redo:EditorUndoRedoManager = Landscaper.undo_redo
	undo_redo.add_do_property( config, "top_colors", config.top_colors.duplicate() )
	undo_redo.add_do_property( config, "bottom_colors", config.bottom_colors.duplicate() )
	undo_redo.add_do_property( config, "transforms", config.transforms.duplicate() )
	undo_redo.add_do_method( config.current_action, "rebuild" )

func _add_undo(config:QuadGrassConfigs):
	var undo_redo:EditorUndoRedoManager = Landscaper.undo_redo
	undo_redo.add_undo_property( config, "top_colors", config.top_colors.duplicate() )
	undo_redo.add_undo_property( config, "bottom_colors", config.bottom_colors.duplicate() )
	undo_redo.add_undo_property( config, "transforms", config.transforms.duplicate() )
	undo_redo.add_undo_method( config.current_action, "rebuild" )
