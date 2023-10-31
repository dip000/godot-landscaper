@tool
extends TBrush
class_name TBrushGrassSpawn
# Brush that spawns grass when you paint over the terrain
# Paints different shades of gray over the "texture" depending on the grass variant


enum SpawnType {SPAWN_ONE_VARIANT, SPAWN_RANDOM_VARIANTS}
enum BillboardType {BILLBOAD_Y, CROSS_BILLBOARD, SCATTER}

## Action to perform while left-clicking over the terrain. Right click will clear grass
@export var spawn_type:SpawnType = SpawnType.SPAWN_RANDOM_VARIANTS:
	set(v):
		spawn_type = v
		set_active( true )

## Grass variant from "variants" property (below "Grass Settings"). Only if you selected mode SPAWN_ONE_VARIANT
@export var variant:int = 0:
	set(v):
		variant = clampi(v, 0, max(0, variants.size()-1))
		set_active( true )

## Amount of grass proportional to the whole surface
@export var density:int = 1024:
	set(v):
		density = v
		set_active( true )
		populate_grass()

@export_group("Grass Settings")

## BILLBOAD_Y: Grass always looks at the camera in y-axis.
## CROSS_BILLBOARD: For each grass instance, spawns another grass 90 degrees in the same position.
## SCATTER Scatters the grass with random rotations
@export var billboard := BillboardType.SCATTER:
	set(v):
		billboard = v
		set_active( true )
		if tb:
			match billboard:
				BillboardType.BILLBOAD_Y:
					tb.grass_mesh.material.shader = AssetsManager.GRASS_SHADER_BILLBOARD_Y.duplicate() 
				BillboardType.CROSS_BILLBOARD:
					tb.grass_mesh.material.shader = AssetsManager.GRASS_SHADER_DOUBLE_SIDE.duplicate() 
				BillboardType.SCATTER:
					tb.grass_mesh.material.shader = AssetsManager.GRASS_SHADER_DOUBLE_SIDE.duplicate() 
			populate_grass()

## If it should recolor the details you may have used in your variant texture.
## Remember that variant textures must be white and their details black
@export var enable_details := true:
	set(v):
		enable_details = v
		_update_grass_shader("enable_details", enable_details)
		set_active( true )

## Detail recolor. See margin_enable
@export var detail_color := Color(0.2, 0.2, 0.2):
	set(v):
		detail_color = v
		_update_grass_shader("detail_color", detail_color)
		set_active( true )

## Subdivisions for each blade of grass. This affects its sway animation and gradient color smoothess (because is vertex colored)
@export var quality:int:
	set(v):
		quality = max(0, v)
		set_active( true )
		if tb:
			tb.grass_mesh.subdivide_depth = quality

## Size of the average blade of grass in meters
@export var size:Vector2:
	set(v):
		size = v
		set_active( true )
		if tb:
			tb.grass_mesh.size = size
			tb.grass_mesh.center_offset.y = size.y/2 #origin rooted to the ground

## The color mix from the grass roots to the top as seen from the front. BLACK=terrain_color and WHITE=grass_color
@export var gradient_mask:GradientTexture2D:
	set(v):
		gradient_mask = v
		set_active( true )
		_update_grass_shader("gradient_mask", gradient_mask)

## Adding or deleting a new variant might remap your current variant placements
@export var variants:Array[Texture2D]:
	set(v):
		variants = v
		set_active( true )
		_update_grass_shader("variants", variants)
		populate_grass()


# To re-create the same series of spawn positions
var _rng := RandomNumberGenerator.new()
var _rng_state:int


func setup():
	resource_name = "grass_spawn"
	# Setup RNG as documentation suggests
	_rng.set_seed( hash("TerraBrush") )
	_rng_state = _rng.get_state()

func template(map_size:Vector2i):
	variants = [
		AssetsManager.DEFAULT_GRASS_VARIANT1.duplicate(),
		AssetsManager.DEFAULT_GRASS_VARIANT2.duplicate(),
	]
	size = Vector2(0.3, 0.3)
	quality = 3
	gradient_mask = AssetsManager.DEFAULT_GRASS_GRADIENT.duplicate()
	set_texture_resolution( 10 )
	set_texture( _create_texture(Color.BLACK, map_size*texture_resolution) )

func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active:
		return
	
	# Spawn with primary key, erase with secondary
	if primary_action:
		match spawn_type:
			SpawnType.SPAWN_ONE_VARIANT:
				# Middleground between variant color range
				var v:float = float(variant)/variants.size() + 0.5/variants.size()
				out_color = Color(v,v,v, 1.0)
			SpawnType.SPAWN_RANDOM_VARIANTS:
				out_color = Color.WHITE
	else:
		out_color = Color.BLACK
	
	# Update textures and grass positions
	_bake_brush_into_surface(scale, pos)
	on_texture_update()


func on_texture_update():
	populate_grass()


func populate_grass():
	if not texture or variants.is_empty():
		return
	
	# Caches
	var terrain_image:Image = texture.get_image()
	var terrain_size_m:Vector2 = tb.terrain_mesh.size
	var terrain_size_px:Vector2 = terrain_image.get_size()
	var total_variants:int = variants.size()
	var max_index:int = total_variants - 1
	var max_height:float = tb.terrain_height.max_height
	var space := tb.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = 1<<(MainPlugin.COLLISION_LAYER-1)
	
	
	# Reset previous instances
	var multimesh_instances:Array[MultiMeshInstance3D] = []
	for multimesh_inst in tb.grass_holder.get_children():
		multimesh_instances.append( multimesh_inst )
		multimesh_inst.multimesh.instance_count = 0
	
	# Add instances if more variants were added
	if multimesh_instances.size() < total_variants:
		for variant_index in total_variants - multimesh_instances.size():
			var new_instance := MultiMeshInstance3D.new()
			new_instance.multimesh = MultiMesh.new()
			new_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			new_instance.multimesh.mesh = tb.grass_mesh
			multimesh_instances.append( new_instance )
			
			tb.grass_holder.add_child( new_instance )
			new_instance.owner = tb.owner
			new_instance.name = "Grass"
	
	# Delete instances if variants were reduced
	else:
		for _variant_index in multimesh_instances.size() - total_variants:
			multimesh_instances.pop_back().queue_free()
	
	# Reset random generator so it can spawn exactly where it previously did
	_rng.set_state(_rng_state)
	
	# Find all actual valid places to spawn
	var transforms_variants:Array[Array] = []
	transforms_variants.resize(total_variants)
	
	for _i in density:
		# Get pixel value in random position
		var rand := Vector2(_rng.randf(), _rng.randf())
		var terrain_value:float = terrain_image.get_pixelv( rand*terrain_size_px ).r
		
		# WHITE = SPAWN_RANDOM_VARIANTS (always calculate randoms to ensure full state restoration from RandomNumberGenerator)
		var variant_index:int = _rng.randi_range(0, max_index)
		var random_rotation:float = _rng.randf_range(0, 2*PI)
		var random_scale:float = _rng.randf_range(0.8, 1.2)
		
		# BLACK = CLEAR
		if is_zero_approx(terrain_value):
			continue
		
		# SPAWN_ONE_VARIANT
		if terrain_value < 1.0:
			variant_index = roundi( terrain_value*max_index )
		
		# Meters from the center of the texture
		var x_m:float = (rand.x - 0.5) * terrain_size_m.x
		var z_m:float = (rand.y - 0.5) * terrain_size_m.y
		
		# Raycast to the HeightMapShape3D to find the actual ground level (shape should've been updated in TBrushTerrainHeight)
		ray.from = Vector3(x_m, max_height+1, z_m)
		ray.to = Vector3(x_m, -max_height-1, z_m)
		var y_m:float = space.intersect_ray(ray).position.y
		
		# Finally, we have the correct position to spawn
		var pos := Vector3(x_m, y_m, z_m)
		var transf := Transform3D(Basis(), Vector3()).translated( pos )
		
		transf = transf.rotated_local( Vector3.UP, random_rotation )
		transf = transf.scaled_local( Vector3.ONE * random_scale )
		transforms_variants[variant_index].append( transf )
	
	
	# Setup one MultiMeshInstance3D for every type of grass
	for variant_index in transforms_variants.size():
		var multimesh_inst := multimesh_instances[variant_index]
		var transforms := transforms_variants[variant_index]
		var transforms_size:int = transforms.size()
		
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		if billboard == BillboardType.CROSS_BILLBOARD:
			multimesh_inst.multimesh.instance_count = transforms_size*2
		else:
			multimesh_inst.multimesh.instance_count = transforms_size
		
		# Spawn the actual grass
		for transform_index in transforms_size:
			var transform:Transform3D = transforms[transform_index]
			multimesh_inst.multimesh.set_instance_transform( transform_index, transform )
		
		# Spawn the cross billboard grass rotated 90 degrees in the same position
		if billboard == BillboardType.CROSS_BILLBOARD:
			for transform_index in transforms_size:
				var transform:Transform3D = transforms[transform_index].rotated_local( Vector3.UP, PI*0.5 )
				multimesh_inst.multimesh.set_instance_transform( transforms_size + transform_index, transform )
		
		
