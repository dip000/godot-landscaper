## TERRA BRUSH: Tool for terraforming and coloring grass
# 1. Instantiate a TerraBrush node in scene tree and select it
# 3. Activate the brush you want from the inspector
# 4. Hover over your terrain and left-click-and-drag to start terra-brushing!

@tool
extends MeshInstance3D
class_name TerraBrush

# Global properties
@export_range(1, 150, 1, "suffix:%") var brush_scale:float = 20
@export var map_size:Vector2i: set=_set_map_size

# Brushes
@export var terrain_color := TBrushTerrainColor.new()
@export var terrain_height := TBrushTerrainHeight.new()
@export var grass_color := TBrushGrassColor.new()
@export var grass_spawn := TBrushGrassSpawn.new()

# Names. Use like "get_node(BODY_NAME.join_path(HEIGHT_COLLIDER_NAME))"
const HEIGHT_COLLIDER_NAME := "Height"
const BASE_COLLIDER_NAME := "Base"
const BODY_NAME := "Body"

# Current meshes (this and "mesh" property from inheritance). They will change once you set a folder to save them
var grass_mesh:QuadMesh = load("res://addons/terra_brush/meshes/grass_mesh.tres")
const TERRAIN_MESH_PATH := "res://addons/terra_brush/meshes/terrain_mesh.tres"

# Keeps track of which brush is currently active so it can call "_active_brush.paint()"
var _active_brush:TBrush


func _ready():
	# Why does this keep reseting??
	grass_mesh.material.set_shader_parameter("terrain_size", map_size)
	
	# There's no point in running during gameplay
	if not Engine.is_editor_hint():
		return
	
	# Initialize these only if this is the first time this object has been instantiated
	# Can't instantiate children while this script is still in ready() cycle
	if not has_node(BODY_NAME):
		await get_tree().process_frame
		mesh = load(TERRAIN_MESH_PATH)
		_create_children()
		_set_map_size( Vector2i(10, 10) )
	
	# Setup brushes. 
	# "_deactivate_brushes()" Will keep only one brush active at a time
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.on_active.connect( _deactivate_brushes.bind(brush) )
		brush.setup( self )


func _create_children():
	var static_body := StaticBody3D.new()
	add_child(static_body)
	static_body.owner = self
	static_body.name = BODY_NAME
	
	var height_collider := CollisionShape3D.new()
	static_body.add_child(height_collider)
	height_collider.owner = self
	height_collider.name = HEIGHT_COLLIDER_NAME
	height_collider.shape = HeightMapShape3D.new()
	
	var base_collider := CollisionShape3D.new()
	static_body.add_child(base_collider)
	base_collider.owner = self
	base_collider.name = BASE_COLLIDER_NAME
	base_collider.shape = BoxShape3D.new()
	

func _set_map_size(size:Vector2i):
	map_size = size
	
	# ignore when setter is being called in gameplay-time or export-time or when size is zero
	if not Engine.is_editor_hint() or not is_node_ready() or size.x <= 0 or size.y <= 0:
		return
	
	# Subdivissions are one less than meters, while vertices are one more. Heh..
	mesh.size = size
	mesh.subdivide_width = size.x - 1
	mesh.subdivide_depth = size.y - 1
	
	var body_shape:HeightMapShape3D = get_node( BODY_NAME.path_join(HEIGHT_COLLIDER_NAME) ).shape
	body_shape.map_width = size.x + 1
	body_shape.map_depth = size.y + 1
	
	# Base from where to draw in case you're outside heightmap mesh. Add extra margin for responsivenes
	var base_shape:BoxShape3D = get_node( BODY_NAME.path_join(BASE_COLLIDER_NAME) ).shape
	base_shape.size = Vector3(size.x+1, 0.05, size.y+1)
	
	# Update colliders first, then place grass according to the colliders
	grass_mesh.material.set_shader_parameter("terrain_size", size)
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
		mesh.material.set_shader_parameter("brush_position", pos_rel)
		mesh.material.set_shader_parameter("brush_scale", brush_scale/100.0)
		if _active_brush == grass_color or _active_brush == terrain_color:
			mesh.material.set_shader_parameter("brush_color", _active_brush.color)
		else:
			mesh.material.set_shader_parameter("brush_color", _active_brush.t_color)
		return


func exit_terrain():
	mesh.material.set_shader_parameter("brush_position", Vector2(2,2)) #move brush outside viewing scope

func scale(value:float):
	if _active_brush:
		brush_scale = clampf(brush_scale+value, 1, 150)
		mesh.material.set_shader_parameter("brush_scale", brush_scale/100.0)

func paint(pos:Vector3, primary_action:bool):
	if _active_brush:
		_active_brush.paint(brush_scale/100.0, pos, primary_action)

func scene_active():
	pass

