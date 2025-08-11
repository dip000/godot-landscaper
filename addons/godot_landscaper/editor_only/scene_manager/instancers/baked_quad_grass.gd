## Grass based of a quad mesh
## This Color-Bakes the painting done into each blade of grass using
## MultiMesh.use_colors and MultiMesh.use_custom_data

@tool
extends BaseInstancer
class_name BakedQuadGrass


# Managed by InspectorLandscaper
var TABS_CONFIG:Dictionary[String,Dictionary] = {
	"Spawn":{
		"info": "Left click to spawn, right click to erase",
		"icon": AtlasIcon.Icon.GRASS_SCATTER,
		"method": spawn_select,
		"hide_properties": ["primary_color", "secondary_color", "splash_height"],
	},
	"Paint":{
		"info": "left cick to paint with primary color, right click for secondary",
		"icon": AtlasIcon.Icon.COLOR,
		"method": color_select,
		"hide_properties": ["spawn_ratio", "erase_ratio", "parent_node", "quality"],
	}
}


@export_category("Actions")
## The transition between the terrain color and the top hand-painted color.
@export_range(-1.0, 1.0, 0.01) var splash_height:float = 0.0
## Grass color with left button mouse
@export var primary_color:Color = Color.MEDIUM_SEA_GREEN
## Grass color with right button mouse
@export var secondary_color:Color = Color.SADDLE_BROWN

@export var parent_node:NodePath = "."
@export_range(1.0, 10.0, 1.0, "or_greater") var spawn_ratio:float = 1.0
@export_range(0.1, 1.0, 0.1) var erase_ratio:float = 0.7
@export_range(0.0, 5.0, 1.0, "or_greater") var quality:float = 0


# Cleanly link them to the project, just so the array doesn't clutter the inspector
# Capping them to four, for fear of saturating the GPU with texture variants
@export_category("Grass Instances")
@export var grass_0:ConfigsBakedQuadGrass:
	get: return _get_instance(0)
	set(v): _set_instance(0, v)
@export var grass_1:ConfigsBakedQuadGrass:
	get: return _get_instance(1)
	set(v): _set_instance(1, v)
@export var grass_2:ConfigsBakedQuadGrass:
	get: return _get_instance(2)
	set(v): _set_instance(2, v)
@export var grass_3:ConfigsBakedQuadGrass:
	get: return _get_instance(3)
	set(v): _set_instance(3, v)


func _get_instance(index:int) -> ConfigsBakedQuadGrass:
	if not project:
		project = ProjectSaveData.new()
		project.grass_instances.resize(4)
		project.notify_property_list_changed()
	return project.grass_instances[index]

func _set_instance(index:int, inst:ConfigsBakedQuadGrass):
	project.grass_instances.resize(4)
	project.grass_instances[index] = inst
	project.notify_property_list_changed()


@export_category("Optimizations")
@export_group("Chunkify Grass")
@export var chunk_size:Vector2i = Vector2i(32,32)
@export_tool_button("     Chunkify     ", "Grid") var chunkify:Callable = _chunkify
func _chunkify():
	if chunk_size.x < 4 or chunk_size.y < 4:
		GLDebug.error("Cannot chunkify below 4 meters!")
		return
	GLDebug.state("NOT-IMPLEMENTED")
@export_tool_button("        Reset        ", "Object") var reset_chunks:Callable = _reset_chunks
func _reset_chunks():
	GLDebug.state("NOT-IMPLEMENTED")

@export_group("Visibility And Level Of Detail")
@export_range(0.0, 1.0, 0.01) var visible_instances:float = 1.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32
@export_tool_button("      Update      ", "UndoRedo") var change_visible:Callable = _change_visible
func _change_visible():
	GLDebug.state("NOT-IMPLEMENTED")


@export_category("Please, Save Files Externally")
## Where the spawned instances be hosted.
## Please save them in your file system.
@export var project := ProjectSaveData.new()

@export var debug_level:GLDebug.Level=GLDebug.Level.STATES:
	set(v): GLDebug.debug_level = v
	get: return GLDebug.debug_level

@export_range(0.1, 20, 0.1) var brush_size:float = 2.0:
	set(v):
		brush_size = v
		if Landscaper.is_enabled:
			Landscaper.scene.brush.set_scale_ratio(v)
	get:
		if Landscaper.is_enabled:
			return Landscaper.scene.brush.get_scale_ratio()
		return brush_size



# Called from InspectorLandscaper
func spawn_select():
	GLDebug.internal("Selected Spawn")
	for instance in project.grass_instances:
		if instance:
			instance.current_action = instance.spawn_action

func color_select():
	GLDebug.internal("Selected Color")
	for instance in project.grass_instances:
		if instance:
			instance.current_action = instance.color_action


# Called from the main Landscaper class using TABS_CONFIG
func action_start():
	if not _validate_action():
		return
		
	Landscaper.undo_redo.create_action("godot_landscaper/baked_quad_grass", UndoRedo.MERGE_DISABLE)
	for instance in project.grass_instances:
		if instance and instance.enable:
			instance.current_action.start( self, project, instance )


func action_primary(hit_info:Dictionary):
	GLDebug.spam("Painting with primary at: %s" %hit_info.position)
	for instance in project.grass_instances:
		if instance and instance.enable:
			instance.current_action.primary( hit_info )


func action_secondary(hit_info:Dictionary):
	GLDebug.spam("Painting with secondary at: %s" %hit_info.position)
	for instance in project.grass_instances:
		if instance and instance.enable:
			instance.current_action.secondary( hit_info )


func action_end():
	for instance in project.grass_instances:
		if instance and instance.enable:
			instance.current_action.end()
	Landscaper.undo_redo.commit_action(false)


func _validate_action() -> bool:
	if parent_node.is_empty():
		GLDebug.warning("Parent Holder was empty. Using this node instead")
		parent_node = "."
	
	var parent:Node = get_node_or_null( parent_node )
	if not parent:
		GLDebug.warning("Parent Node '%s' is invalid. Using this node instead")
		parent_node = "."
		parent = self
	
	var any_exists:bool = false
	var any_enable:bool = false
	var grass_textures:Array[Texture2D]=[null, null, null, null]
	var details_enable:PackedInt32Array=[0, 0, 0, 0]
	var detail_colors:Array[Color]=[Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK]
	
	for i in project.grass_instances.size():
		var instance:ConfigsBakedQuadGrass = project.grass_instances[i]
		if not instance:
			continue
		
		# Make sure there are MultiMeshInstance3D
		var mmi:MultiMeshInstance3D = SceneManager.find_or_create_node(MultiMeshInstance3D, parent, instance.resource_name)
		if not mmi.multimesh:
			mmi.multimesh = MultiMesh.new()
			mmi.multimesh.use_colors = true
			mmi.multimesh.use_custom_data = true
			mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mmi.multimesh.mesh = project.mesh
		mmi.set_instance_shader_parameter("variant_index", i)
		
		grass_textures[i] = instance.grass_texture
		details_enable[i] = int(instance.detail_enable)
		detail_colors[i] = instance.detail_color
		
		any_exists = true
		
		# Don't check if it is not enabled to avoid spamming
		if not instance.enable:
			continue
		
		if instance.resource_name.is_empty():
			GLDebug.warning("'Grass %s' doesn't have a resource_name. Using 'Grass %s' as its Node name" %[i,i])
			instance.resource_name = "Grass %s" %i
		
		any_enable = true
		
		if not instance.grass_texture:
			GLDebug.warning("No Grass Texture is selected for '%s'" %instance.resource_name)
		
		if is_zero_approx( instance.size_base.x*instance.size_base.y*instance.size_base.z ):
			GLDebug.warning("Grass volume is zero. Used Vector3.ONE")
			instance.size_base = Vector3.ONE
	
	
	if not any_exists:
		GLDebug.warning("No grass to spawn. Using template configs")
		grass_0 = AssetsManager.grass.configs0.duplicate()
		grass_1 = AssetsManager.grass.configs1.duplicate()
		grass_2 = AssetsManager.grass.configs2.duplicate()
	
	
	if not any_enable:
		GLDebug.warning("No grass is enabled. Enable at least one to start or deselect Landscaper node")
	
	
	# Force fill project dependencies
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
		resources_added += "Grass Mesh, "
	project.mesh.material = project.material
	
	if resources_added:
		GLDebug.warning("The following resources were added: %s" %resources_added)
	
	# Update shader parameters
	project.material.set_shader_parameter("splash_height", splash_height)
	project.material.set_shader_parameter("grass_textures", grass_textures)
	project.material.set_shader_parameter("details_enable", details_enable)
	project.material.set_shader_parameter("detail_colors", detail_colors)
	
	project.mesh.subdivide_depth = quality
	project.mesh.center_offset.z = -project.mesh.size.y*0.5
	return true
