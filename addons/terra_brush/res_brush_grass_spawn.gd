@tool
extends TBrush
class_name TBrushGrassSpawn
# Brush that spawns grass when you paint over the terrain
# Paints different shades of gray over the "texture" depending on the grass variant


enum SpawnType {SPAWN_ONE_VARIANT, SPAWN_RANDOM_VARIANTS}

## Action to perform while left-clicking over the terrain. Right click will clear grass
@export var spawn_type:SpawnType = SpawnType.SPAWN_RANDOM_VARIANTS:
	set(v):
		spawn_type = v
		on_active.emit()
		active = true

## Grass variant from "variants" property (below "Shader Properties"). Only if you selected mode SPAWN_ONE_VARIANT
@export var variant:int = 0:
	set(v):
		variant = clampi(v, 0, variants.size()-1)
		on_active.emit()
		active = true

## Amount of grass proportional to the whole surface
@export var density:int = 1024:
	set(v):
		density = v
		on_active.emit()
		active = true
		populate_grass()

@export_group("Grass Settings")

## Grass always looks at the camera in y-axis
@export var billboard_y := true:
	set(v):
		billboard_y = v
		update_grass_shader("billboard_y", billboard_y)

##[NOT IMPLEMENTED]
@export var cross_billboard := false:
	set(v):
		cross_billboard = v

## If it should recolor the details you may have used in your variant texture.
## Remember that variant textures must be white and their details black
@export var enable_margin := true:
	set(v):
		enable_margin = v
		update_grass_shader("enable_margin", enable_margin)

## Detail recolor. See margin_enable
@export var margin_color := Color(0.3, 0.3, 0.3):
	set(v):
		margin_color = v
		update_grass_shader("margin_color", margin_color)

## Subdivisions for each blade of grass. This affects its sway animation and gradient color smoothess (because is vertex colored)
@export var quality:int = 3:
	set(v):
		quality = v
		if tb:
			tb.grass_mesh.subdivide_depth = quality

## Size of the average blade of grass in meters
@export var size:Vector2:
	set(v):
		size = v
		if tb:
			tb.grass_mesh.size = size
			tb.grass_mesh.center_offset.y = size.y/2 #origin rooted to the ground

## The color mix from the grass roots to the top as seen from the front. BLACK=terrain_color and WHITE=grass_color
@export var gradient_mask:GradientTexture2D:
	set(v):
		gradient_mask = v
		update_grass_shader("gradient_mask", gradient_mask)

## Adding or deleting a new variant might remap your current variant placements
@export var variants:Array[Texture2D]:
	set(v):
		variants = v
		update_grass_shader("variants", variants)
		populate_grass()

# To re-create the same series of spawn positions
var _rng := RandomNumberGenerator.new()
var _rng_state:int


func setup():
	resource_name = "grass_spawn"
	
	variants = [
		AssetsManager.DEFAULT_GRASS_VARIANT1.duplicate(),
		AssetsManager.DEFAULT_GRASS_VARIANT2.duplicate(),
	]
	gradient_mask = AssetsManager.DEFAULT_GRASS_GRADIENT.duplicate()
	texture = ImageTexture.create_from_image( _create_empty_img(Color.BLACK) )
	size = Vector2(0.3, 0.3)
	
	# Setup RNG as documentation suggests
	_rng.set_seed( hash("TerraBrush") )
	_rng_state = _rng.get_state()


func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active or not texture:
		return
	
	# Spawn with primary key, erase with secondary
	if primary_action:
		match spawn_type:
			SpawnType.SPAWN_ONE_VARIANT:
				# Middleground between variant color range
				var v:float = float(variant)/variants.size() + 0.5/variants.size()
				t_color = Color(v,v,v, 1.0)
			SpawnType.SPAWN_RANDOM_VARIANTS:
				t_color = Color.WHITE
	else:
		t_color = Color.BLACK
	
	# Update textures and grass positions
	_bake_brush_into_surface(scale, pos)
	populate_grass()


func on_texture_update():
	populate_grass()

func populate_grass():
	if not tb or not tb.terrain_mesh or not texture:
		return
	
	if variants.is_empty():
		return
	
	# Caches
	var terrain_image:Image = texture.get_image()
	var terrain_size_m:Vector2 = tb.terrain_mesh.size
	var terrain_size_px:Vector2 = terrain_image.get_size()
	var total_variants:int = variants.size()
	var max_index:int = total_variants - 1
	var space := tb.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	
	# Reset previous instances
	var multimesh_instances:Array[MultiMeshInstance3D]
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
			multimesh_instances.append(new_instance)
			
			tb.grass_holder.add_child(new_instance)
			new_instance.owner = tb.owner
			new_instance.name = "Grass"
	
	# Delete instances if variants were reduced
	else:
		for _variant_index in multimesh_instances.size() - total_variants:
			multimesh_instances.pop_back().queue_free()
	
	# Reset random generator so it can spawn exactly where it previously did
	_rng.set_state(_rng_state)
	
	# Find all actual valid places to spawn
	var transforms_variants:Array[Array]
	transforms_variants.resize(total_variants)
	
	for _i in density:
		# Get pixel value in random position
		var rand := Vector2(_rng.randf(), _rng.randf())
		var terrain_value:float = terrain_image.get_pixelv( rand*terrain_size_px ).r
		
		# WHITE = SPAWN_RANDOM_VARIANTS (always calculate to ensure full state restoration from RandomNumberGenerator)
		var variant_index:int = _rng.randi_range(0, max_index)
		
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
		ray.from = Vector3(x_m, 10.0, z_m)
		ray.to = Vector3(x_m, -10.0, z_m)
		var y_m:float = space.intersect_ray(ray).position.y
		
		# Finally, we have the correct position to spawn
		var pos := Vector3(x_m, y_m, z_m)
		var transf := Transform3D(Basis(), Vector3()).translated( pos )
		transforms_variants[variant_index].append( transf )
	
	
	# Place grass with the obtained transforms
	for variant_index in transforms_variants.size():
		var multimesh_inst := multimesh_instances[variant_index]
		var transforms := transforms_variants[variant_index]
		multimesh_inst.multimesh.instance_count = transforms.size()
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		
		for transform_index in transforms.size():
			multimesh_inst.multimesh.set_instance_transform( transform_index, transforms[transform_index] )

