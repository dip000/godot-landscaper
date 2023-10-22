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

const GRASS_MAT:ShaderMaterial = preload("res://addons/terra_brush/materials/grass_mat.tres")
const GRASS_MESH:PlaneMesh = preload("res://addons/terra_brush/meshes/grass_mesh.tres")
const TERRAIN_MAT:ShaderMaterial = preload("res://addons/terra_brush/materials/terrain_mat.tres")
const TERRAIN_MESH:PlaneMesh = preload("res://addons/terra_brush/meshes/terrain_mesh.tres")
const BRUSH_MASK:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres")
const HEIGHT_COLLIDER_NAME := "Height"
const BASE_COLLIDER_NAME := "Base"
const BODY_NAME := "Body"

var _active_brush:TBrush
var rng := RandomNumberGenerator.new()
var rng_state:int


func _ready():
	GRASS_MAT.set_shader_parameter("terrain_size", map_size) #idk why this keeps reseting..
	if not Engine.is_editor_hint():
		return
	
	rng.set_seed( hash("TerraBrush <3") )
	rng_state = rng.get_state()
	
	grass_spawn.variants = [
		preload("res://addons/terra_brush/textures/grass_small_texture.png"),
		preload("res://addons/terra_brush/textures/grass_texture.png")
	]
	
	# Always keep only one brush active at a time
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.on_active.connect(_deactivate_brushes.bind(brush))
		brush.terrain = self
		brush.active = false
		if not brush.surface_texture:
			brush.surface_texture = brush.TEXTURE
	
	_setup()

func _setup():
	mesh = TERRAIN_MESH
	GRASS_MAT.set_shader_parameter("terrain_size", map_size)
	
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
	
	# ignore when setter is being called in gameplay-time or export-time
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	
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
	
	GRASS_MAT.set_shader_parameter("terrain_size", size)
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
		TERRAIN_MAT.set_shader_parameter("brush_position", pos_rel)
		TERRAIN_MAT.set_shader_parameter("brush_scale", brush_scale/100.0)
		if _active_brush == grass_color or _active_brush == terrain_color:
			TERRAIN_MAT.set_shader_parameter("brush_color", _active_brush.color)
		else:
			TERRAIN_MAT.set_shader_parameter("brush_color", _active_brush.t_color)
		return

func exit_terrain():
	TERRAIN_MAT.set_shader_parameter("brush_position", Vector2(2,2)) #move brush outside viewing scope

func scale(value:float):
	if _active_brush:
		brush_scale = clampf(brush_scale+value, 1, 150)
		TERRAIN_MAT.set_shader_parameter("brush_scale", brush_scale/100.0)

func paint(pos:Vector3, primary_action:bool):
	if _active_brush:
		_active_brush.paint(brush_scale/100.0, pos, primary_action)

func scene_active():
	pass
