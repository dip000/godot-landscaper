@tool
extends Brush
class_name GrassSpawn
# Brush that spawns grass when you paint over the terrain
# Paints different shades of gray over the "texture" depending on the grass variant, black for erase

enum {VARIANT_0, VARIANT_1, VARIANT_2, VARIANT_3, VARIANT_TOTAL}
enum {BILLBOARD_SCATTER, BILLBOARD_CROSS, BILLBOARD_Y}

@onready var density:CustomNumberInput = $Density
@onready var quality:CustomSliderUI = $Quality
@onready var gradient:CustomSliderUI = $Gradient
@onready var grass_size:CustomVector2Input = $Size
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
	billboard.on_change.connect( _on_billboard_changed )
	variants.on_change.connect( _on_variant_tabs_changed )
	density.on_change.connect( rebuild_terrain.unbind(1) )
	
	for dropbox in variants.tabs:
		dropbox.on_change.connect( _on_variant_changed )
	
	# Setup RNG as documentation suggests
	_rng.set_seed( hash("GodotLandscaper") )
	_rng_state = _rng.get_state()

func _on_gradient_change(value:float):
	_update_grass_shader("gradient_mask", _raw.gs_gradient_mask)
	_raw.gs_gradient_mask.fill_to.y = value
func _on_detail_changed(color:Color, pressed:bool):
	_update_grass_shader("detail_color", color)
	_update_grass_shader("enable_details", pressed)
func _on_quality_changed(value:float):
	_scene.grass_mesh.subdivide_depth = value
func _on_size_changed(value:Vector2):
	_scene.grass_mesh.size = value
	_scene.grass_mesh.center_offset.y = value.y*0.5 #origin rooted to the ground

func _on_billboard_changed(tab_index:int):
	var directive:String = AssetsManager.SHADER_BILLBOARD_Y
	var is_billboard_y:bool = (tab_index == BILLBOARD_Y)
	_ui.assets_manager.set_shader_directive( directive, is_billboard_y )
	rebuild_terrain()


func _on_variant_tabs_changed(tab_index:int):
	_ui.assets_manager.fix_shader_compatibility( variants.value )
	_update_grass_shader("variant_index", tab_index)
func _on_variant_changed(want_to_add:bool):
	_ui.assets_manager.fix_shader_compatibility( variants.value )
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
	_texture = raw.gs_texture
	super(ui, scene, raw)
	_resolution = raw.gs_resolution
	variants.value = raw.gs_variants
	variants.selected_tab = raw.gs_selected_variant
	density.value = raw.gs_density
	billboard.selected_tab = raw.gs_selected_billboard
	quality.value = raw.gs_quality
	gradient.value = raw.gs_gradient_value
	grass_size.value = raw.gs_size
	detail_color.enabled = raw.gs_enable_details
	detail_color.value = raw.gs_detail_color
	_on_gradient_change( gradient.value )
	_on_detail_changed( detail_color.value, detail_color.enabled )
	_on_quality_changed( quality.value )
	_on_size_changed( grass_size.value )
	_update_grass_shader("variants", variants.value)
	_ui.assets_manager.fix_shader_compatibility( variants.value )

func paint(pos:Vector3, primary_action:bool):
	# Spawn with primary key, erase with secondary
	if primary_action:
		var v:float = float(variants.selected_tab)/VARIANT_TOTAL + 0.5/VARIANT_TOTAL
		out_color = Color(v,v,v, 1.0)
	else:
		out_color = Color.BLACK
	
	# Update textures and grass positions
	_bake_out_color_into_texture( pos )
	rebuild_terrain()


func rebuild_terrain():
	# Caches
	var world_size:Vector2 = _raw.world.size
	var world_position:Vector2 = _raw.world.position
	var world_position_inv:Vector2 = _raw.MAX_BUILD_REACH*0.5 + world_position
	var spawn_size_px:Vector2 = img.get_size()
	var max_index:int = VARIANT_TOTAL - 1
	var grass_holder:Node3D = _scene.grass_holder
	var valid_variants:Array[Texture2D] = variants.value
	var max_height:float = _ui.terrain_height.max_height.value
	var builder_img = _ui.terrain_builder.img
	var total_grass = density.value * world_size.x * world_size.y
	var is_cross_billboard:bool = (billboard.selected_tab == BILLBOARD_CROSS)
	
	var space := _scene.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = 1<<(PluginLandscaper.COLLISION_LAYER_TERRAIN-1)
	
	# Reset random generator so it can spawn exactly how it previously did
	_rng.set_state( _rng_state )
	
	
	for variant_index in VARIANT_TOTAL:
		var multimesh_inst:MultiMeshInstance3D = grass_holder.get_node_or_null("Varaint%s"%variant_index)
		
		# Delete instances if variants were reduced
		if not valid_variants[variant_index]:
			if multimesh_inst:
				multimesh_inst.queue_free()
			continue
		
		# Add 'MultiMeshInstance3D' nodes if more variants were added
		elif not multimesh_inst:
			multimesh_inst = MultiMeshInstance3D.new()
			multimesh_inst.multimesh = MultiMesh.new()
			multimesh_inst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh_inst.multimesh.mesh = _scene.grass_mesh
			multimesh_inst.name = "Varaint%s"%variant_index
			
			_scene.grass_holder.add_child( multimesh_inst )
			multimesh_inst.owner = _scene.owner
		
		
		var transforms:Array[Transform3D] = []
		for _grass_index in total_grass:
			
			# Calculate all randoms to ensure full RNG restoration
			var rand := Vector2(_rng.randf(), _rng.randf())
			var random_rotation:float = _rng.randf_range( 0, 2*PI )
			var random_scale:float = _rng.randf_range( 0.8, 1.2 )
			
			# Variant found in texture. Zero/black = Nothing to spawn
			var spawn_value:float = img.get_pixelv( rand*spawn_size_px ).r
			# Either zero or one. This avoids spawning when there's no ground below
			var valid_ground:float = builder_img.get_pixelv( rand*world_size + world_position_inv ).r
			
			# Ignore non-spawns and non-current-variants
			var spawn_variant:int = roundi( spawn_value*max_index )
			if is_zero_approx( spawn_value * valid_ground ) or variant_index != spawn_variant:
				continue
			
			# Random position in XZ worldspace
			var pos_2d:Vector2 = rand * world_size + world_position
			
			# Raycast to the HeightMapShape3D to find the actual ground level (shape should've been updated in TBrushTerrainHeight)
			ray.from = Vector3(pos_2d.x, max_height+1, pos_2d.y)
			ray.to = Vector3(pos_2d.x, -max_height-1, pos_2d.y)
			var result:Dictionary = space.intersect_ray(ray)
			if not result:
				continue
			
			# Finally, we have the correct position to spawn
			var y:float = result.position.y
			var pos_3d := Vector3(pos_2d.x, y, pos_2d.y)
			var transf := Transform3D(Basis(), Vector3()).translated( pos_3d )
			
			transf = transf.rotated_local( Vector3.UP, random_rotation )
			transf = transf.scaled_local( Vector3.ONE * random_scale )
			transforms.append( transf )
		
		
		# Setup one MultiMeshInstance3D for every type of grass
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
		
