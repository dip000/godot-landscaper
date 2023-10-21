@tool
extends TBrush
class_name TBrushGrassSpawn

const BATCH_PROCESS_FRAMES:int = 50 # Set higher if you have a better computer :D
const GRASS_MESH:Mesh = preload("res://addons/terra_brush/meshes/grass.tres")
const TEXTURE:Texture2D = preload("res://addons/terra_brush/textures/grass_spawn.tres")

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
@export var density:int = 512:
	set(v):
		density = v
		on_active.emit()
		active = true
		populate_grass()

@export_group("Shader Properties")
## Adding or deleting a new variant might remap your current variant placements
@export var variants:Array[Texture2D]:
	set(v):
		variants = v
		populate_grass()

## Grass always looks at the camera in y-axis
@export var billboard_y:bool = true:
	set(v):
		billboard_y = v
		populate_grass()

## If it should recolor the details you may have used in your variant texture.
## Remember that variant textures must be white and their details black
@export var margin_enable:bool = true:
	set(v):
		margin_enable = v
		populate_grass()

## Detail recolor. See margin_enable
@export var margin_color:Color = Color.WHITE:
	set(v):
		margin_color = v
		populate_grass()


func paint(scale:float, pos:Vector3, primary_action:bool):
	if active:
		if not surface_texture:
			surface_texture = TEXTURE
		
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
		
		TerraBrush.GRASS.set_shader_parameter("grass_spawn", surface_texture)
		_bake_brush_into_surface(scale, pos)
		populate_grass()


func populate_grass():
	if not terrain or not surface_texture:
		return
	
	if variants.is_empty():
		push_warning("Please add a grass variant under 'Shader Properties'")
		return
	
	# Caches
	var rng:RandomNumberGenerator = terrain.rng
	var terrain_image:Image = surface_texture.get_image()
	var terrain_size_m:Vector2 = terrain.mesh.size
	var terrain_size_px:Vector2i = terrain_image.get_size()
	var total_variants:int = variants.size()
	var max_index:int = total_variants - 1
	var space := terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	
	# Reset previous instances
	var multimesh_instances:Array[MultiMeshInstance3D]
	for child in terrain.get_children():
		if child is MultiMeshInstance3D:
			multimesh_instances.append(child)
			child.multimesh.instance_count = 0
			child.position = Vector3.ZERO # fix their position just in case
	
	# Add instances if more variants were added
	if multimesh_instances.size() < total_variants:
		for _variant_index in total_variants - multimesh_instances.size():
			var new_instance := MultiMeshInstance3D.new()
			new_instance.multimesh = MultiMesh.new()
			new_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			new_instance.multimesh.mesh = GRASS_MESH
			multimesh_instances.append(new_instance)
			
			terrain.add_child(new_instance)
			new_instance.owner = terrain.owner
			new_instance.name = "Grass"
	
	# Delete instances if variants were reduced
	else:
		for _variant_index in multimesh_instances.size() - total_variants:
			multimesh_instances.pop_back().queue_free()
	
	# Setup shader
	TerraBrush.GRASS.set_shader_parameter("bilboard_y", billboard_y)
	TerraBrush.GRASS.set_shader_parameter("enable_margin", margin_enable)
	TerraBrush.GRASS.set_shader_parameter("color_margin", margin_color)
	TerraBrush.GRASS.set_shader_parameter("grass_variants", variants)
	
	rng.set_state(terrain.rng_state)
	
	# Find all actual valid places to spawn
	var transforms_variants:Array[Array]
	transforms_variants.resize(total_variants)
	
	for current_instance in density:
		# Get pixel value in random position
		var x:float = rng.randf()
		var z:float = rng.randf()
		var x_px:int = floori(x*terrain_size_px.x)
		var z_px:int = floori(z*terrain_size_px.y)
		var terrain_value:float = terrain_image.get_pixel(x_px, z_px).r
		
		# WHITE = SPAWN_RANDOM_VARIANTS (always calculate to ensure full state restoration from RandomNumberGenerator)
		var variant_index:int = rng.randi_range(0, max_index)
		
		# BLACK = CLEAR
		if is_zero_approx(terrain_value):
			continue
		
		# SPAWN_ONE_VARIANT
		if terrain_value < 1.0:
			variant_index = roundi( terrain_value*max_index )
		
		var x_m:float = (x - 0.5)*terrain_size_m.x
		var z_m:float = (z - 0.5)*terrain_size_m.y
		
		# Raycast to the HeightMapShape3D to find the actual ground level (shape should've been updated in TBrushTerrainHeight)
		ray.from = Vector3(x_m, 10.0, z_m)
		ray.to = Vector3(x_m, -10.0, z_m)
		var result := space.intersect_ray(ray)
		if not result: continue
		var y_m:float = result.position.y
		
		# Using "height_image" as height reference will spawn floating grass. The vertices wouldn't alignt perfectly with the image
#		var y_m:float = height_image.get_pixel(x_px, z_px).r * TBrushTerrainHeight.HEIGHT_STRENGTH
		
		var pos := Vector3(x_m, y_m, z_m)
		var transf := Transform3D(Basis(), Vector3()).translated( pos )
		transforms_variants[variant_index].append( transf )
	print("Grass spawned per multimesh: ", transforms_variants.map(func(v): return v.size()))
	
	# Place grass with the obtained transforms
	for variant_index in transforms_variants.size():
		var multimesh_inst := multimesh_instances[variant_index]
		var transforms := transforms_variants[variant_index]
		multimesh_inst.multimesh.instance_count = transforms.size()
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		
		var transforms_size:int = transforms.size()
		for transform_index in transforms_size:
			multimesh_inst.multimesh.set_instance_transform( transform_index, transforms[transform_index] )

