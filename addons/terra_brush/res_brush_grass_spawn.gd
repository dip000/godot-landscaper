@tool
extends TBrush
class_name TBrushGrassSpawn

enum SpawnType {SPAWN_ONE_VARIANT, SPAWN_RANDOM_VARIANTS}

## Action to perform while left-clicking over the _terrain. Right click will clear grass
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
@export var margin_color:Color = Color(0.3, 0.3, 0.3):
	set(v):
		margin_color = v
		populate_grass()


var _rng := RandomNumberGenerator.new()
var _rng_state:int


func setup(terrain:TerraBrush):
	super(terrain)
	resource_name = "grass_spawn"
	var tex := ImageTexture.create_from_image( _create_empty_img(Color.BLACK) )
	surface_texture = tex
	variants = [
		preload("res://addons/terra_brush/textures/grass_small_texture.png"),
		preload("res://addons/terra_brush/textures/grass_texture.png"),
	]
	_rng.set_seed( hash("TerraBrush") )
	_rng_state = _rng.get_state()

func update():
	_terrain.grass_mesh.material.set_shader_parameter("grass_spawn", surface_texture)
	populate_grass()

func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active or not surface_texture:
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
	update()


func populate_grass():
	if not _terrain or not surface_texture:
		return
	
	if variants.is_empty():
		push_warning("Please add a grass variant under 'Shader Properties'")
		return
	
	# Caches
	var terrain_image:Image = surface_texture.get_image()
	var terrain_size_m:Vector2 = _terrain.mesh.size
	var terrain_size_px:Vector2i = terrain_image.get_size()
	var total_variants:int = variants.size()
	var max_index:int = total_variants - 1
	var space := _terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	
	# Reset previous instances
	var multimesh_instances:Array[MultiMeshInstance3D]
	for child in _terrain.get_children():
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
			new_instance.multimesh.mesh = _terrain.grass_mesh
			multimesh_instances.append(new_instance)
			
			_terrain.add_child(new_instance)
			new_instance.owner = _terrain
			new_instance.name = "Grass"
	
	# Delete instances if variants were reduced
	else:
		for _variant_index in multimesh_instances.size() - total_variants:
			multimesh_instances.pop_back().queue_free()
	
	# Setup shader
	var mat:ShaderMaterial = _terrain.grass_mesh.material
	mat.set_shader_parameter("bilboard_y", billboard_y)
	mat.set_shader_parameter("enable_margin", margin_enable)
	mat.set_shader_parameter("color_margin", margin_color)
	mat.set_shader_parameter("grass_variants", variants)
	
	# Reset random generator so it can spawn exactly where it previously did
	_rng.set_state(_rng_state)
	
	# Find all actual valid places to spawn
	var transforms_variants:Array[Array]
	transforms_variants.resize(total_variants)
	
	for current_instance in density:
		# Get pixel value in random position
		var x:float = _rng.randf()
		var z:float = _rng.randf()
		var x_px:int = floori(x*terrain_size_px.x)
		var z_px:int = floori(z*terrain_size_px.y)
		var terrain_value:float = terrain_image.get_pixel(x_px, z_px).r
		
		# WHITE = SPAWN_RANDOM_VARIANTS (always calculate to ensure full state restoration from RandomNumberGenerator)
		var variant_index:int = _rng.randi_range(0, max_index)
		
		# BLACK = CLEAR
		if is_zero_approx(terrain_value):
			continue
		
		# SPAWN_ONE_VARIANT
		if terrain_value < 1.0:
			variant_index = roundi( terrain_value*max_index )
		
		# From the center of the texture
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
	
	
	# Place grass with the obtained transforms
	for variant_index in transforms_variants.size():
		var multimesh_inst := multimesh_instances[variant_index]
		var transforms := transforms_variants[variant_index]
		multimesh_inst.multimesh.instance_count = transforms.size()
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		
		var transforms_size:int = transforms.size()
		for transform_index in transforms_size:
			multimesh_inst.multimesh.set_instance_transform( transform_index, transforms[transform_index] )

