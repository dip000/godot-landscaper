@tool
extends LandscaperTool
class_name Grass3DTool
## Grass based of 3D meshes.
## This Color-Bakes the painting done into each blade of grass using
## MultiMesh.use_colors and MultiMesh.use_custom_data

#region Constants
# Max amount of grass variants.
# [TODO] Make dynamic. Placing the property in the right category with _get_property_list() is not possible
const INSTANCES_CAP:int = 8

# Managed by InspectorTools
var TABS_CONFIG:Array[InspectorTab] = [
	preload(AssetsManager.INSPECTOR_TOOLS_ROOT+"tabs/spawn.tres"),
	preload(AssetsManager.INSPECTOR_TOOLS_ROOT+"tabs/paint.tres"),
]
var CURRENT_TAB:InspectorTab
#endregion


#region ExportActions
@export_category("Actions")
## How many grass instances coincides to hit over the surface per frame
@export_range(1.0, 10.0, 1.0, "or_greater") var spawn_ratio:float = 1.0
## How many grass instances attempt to erase per frame
@export_range(0.1, 1.0, 0.1) var erase_ratio:float = 1.0
## The parent for the generated MultiMeshInstance3D grass. Grass will be anchored to this node's position
## Consider using multiple Grass3DTool for non-static objects. Like a golem that will move at some point
@export var anchor_node:Node3D

## The transition between the terrain color and the top hand-painted color.
@export_range(0.0, 2.0, 0.01) var splash_height:float = 1.0:
	set(v):
		if _project and _project.material:
			_project.material.set_shader_parameter("splash_height", v)
	get:
		if _project and _project.material:
			return _project.material.get_shader_parameter("splash_height")
		return 1.0

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
		notify_property_list_changed()
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

func _validate_paint_with_sencondary_color(property:Dictionary):
	if paint_with_sencondary_color:
		var hide_properties:Array[String] = [
			"parent_of_physics_body", "children_of_physics_body", "relative_path_from_physics_body",
			"active_material_indexes",
			"paths_in_standar_materials", "paths_in_shader_materials", "fallback_color",
		]
		if property.name in hide_properties:
			property.usage = PROPERTY_USAGE_NONE
#endregion


#region ExportGrassInstances
# Cleanly link them to the _project, just so the array doesn't clutter the inspector
# They will be dynamically shown/hidden
@export_category("Grass Instances")
@export var grass_0:Grass3DConfigs:
	get: return _get_instance(0)
	set(v): _set_instance(v, 0)
@export var grass_1:Grass3DConfigs:
	get: return _get_instance(1)
	set(v): _set_instance(v, 1)
@export var grass_2:Grass3DConfigs:
	get: return _get_instance(2)
	set(v): _set_instance(v, 2)
@export var grass_3:Grass3DConfigs:
	get: return _get_instance(3)
	set(v): _set_instance(v, 3)
@export var grass_4:Grass3DConfigs:
	get: return _get_instance(4)
	set(v): _set_instance(v, 4)
@export var grass_5:Grass3DConfigs:
	get: return _get_instance(5)
	set(v): _set_instance(v, 5)
@export var grass_6:Grass3DConfigs:
	get: return _get_instance(6)
	set(v): _set_instance(v, 6)
@export var grass_7:Grass3DConfigs:
	get: return _get_instance(7)
	set(v): _set_instance(v, 7)

func _get_instance(index:int) -> Grass3DConfigs:
	if not is_inside_tree(): return
	if not _project: return
	if index >= _project.grass_configs.size(): return null
	return _project.grass_configs[index]

func _set_instance(inst:Grass3DConfigs, index:int):
	if not is_inside_tree(): return
	if not _project:
		_create_project_template()
	_project.grass_configs.resize(INSTANCES_CAP)
	_project.grass_configs[index] = inst
	notify_property_list_changed()
	if inst: # Update the currently selected brush
		GLDebug.state("Loaded new instance: %s" %inst)
		inst.current_brush = inst.color_action if CURRENT_TAB.name=="Paint" else inst.spawn_action

func _validate_property(property:Dictionary):
	_validate_paint_with_sencondary_color(property)
	
	if property.name.left(-1) != "grass_":
		return
	
	if _project:
		var index:int = property.name.right(-1).to_int()
		_project.grass_configs = _project.grass_configs.filter(func(v): return v)
		_project.grass_configs.resize( _project.grass_configs.size()+1 )
		if index > _project.grass_configs.size()-1:
			property.usage = PROPERTY_USAGE_NONE
			notify_property_list_changed()
	else:
		property.usage = PROPERTY_USAGE_NONE
		notify_property_list_changed()
#endregion


#region ExportSaveLoad
@export_category("Save Or Load Files")
var _project:Grass3DSave
## Where the spawned instances be hosted.
## Please save them in your file system.
@export var project:Grass3DSave:
	get: return _project
	set(v):
		_project = v
		if not is_inside_tree(): return
		if not _project: notify_property_list_changed()
		if not (_project and CURRENT_TAB): return
		
		if not anchor_node:
			GLDebug.error("Failed to load project. Update the Anchor Mesh and try again")
			return
		
		# For some reason you cannot save and keep the save project file. The undo_redo history will go crazy
		# Now i'll pretend this is a feature to keep changes local until saved manually again hehe
		GLDebug.state("Loaded new project: '%s'. Remember to keep saving your changes" %(_project.resource_path if _project.resource_path else "(empty)"))
		_project = _project.duplicate()
		EditorInterface.save_scene()
		
		# Update every Grass3DConfigs.current_brush to the currently selected tab
		_force_fill_dependencies()
		Callable(self, CURRENT_TAB.method).call()
		
		# Rebuild loaded project
		_for_each_config( func(config:Grass3DConfigs):
			config.current_brush.unpack( self, _project, config )
			config.current_brush.rebuild()
		)
#endregion


#region Tools
@export_category("Optimization Tools")
@export_group("Chunkify Grass")
@export var chunk_size:int = 32
@export var chunk_parent_name:String = "Chunks"
@export_tool_button("     Chunkify     ", "Grid") var chunkify:Callable = OptimizationQuadGrass.chunkify
@export_tool_button("        Reset        ", "Object") var reset_chunks:Callable = OptimizationQuadGrass.reset_chunks

@export_group("Visibility And Level Of Detail")
@export_range(0.0, 1.0, 0.01) var visible_instances:float = 1.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32
@export_tool_button("      Update      ", "UndoRedo") var change_visible:Callable = OptimizationQuadGrass.update_visiblity
@export_tool_button("        Reset        ", "Object") var reset_visible:Callable = OptimizationQuadGrass.reset_visible


@export_category("Rebuild And Fix Tools")
@export_group("Rescan Ground Level")
## Range in meters on Y axis that the grass will try to scan for a surface to sit on
@export var rescan_range_y:float = 2
@export_tool_button(" Rescan Ground Level ", "UndoRedo") var _rescan_position_y:Callable = rescan_position_y

@export_group("Rescan Bottom Colors")
@export_tool_button("Rescan Bottom Colors", "UndoRedo") var _rescan_colors:Callable = rescan_colors
#endregion



func _exit_tree():
	if Landscaper.running():
		_clear_undo_redo()
		Scanner.clear_cache()


# Selects the Spawn/Paint config resources
func spawn_select() -> void:
	if not _project: return
	_for_each_config( func(config:Grass3DConfigs):
		config.current_brush = config.spawn_action
	)

func paint_select() -> void:
	if not _project: return
	_for_each_config( func(config:Grass3DConfigs):
		config.current_brush = config.color_action
	)


# Called on brush start from the main Landscaper class on 3D world inputs
func action_start(hit_info:Dictionary) -> void:
	if not _validate_action(): return
	if OptimizationQuadGrass.is_chunkified():
		OptimizationQuadGrass.reset_chunks()
		GLDebug.warning("Chunks were reseted to be modified")
	
	GLDebug.internal("Brush started")
	_create_undo_redo( CURRENT_TAB.name )
	_for_each_enabled_config( func(config:Grass3DConfigs):
		config.current_brush.unpack( self, _project, config )
		config.current_brush.start( hit_info )
		_add_undo( config )
	)


# Called every frame after the start of the brush. LMB/RMB actions
func action_primary(hit_info:Dictionary) -> void:
	if not _validate_action(): return
	_for_each_enabled_config( func(config:Grass3DConfigs):
		config.current_brush.primary( hit_info )
	)

func action_secondary(hit_info:Dictionary) -> void:
	if not _validate_action(): return
	_for_each_enabled_config( func(config:Grass3DConfigs):
		config.current_brush.secondary( hit_info )
	)


# Called on brush end
func action_end() -> void:
	if not _validate_action(): return
	GLDebug.internal("Brush ended")
	_for_each_enabled_config( func(config:Grass3DConfigs):
		config.current_brush.end()
		_add_redo(config)
	)
	_commit_undo_redo()


# Rescan Tools
func rescan_position_y() -> void:
	if not _validate_action(): return
	if OptimizationQuadGrass.is_chunkified():
		OptimizationQuadGrass.reset_chunks()
		GLDebug.warning("Chunks were reseted to be modified")
	
	_create_undo_redo("rescan_position_y")
	Scanner.clear_cache()
	for config in _project.grass_configs:
		if config and config.enable:
			_add_undo( config )
			config.spawn_action.unpack( self, _project, config )
			await config.spawn_action.rescan_position_y( rescan_range_y )
			config.spawn_action.rebuild()
			_add_redo( config )
	_commit_undo_redo()
	Scanner.clear_cache()
	

func rescan_colors() -> void:
	if not _validate_action(): return
	if OptimizationQuadGrass.is_chunkified():
		OptimizationQuadGrass.reset_chunks()
		GLDebug.warning("Chunks were reseted to be modified")
	
	_create_undo_redo("rescan_colors")
	Scanner.clear_cache()
	for config in _project.grass_configs:
		if config and config.enable:
			config.spawn_action.unpack( self, _project, config )
			await config.spawn_action.rescan_bottom_colors( rescan_range_y )
			config.spawn_action.rebuild()
	_commit_undo_redo()
	Scanner.clear_cache()


#region Utilities
func _validate_action() -> bool:
	if not Landscaper.running() or not is_inside_tree():
		return false
	
	if not anchor_node:
		anchor_node = Scanner.scan_mesh(
			SceneRaycaster.hit_info.collider if SceneRaycaster.hit_info else null,
			parent_of_physics_body,
			children_of_physics_body,
			relative_path_from_physics_body
		)
		if not anchor_node:
			GLDebug.error("No Anchor Node was selected")
			return false
		GLDebug.warning("Auto selected '%s' as Anchor Node. This reference will anchor every grass position" %anchor_node.name)
	
	if _project:
		_force_fill_dependencies()
	else:
		_create_project_template()
	return true


func _force_fill_dependencies() -> void:
	var resources_added:String
	if not _project.shader:
		_project.shader = AssetsManager.grass.color_baked.duplicate()
		resources_added += "Grass Shader, "
	
	if not _project.material:
		_project.material = AssetsManager.grass.material.duplicate()
		resources_added += "Grass Material, "
	_project.material.shader = _project.shader
	
	if resources_added:
		GLDebug.warning("The following resources were added: %s" %resources_added)
	
	# Force fill shader parameters
	if not _project.material["shader_parameter/grass_textures"]:
		_project.material["shader_parameter/grass_textures"] = []
	_project.material.set_shader_parameter("splash_height", splash_height)
	notify_property_list_changed()


# Resource.duplicate() cannot fully duplicate a stored template so..
func _create_project_template() -> void:
	_project = Grass3DSave.new()
	_force_fill_dependencies()
	_project.grass_configs.resize(2)
	_project.grass_configs[0] = Grass3DConfigs.new()
	_project.grass_configs[1] = Grass3DConfigs.new()
	_fill_grass(_project.grass_configs[0], "Single3D", AssetsManager.grass.single3d)
	_fill_grass(_project.grass_configs[1], "Foxtail3D", AssetsManager.grass.foxtail3d)
	
	# Update every Grass3DConfigs.current_brush to the currently selected tab
	if CURRENT_TAB:
		Callable(self, CURRENT_TAB.method).call()
	GLDebug.state("Created a new template project. Please save your resources manually")

func _fill_grass(conf:Grass3DConfigs, grass_name:String, mesh:Mesh) -> void:
	conf.mesh = mesh.duplicate()
	conf.resource_name = grass_name
	conf.rotation_randomize.y = PI
	conf.size_randomize.z = 0.3



func _for_each_enabled_config(callback:Callable):
	for config in _project.grass_configs:
		if config and config.enable:
			callback.call( config )


func _for_each_config(callback:Callable):
	for config in _project.grass_configs:
		if config:
			callback.call( config )


func _create_undo_redo(brush:String) -> void:
	Landscaper.undo_redo.commit_action(false) # closes previous commits in case of errors
	Landscaper.undo_redo.create_action("godot_landscaper/grass_3d_tool/"+brush.to_snake_case())

func _commit_undo_redo() -> void:
	Landscaper.undo_redo.commit_action(false)

func _clear_undo_redo() -> void:
	Landscaper.undo_redo.commit_action(false)
	Landscaper.undo_redo.clear_history( EditorUndoRedoManager.GLOBAL_HISTORY )

func _add_redo(config:Grass3DConfigs) -> void:
	var undo_redo:EditorUndoRedoManager = Landscaper.undo_redo
	undo_redo.add_do_property( config, "top_colors", config.top_colors.duplicate() )
	undo_redo.add_do_property( config, "bottom_colors", config.bottom_colors.duplicate() )
	undo_redo.add_do_property( config, "transforms", config.transforms.duplicate() )
	undo_redo.add_do_method( config.current_brush, "rebuild" )

func _add_undo(config:Grass3DConfigs) -> void:
	var undo_redo:EditorUndoRedoManager = Landscaper.undo_redo
	undo_redo.add_undo_property( config, "top_colors", config.top_colors.duplicate() )
	undo_redo.add_undo_property( config, "bottom_colors", config.bottom_colors.duplicate() )
	undo_redo.add_undo_property( config, "transforms", config.transforms.duplicate() )
	undo_redo.add_undo_method( config.current_brush, "rebuild" )
#endregion
