@tool
@icon("res://addons/godot_landscaper/scene_element/grass/grass_icon.svg")
extends SceneElement
class_name Grass3D

#region Tab
var TABS_CONFIG:Array[InspectorTab] = [
	preload(AssetsManager.SPAWN_TAB),
	preload(AssetsManager.PAINT_TAB),
]
var CURRENT_TAB:InspectorTab = TABS_CONFIG[0]
#endregion


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
	set(v): set_shader_parameter("splash_height", v)
	get: return get_shader_parameter("splash_height", 0.0)

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


#region ToolButtons
@export_category("Control")
@export_tool_button("        Rebuild        ", "Object") var _rebuild:Callable = stroke_rebuild
@export_tool_button("           Clear          ", "UndoRedo") var _clear:Callable = stroke_clear
#endregion


#region SaveData
# Rebuild data. Shared between grass actions.
# Tools might override scene instances for these in case there's a missmatch
@export_category("Save Data")
@export var save_data:GLSaveData
#endregion

#region SaveData
@export_category("Executables")
@export var chunkify:ExecMMIChunkify = ExecMMIChunkify.new()
@export var level_of_detail:ExecMMILoD = ExecMMILoD.new()
@export var rescan_colors:ExecMMIRescanColor = ExecMMIRescanColor.new()
@export var rescan_ground_level:ExecMMIRescanLevel = ExecMMIRescanLevel.new()
#endregion


# Strokes are where the actual landscaping happens.
var spawn_brush:ActionMMISpawn = ActionMMISpawn.new()
var paint_brush:ActionMMIColor = ActionMMIColor.new()
var current_brush:Brush = spawn_brush

var mmi:MultiMeshInstance3D


func _ready():
	super()
	load_random_template()

func select_brush(brush_name:String):
	current_brush = get(brush_name)
	_notify_property_list_changed_once()
	GLDebug.internal("Selected: %s/%s" %[name, brush_name])

## Start landscaping according to the current brush
func stroke_start(hit_info:Dictionary):
	if not anchor_node:
		anchor_node = Scanner.scan_mesh( hit_info.collider, parent_of_physics_body, relative_path_from_physics_body)
		if not anchor_node:
			GLDebug.warning("There's no anchor node. Add one under 'Brushes' category")
			return
	if not save_data:
		save_data = GLSaveData.new()
		load_template()
		GLDebug.warning("Created Save Data and loaded a template. You can save, load or use your own resources from 'save_data'")
	if chunkify and chunkify.is_chunkified(self):
		chunkify._reset_executable()
	fix_dependencies()
	_create_undo_redo("stroke")
	_add_undo(save_data)
	current_brush.start(hit_info)

func stroke_primary(hit_info:Dictionary):
	current_brush.primary(hit_info)

func stroke_secondary(hit_info:Dictionary):
	current_brush.secondary(hit_info)

func stroke_end():
	current_brush.end()
	_add_redo(save_data)
	_commit_undo_redo()


## Clean up or rebuild in the scene tree or otherwise
func stroke_clear():
	queue_free()
	if not anchor_node:
		GLDebug.warning("Clearing needs an Anchor Node as reference. Set Anchor node from the main CanvasScatterer class node")
		return
	
	var instances:int = save_data.transforms.size()
	save_data.transforms.clear()
	save_data.top_colors.clear()
	save_data.bottom_colors.clear()
	if mmi and is_instance_valid(mmi): mmi.queue_free()
	GLDebug.state("Instances Cleared: %s" %instances)
	

func stroke_rebuild():
	if not anchor_node:
		GLDebug.warning("Rebuilding needs an Anchor Node as reference. Set Anchor node from the main CanvasScatterer class node")
		return
	
	fix_dependencies()
	current_brush.rebuild()
	var instances:int = save_data.transforms.size()
	GLDebug.state("Instances Rebuilt: %s" %instances)


func load_template():
	save_data.size_randomize.y = randf_range(0.2, 0.6)
	save_data.size_base.y = randf_range(0.8, 1.4)
	save_data.rotation_randomize.y = PI

func fix_dependencies():
	# Create resources if needed
	if save_data.enable_textures and not save_data.texture:
		GLDebug.warning("You have enabled textures, but not selected one")
	if not save_data.shader:
		save_data.shader = AssetsManager.grass.shader
	if not save_data.material:
		save_data.material = AssetsManager.grass.material
	if not save_data.mesh:
		save_data.mesh = AssetsManager.grass.mesh_3d_single
	
	# Force set values just in case
	save_data.material.shader = save_data.shader
	save_data.mesh.surface_set_material( 0, save_data.material )
	set_shader_parameter("details_enable", save_data.enable_details as int, save_data.instance_index)
	set_shader_parameter("detail_colors", save_data.detail_color, save_data.instance_index)
	set_shader_parameter("enable_textures", save_data.enable_textures as int, save_data.instance_index)
	set_shader_parameter("splash_height", splash_height)
	if save_data.enable_textures:
		set_shader_parameter("grass_texture_array", format_texture_array())
	
	# Force set references
	if anchor_node:
		mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, anchor_node, name)
		mmi.set_instance_shader_parameter("variant_index", save_data.instance_index)
		if not mmi.multimesh:
			mmi.multimesh = MultiMesh.new()
			mmi.multimesh.use_colors = true
			mmi.multimesh.use_custom_data = true
			mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mmi.multimesh.mesh = save_data.mesh
		current_brush.mmi = mmi
	
	current_brush.save_data = save_data
	current_brush.grass = self


## [TODO] Keep track of instance_index globaly so this can work on the background
## Generates a dynamic, compatibility-friendly, and performant array of textures
func format_texture_array() -> Texture2DArray:
	var tex_array:Texture2DArray = save_data.material.get_shader_parameter("grass_texture_array")
	var texture:Texture2D = save_data.texture
	if not texture:
		return tex_array
	if not tex_array:
		tex_array = Texture2DArray.new()
	
	var instance_index:int = save_data.instance_index
	var layers:int = tex_array.get_layers()
	var layer_max_index:int = layers-1
	var variant_img:Image = texture.get_image()
	format_img(variant_img)
	
	# Make room for new texture
	if instance_index > layer_max_index:
		var new_max_length:int = instance_index+1
		var current_images:Array[Image]
		current_images.resize(new_max_length)
		for layer in new_max_length:
			if layer < layers:
				# [WARNING] This might return on format Image.FORMAT_RGBA8 unexpectedly
				current_images[layer] = tex_array.get_layer_data(layer)
				GLDebug.spam("Current layer data array format: %s, img format: %s" %[tex_array.get_format(), current_images[layer].get_format()])
			elif layer == instance_index:
				GLDebug.spam("Selected variant on layer: %s of format: %s" %[layer, variant_img.get_format()])
				current_images[layer] = variant_img
			else: #fill empty slots
				GLDebug.spam("Filled layer: %s with format: %s" %[layer, Image.FORMAT_LA8])
				current_images[layer] = Image.create_empty(255, 255, true, Image.FORMAT_LA8)
				current_images[layer].fill(Color.BLACK)
			format_img( current_images[layer] )
		tex_array.create_from_images(current_images)
		GLDebug.internal("Updated tex_array: %s. new_max_length: %s" %[tex_array, new_max_length])
	
	else: # If it fits, it sits
		GLDebug.internal("variant_img format: %s, tex_array format: %s" %[variant_img.get_format(), tex_array.get_format()])
		tex_array.update_layer(variant_img, instance_index)
	return tex_array


func format_img(img:Image):
	if img.is_compressed():
		GLDebug.internal("Decompression: %s" %img.decompress())
	if img.get_size() != Vector2i(255, 255):
		img.resize(255, 255)
	if not img.has_mipmaps():
		img.generate_mipmaps()
	var err:int = img.compress_from_channels(Image.COMPRESS_ETC2, Image.USED_CHANNELS_LA)


func load_random_template():
	var grass_db:Dictionary[String,Object] = AssetsManager.grass
	save_data = GLSaveData.new()
	match range(4).pick_random():
		0: # 3D single
			save_data.mesh = grass_db.mesh_3d_single
			save_data.size_base = Vector3.ONE * randf_range(0.3, 0.8)
			save_data.size_randomize = Vector3.ONE * randf_range(0.1, 0.5)
			save_data.instance_index = 31
			name = "Grass3DSingles"
		1: # 3D Foxtail
			save_data.mesh = grass_db.mesh_3d_foxtail
			save_data.instance_index = 31
			save_data.size_base = Vector3.ONE * randf_range(1.0, 1.5)
			save_data.size_randomize = Vector3.ONE * randf_range(0.5, 0.8)
			name = "Grass3DFoxtails"
		2: # Textured Quad
			save_data.mesh = grass_db.mesh_textured_quad
			save_data.enable_textures = true
			save_data.texture = grass_db.texture_quad
			save_data.size_base = Vector3.ONE * randf_range(0.3, 0.8)
			save_data.size_randomize = Vector3.ONE * randf_range(0.1, 0.5)
			name = "Grass3DQuads"
		3: # Textured PolyQuad
			save_data.mesh = grass_db.mesh_textured_polyquad
			save_data.enable_textures = true
			save_data.texture = grass_db.texture_polyquad
			save_data.enable_details = true
			save_data.detail_color = Color.DARK_SLATE_GRAY
			save_data.size_base = Vector3.ONE * randf_range(1.0, 1.5)
			save_data.size_randomize = Vector3.ONE * randf_range(0.5, 0.8)
			name = "Grass3DPolyquads"
	save_data.rotation_randomize.y = PI
	fix_dependencies()

func get_shader_parameter(param:String, default:Variant, index:int=-1) -> Variant:
	var full_param:String = "shader_parameter/%s" %param
	if full_param in save_data.material:
		if index >= 0:
			return save_data.material[full_param][index]
		else:
			return save_data.material[full_param]
	GLDebug.warning("Shader of '%s' failed getting parameter %s" % [name, param])
	return default

func set_shader_parameter(param:String, value:Variant, index:int=-1):
	var full_param:String = "shader_parameter/%s" %param
	if full_param in save_data.material:
		if index >= 0:
			save_data.material[full_param][index] = value
		else:
			save_data.material[full_param] = value
	else:
		GLDebug.warning("Shader of '%s' failed setting parameter %s=%s" % [name, param, value])
