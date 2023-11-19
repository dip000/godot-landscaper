@tool
extends Brush
class_name GrassSpawn
# Brush that spawns grass when you paint over the terrain
# Paints different shades of gray over the "texture" depending on the grass variant

enum {VARIANT_1, VARIANT_2, VARIANT_3, VARIANT_4, VARIANT_TOTAL}
enum {BILLBOARD_SCATTER, BILLBOARD_CROSS, BILLBOARD_Y}

@onready var density:CustomNumberInput = $Density
@onready var quality:CustomNumberInput = $Quality
@onready var gradient:CustomSliderUI = $Gradient
@onready var grass_size:CustomVectorInput = $Size
@onready var detail_color:CustomColorPickerEnable = $DetailColor
@onready var variants:CustomTabs = $Variants
@onready var billboard:CustomTabs = $Billboard

# To re-create the same series of spawn positions
var _rng := RandomNumberGenerator.new()
var _rng_state:int


func _ready():
	# UI events
	gradient.on_change.connect( _on_gradient_change )
	detail_color.on_change.connect( _on_detail_changed )
	quality.on_change.connect( _on_quality_changed )
	grass_size.on_change.connect( _on_size_changed )
	density.on_change.connect( rebuild_terrain.unbind(1) )
	billboard.on_change.connect( rebuild_terrain.unbind(1) )
	
	for dropbox in variants.tabs:
		dropbox.on_change.connect( _on_variant_changed )
	
	# Setup RNG as documentation suggests
	_rng.set_seed( hash("TerraBrush") )
	_rng_state = _rng.get_state()

func _on_gradient_change(value:float):
	_update_grass_shader("gradient_mask", _raw.gs_gradient_mask)
	_raw.gs_gradient_mask.fill_to.y = value
func _on_detail_changed(color:Color):
	_update_grass_shader("enable_details", true)
	_update_grass_shader("detail_color", color)
func _on_quality_changed(value:float):
	_scene.grass_mesh.subdivide_depth = value
func _on_size_changed(value:Vector2):
	_scene.grass_mesh.size = value
	_scene.grass_mesh.center_offset.y = value.y*0.5 #origin rooted to the ground
func _on_variant_changed(_icon:Texture2D):
	_update_grass_shader("variants", variants.value)
	rebuild_terrain()


func save_ui():
	_raw.gs_texture = _texture
	_raw.gs_resolution = _resolution
	_raw.gs_variants = variants.value
	_raw.gs_selected_variant = variants.selected_tab
	_raw.gs_density = density.value
	_raw.gs_selected_billboard = billboard.selected_tab
	_raw.gs_quality = quality.value
	_raw.gs_gradient_value = gradient.value
	_raw.gs_size = grass_size.value
	_raw.gs_detail_color = detail_color.value
	_raw.gs_enable_details = detail_color.enabled
	
func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	super(ui, scene, raw)
	_texture = _raw.gs_texture
	_resolution = _raw.gs_resolution
	variants.value = _raw.gs_variants
	variants.selected_tab = _raw.gs_selected_variant
	density.value = _raw.gs_density
	billboard.selected_tab = _raw.gs_selected_billboard
	quality.value = _raw.gs_quality
	gradient.value = _raw.gs_gradient_value
	grass_size.value = _raw.gs_size
	detail_color.enabled = _raw.gs_enable_details
	detail_color.value = _raw.gs_detail_color
	_preview_texture()
	_on_gradient_change( gradient.value )
	_on_detail_changed( detail_color.value )
	_on_quality_changed( quality.value )
	_on_size_changed( grass_size.value )
	_update_grass_shader("variants", variants.value)

func paint(pos:Vector3, primary_action:bool):
	# Spawn with primary key, erase with secondary
	if primary_action:
		if variants.selected_tab == VARIANT_TOTAL:
			out_color = Color.WHITE
		else:
			var v:float = float(variants.selected_tab)/VARIANT_TOTAL + 0.5/VARIANT_TOTAL
			out_color = Color(v,v,v, 1.0)
	else:
		out_color = Color.BLACK
	
	# Update textures and grass positions
	_bake_out_color_into_texture( pos )
	rebuild_terrain()


func rebuild_terrain():
	# Caches
	var spawn_img:Image = _texture.get_image()
	var terrain_size_m:Vector2 = _ui.terrain_builder.bounds_size
	var spawn_size_px:Vector2 = spawn_img.get_size()
	var max_index:int = VARIANT_TOTAL - 1
	var grass_holder:Node3D = _scene.grass_holder
	var valid_variants:Array[Texture2D] = variants.value
	var max_height:float = _ui.terrain_height.max_height.value
	var space := _scene.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = 1<<(PluginLandscaper.COLLISION_LAYER_TERRAIN-1)
	
	var multimesh_instances:Array[MultiMeshInstance3D] = []
	multimesh_instances.resize( VARIANT_TOTAL )
	
	for variant_index in VARIANT_TOTAL:
		var multimesh_inst:MultiMeshInstance3D = grass_holder.get_node_or_null("GrassVaraint%s"%variant_index)
		var variant:Texture2D = valid_variants[variant_index]
		
		# Reset current valid instances
		if multimesh_inst and variant:
			multimesh_instances[variant_index] = multimesh_inst
			multimesh_inst.multimesh.instance_count = 0
		
		# Add instances if more variants were added
		elif not multimesh_inst and variant:
			var new_instance := MultiMeshInstance3D.new()
			new_instance.multimesh = MultiMesh.new()
			new_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			new_instance.multimesh.mesh = _scene.grass_mesh
			new_instance.name = "GrassVaraint%s"%variant_index
			
			_scene.grass_holder.add_child( new_instance )
			multimesh_instances[variant_index] = new_instance
			new_instance.owner = _scene.owner
		
		# Delete instances if variants were reduced
		elif multimesh_inst and not variant:
			multimesh_inst.queue_free()
	
	
	# Reset random generator so it can spawn exactly where it previously did
	_rng.set_state(_rng_state)
	
	# Find all actual valid places to spawn
	var transforms_variants:Array[Array] = []
	transforms_variants.resize( VARIANT_TOTAL )
	
	for _i in density.value:
		# Get pixel value in random position
		var rand := Vector2(_rng.randf(), _rng.randf())
		var terrain_value:float = spawn_img.get_pixelv( rand*spawn_size_px ).r
		
		# WHITE = Spawn random variants
		# Always calculate randoms to ensure full state restoration from RandomNumberGenerator
		var variant_index:int = _rng.randi_range(0, max_index)
		var random_rotation:float = _rng.randf_range(0, 2*PI)
		var random_scale:float = _rng.randf_range(0.8, 1.2)
		
		# BLACK = Erase
		if is_zero_approx(terrain_value) or not valid_variants[variant_index]:
			continue
		
		# GRAYSCALE = Spawn variant
		if terrain_value < 1.0:
			variant_index = roundi( terrain_value*max_index )
		
		# Meters from the center of the texture
		var x_m:float = (rand.x) * terrain_size_m.x + _raw.world_offset.x
		var z_m:float = (rand.y) * terrain_size_m.y + _raw.world_offset.y
		
		# Raycast to the HeightMapShape3D to find the actual ground level (shape should've been updated in TBrushTerrainHeight)
		ray.from = Vector3(x_m, max_height+1, z_m)
		ray.to = Vector3(x_m, -max_height-1, z_m)
		var result:Dictionary = space.intersect_ray(ray)
		if not result:
			print(ray.from, ray.to)
			continue
		var y_m:float = result.position.y
		
		# Finally, we have the correct position to spawn
		var pos := Vector3(x_m, y_m, z_m)
		var transf := Transform3D(Basis(), Vector3()).translated( pos )
		
		transf = transf.rotated_local( Vector3.UP, random_rotation )
		transf = transf.scaled_local( Vector3.ONE * random_scale )
		transforms_variants[variant_index].append( transf )
	
	
	# Setup one MultiMeshInstance3D for every type of grass
	for variant_index in transforms_variants.size():
		if not valid_variants[variant_index]:
			continue
		
		var multimesh_inst := multimesh_instances[variant_index]
		var transforms := transforms_variants[variant_index]
		var transforms_size:int = transforms.size()
		var is_cross_billboard:bool = (billboard.selected_tab == BILLBOARD_CROSS)
		
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		multimesh_inst.multimesh.instance_count = transforms_size*2 if is_cross_billboard else transforms_size
		
		# Spawn the actual grass
		for transform_index in transforms_size:
			var transform:Transform3D = transforms[transform_index]
			multimesh_inst.multimesh.set_instance_transform( transform_index, transform )
		
		# Spawn the cross billboard grass rotated 90 degrees in the same position
		if is_cross_billboard:
			for transform_index in transforms_size:
				var transform:Transform3D = transforms[transform_index].rotated_local( Vector3.UP, PI*0.5 )
				multimesh_inst.multimesh.set_instance_transform( transforms_size + transform_index, transform )
		

# Spawn new grass where the texture was extended
func extend_texture(min:Vector2i, max:Vector2i):
	super(min, max)
	rebuild_terrain()


