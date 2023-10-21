## TERRA BRUSH: Tool for terraforming and coloring grass
# 1. Instantiate a TerraBrush node in scene tree and select it
# 2. Set up the terrain and grass shader properties from the inspector
# 3. Activate the brush you want from the inspector
# 4. Hover over your terrain and left-click-and-drag to start terra-brushing!

@tool
extends MeshInstance3D
class_name TerraBrush

@export_range(1, 150, 1, "suffix:%") var brush_scale:float = 20
@export var map_size:Vector2i: set=_set_map_size

@export var terrain_color := TBrushTerrainColor.new()
@export var terrain_height := TBrushTerrainHeight.new()
@export var grass_color := TBrushGrassColor.new()
@export var grass_spawn := TBrushGrassSpawn.new()

const GRASS:ShaderMaterial = preload("res://addons/terra_brush/materials/grass.tres")
const TERRAIN:ShaderMaterial = preload("res://addons/terra_brush/materials/terrain.tres")
const TERRAIN_MESH:PlaneMesh = preload("res://addons/terra_brush/meshes/terrain.tres")
const BRUSH_MASK:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres")
const HEIGHT_COLLIDER_NAME := "Height"
const BASE_COLLIDER_NAME := "Base"
const BODY_NAME := "Body"

var _active_brush:TBrush
var rng := RandomNumberGenerator.new()
var rng_state:int


func _ready():
	rng.set_seed( hash("TerraBrush <3") )
	rng_state = rng.get_state()
	grass_spawn.variants = [
		preload("res://addons/terra_brush/textures/grass_small_texture.png"),
		preload("res://addons/terra_brush/textures/grass_texture.png")
	]
	
	# Always keep only one brush active at a time. Starts with "terrain_color"
	_active_brush = terrain_color
	terrain_color.active = true
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.on_active.connect(_deactivate_brushes.bind(brush))
		brush.terrain = self
		brush.surface_texture = brush.TEXTURE
	
	_setup()

func _setup():
	mesh = TERRAIN_MESH
	GRASS.set_shader_parameter("terrain_size", map_size)
	
	if has_node(BODY_NAME):
		return
	await get_tree().process_frame
	
	var static_body := StaticBody3D.new()
	add_child(static_body)
	static_body.owner = owner
	static_body.name = BODY_NAME
	
	var height_collider := CollisionShape3D.new()
	static_body.add_child(height_collider)
	height_collider.owner = owner
	height_collider.name = HEIGHT_COLLIDER_NAME
	height_collider.shape = HeightMapShape3D.new()
	
	var base_collider := CollisionShape3D.new()
	static_body.add_child(base_collider)
	base_collider.owner = owner
	base_collider.name = BASE_COLLIDER_NAME
	base_collider.shape = BoxShape3D.new()
	_set_map_size( Vector2i(10, 10) )
	
func _set_map_size(size:Vector2i):
	map_size = size
	if size.x <= 0 or size.y <= 0:
		return
	
	mesh.size = size
	mesh.subdivide_width = size.x - 1
	mesh.subdivide_depth = size.y - 1
	
	var body_shape:HeightMapShape3D = get_node( BODY_NAME.path_join(HEIGHT_COLLIDER_NAME) ).shape
	body_shape.map_width = size.x + 1
	body_shape.map_depth = size.y + 1
	
	var base_shape:BoxShape3D = get_node( BODY_NAME.path_join(BASE_COLLIDER_NAME) ).shape
	base_shape.size = Vector3(size.x+0.5, 0.05, size.y+0.5) # Extra margin for responsivenes
	
	GRASS.set_shader_parameter("terrain_size", size)
	terrain_height.update_terrain_collider()
	grass_spawn.populate_grass()

func _deactivate_brushes(caller_brush:TBrush):
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.active = false
	_active_brush = caller_brush

func over_terrain(pos:Vector3):
	# The shader draws a circle over mouse pointer to show where and what size are you hovering
	if _active_brush:
		var pos_rel:Vector2 = Vector2(pos.x, pos.z)/mesh.size
		TERRAIN.set_shader_parameter("brush_position", pos_rel)
		TERRAIN.set_shader_parameter("brush_scale", brush_scale/100.0)
		if _active_brush == grass_color or _active_brush == terrain_color:
			TERRAIN.set_shader_parameter("brush_color", _active_brush.color)
		else:
			TERRAIN.set_shader_parameter("brush_color", _active_brush.t_color)
		return

func exit_terrain():
	TERRAIN.set_shader_parameter("brush_position", Vector2(2,2)) #move brush outside viewing scope

func scale(value:float):
	if _active_brush:
		var terrain_material:ShaderMaterial = mesh.surface_get_material(0)
		brush_scale = clampf(brush_scale+value, 1, 150)
		terrain_material.set_shader_parameter("brush_scale", brush_scale/100.0)

func save():
	# Might take a bit to save
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		if brush and brush.surface_texture and brush.texture_updated:
			ResourceSaver.save(brush.surface_texture)
			print("Saved texture: ", brush.surface_texture.resource_name)
			brush.texture_updated = false
			await get_tree().process_frame

func paint(pos:Vector3, primary_action:bool):
	if _active_brush:
		_active_brush.paint(brush_scale/100.0, pos, primary_action)

func scene_active():
	pass
