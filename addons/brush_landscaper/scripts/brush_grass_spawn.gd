@tool
extends Brush
class_name GrassSpawn
# Brush that spawns grass when you paint over the terrain
# Paints different shades of gray over the "texture" depending on the grass variant

enum {VARIANT_0, VARIANT_1, VARIANT_2, VARIANT_3, VARIANT_RANDOM}
enum {BILLBOARD_SCATTER, BILLBOARD_CROSS, BILLBOARD_Y}

@onready var density:CustomNumberInput = $Density
@onready var quality:CustomSliderUI = $Quality
@onready var gradient:CustomSliderUI = $Gradient
@onready var grass_size:CustomVectorInput = $Size
@onready var detail_color:CustomColorPicker = $DetailColor
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
		dropbox.on_change.connect( _on_variant_changed.bind(dropbox.get_index()) )
	
	# Setup RNG as documentation suggests
	_rng.set_seed( hash("TerraBrush") )
	_rng_state = _rng.get_state()

func _on_gradient_change(value:float):
	_update_grass_shader("gradient_mask", _raw.gs_gradient_mask)
	_raw.gs_gradient_mask.fill_to.y = value
func _on_detail_changed(color:Color, pressed:bool):
	_update_grass_shader("detail_color", color)
	_update_grass_shader("enable_details", pressed)
func _on_quality_changed(value:float):
	_scene.grass_mesh.subdivide_depth = value*10
func _on_size_changed(value:Vector2):
	_scene.grass_mesh.size = value
	_scene.grass_mesh.center_offset.y = value.y*0.5 #origin rooted to the ground

func _on_variant_changed(want_to_add:bool, variant_index:int):
	var multimesh_inst:MultiMeshInstance3D = _scene.grass_holder.get_node_or_null("GrassVaraint%s"%variant_index)
	
	# Delete instances if variants were reduced
	if not want_to_add:
		if multimesh_inst:
			multimesh_inst.queue_free()
		return
	
	# Add MultiMeshInstance3D nodes if more variants were added
	elif not multimesh_inst:
		multimesh_inst = MultiMeshInstance3D.new()
		multimesh_inst.multimesh = MultiMesh.new()
		multimesh_inst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh_inst.multimesh.mesh = _scene.grass_mesh
		multimesh_inst.name = "GrassVaraint%s"%variant_index
		
		_scene.grass_holder.add_child( multimesh_inst )
		multimesh_inst.owner = _scene.owner
	
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
	_on_detail_changed( detail_color.value, detail_color.enabled )
	_on_quality_changed( quality.value )
	_on_size_changed( grass_size.value )
	_update_grass_shader("variants", variants.value)

func paint(pos:Vector3, primary_action:bool):
	# Spawn with primary key, erase with secondary
	if primary_action:
		if variants.selected_tab == VARIANT_RANDOM:
			out_color = Color.WHITE
		else:
			var v:float = float(variants.selected_tab)/VARIANT_RANDOM + 0.5/VARIANT_RANDOM
			out_color = Color(v,v,v, 1.0)
	else:
		out_color = Color.BLACK
	
	# Update textures and grass positions
	_bake_out_color_into_texture( pos )
	rebuild_terrain()


func rebuild_terrain():
	# Caches
	var spawn_img:Image = _texture.get_image()
	var bounds_size:Vector2 = _ui.terrain_builder.bounds_size
	var world_offset:Vector2 = _raw.world_offset
	var spawn_size_px:Vector2 = spawn_img.get_size()
	var max_index:int = VARIANT_RANDOM - 1
	var grass_holder:Node3D = _scene.grass_holder
	var valid_variants:Array[Texture2D] = variants.value
	var max_height:float = _ui.terrain_height.max_height.value
	var builder_img = _ui.terrain_builder.get_texture().get_image()
	var total_grass = density.value * bounds_size.x * bounds_size.y
	var is_cross_billboard:bool = (billboard.selected_tab == BILLBOARD_CROSS)
	
	var space := _scene.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = 1<<(PluginLandscaper.COLLISION_LAYER_TERRAIN-1)
	
	var transforms_variants:Array[Array] = []
	var multimesh_instances:Array[MultiMeshInstance3D] = []
	transforms_variants.resize( VARIANT_RANDOM )
	multimesh_instances.resize( VARIANT_RANDOM )
	
	# Reset random generator so it can spawn exactly where it previously did
	_rng.set_state(_rng_state)
	
	
	# Rebuild for every variant of grass
	for variant_index in VARIANT_RANDOM:
		if not valid_variants[variant_index]:
			continue
		
		var multimesh_inst:MultiMeshInstance3D = grass_holder.get_node_or_null("GrassVaraint%s"%variant_index)
		multimesh_instances[variant_index] = multimesh_inst
		
		# Calculate transforms for each grass
		for _grass_index in total_grass:
			
			# Always calculate randoms to ensure full state restoration from RandomNumberGenerator
			var rand := Vector2(_rng.randf(), _rng.randf())
			var random_rotation:float = _rng.randf_range( 0, 2*PI )
			var random_scale:float = _rng.randf_range( 0.8, 1.2 )
			var spawn_variant = _rng.randf_range( 0, VARIANT_RANDOM )
			
			# "spawn_value" is the variant found. Zero/black = Nothing to spawn
			# "valid_ground" is either zero or one. This avoids spawning when there's no ground below
			var spawn_value:float = spawn_img.get_pixelv( rand*spawn_size_px ).r
			var valid_ground:float = builder_img.get_pixelv( rand*bounds_size ).r
			if is_zero_approx( spawn_value * valid_ground ):
				continue
			
			# GRAYSCALE = Spawn variant
			if spawn_value < 1.0:
				spawn_variant = roundi( spawn_value*max_index )
			
			# Random position in worldspace
			var world_pos:Vector2 = rand * bounds_size + world_offset
			
			# Raycast to the HeightMapShape3D to find the actual ground level (shape should've been updated in TBrushTerrainHeight)
			ray.from = Vector3(world_pos.x, max_height+1, world_pos.y)
			ray.to = Vector3(world_pos.x, -max_height-1, world_pos.y)
			var y:float = space.intersect_ray(ray).position.y
			
			# Finally, we have the correct position to spawn
			var pos_3d := Vector3(world_pos.x, y, world_pos.y)
			var transf := Transform3D(Basis(), Vector3()).translated( pos_3d )
			
			transf = transf.rotated_local( Vector3.UP, random_rotation )
			transf = transf.scaled_local( Vector3.ONE * random_scale )
			transforms_variants[spawn_variant].append( transf )
	
	
	for variant_index in VARIANT_RANDOM:
		if not valid_variants[variant_index]:
			continue
		
		# Setup one MultiMeshInstance3D for every type of grass
		var multimesh_inst:MultiMeshInstance3D = multimesh_instances[variant_index]
		var transforms:Array = transforms_variants[variant_index]
		var transforms_size:int = transforms.size()
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		multimesh_inst.multimesh.instance_count = transforms_size*2 if is_cross_billboard else transforms_size
		
		# Spawn the actual grass with calculated transforms
		for transform_index in transforms_size:
			var transform:Transform3D = transforms[transform_index]
			multimesh_inst.multimesh.set_instance_transform( transform_index, transform )
			
			if is_cross_billboard:
				transform = transform.rotated_local( Vector3.UP, PI*0.5 )
				multimesh_inst.multimesh.set_instance_transform( transforms_size+transform_index, transform )
		



