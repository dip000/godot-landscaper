@tool
extends Node3D
class_name TerraBrush
# Tool for terraforming and coloring
# 1. Instantiate a TerraBrush node in scene tree and select it
# 2. Activate the brush you want from the inspector
# 3. Hover over your terrain and left-click-and-drag to start terra-brushing!

## Folder to save or load assets. 
@export_dir() var assets_folder:String = "res://generated_terrain/"
@export_range(1, 150, 1, "suffix:%") var brush_scale:float = 20
@export var map_size:Vector2i: set=_set_map_size

# Brushes
@export var terrain_color := TBrushTerrainColor.new()
@export var terrain_height := TBrushTerrainHeight.new()
@export var grass_color := TBrushGrassColor.new()
@export var grass_spawn := TBrushGrassSpawn.new()

#[TEST] Get rid of exports on release
@export var grass_holder:Node3D
@export var terrain:MeshInstance3D
@export var height_shape:HeightMapShape3D
@export var base_shape:BoxShape3D


# Keeps track of which brush is currently active
var _active_brush:TBrush

# Set mesh to every used multimesh (grass)
@export var grass_mesh:QuadMesh:
	set(v):
		grass_mesh = v
		for child in grass_holder.get_children():
			child.multimesh.mesh = v

# Just for consistency with "grass_mesh"
@export var terrain_mesh:PlaneMesh:
	set(v):
		terrain_mesh = v
		terrain.mesh = v


func _ready():
	# There's no point in running during gameplay
	if not Engine.is_editor_hint():
		return
	
	# Initialize these only if this is the first time this object has been instantiated
	if not get_child(0):
		await  get_tree().process_frame
		terrain = load("res://addons/terra_brush/Scenes/terrain_template.tscn").instantiate()
		add_child(terrain)
		terrain.owner = owner
		grass_holder = terrain.get_node("Grass")
		height_shape = terrain.get_node("Body/Height").shape
		base_shape = terrain.get_node("Body/Base").shape
		grass_mesh = grass_holder.get_child(0).multimesh.mesh
		terrain_mesh = terrain.mesh
		_set_map_size( Vector2i(10, 10) )
	
	# Setup brushes. Keeps only one brush active at a time
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.on_active.connect( _deactivate_brushes.bind(brush) )
		brush.terrain = self
		brush.setup()
	

func _set_map_size(size:Vector2i):
	map_size = size
	
	# ignore when setter is being called in gameplay-time or export-time or when size is zero
	if not terrain or not Engine.is_editor_hint() or not is_node_ready() or size.x <= 0 or size.y <= 0:
		return
	
	print(terrain_mesh, size)
	# Subdivissions are one less than meters, while vertices are one more. Heh..
	terrain_mesh.size = size
	terrain_mesh.subdivide_width = size.x - 1
	terrain_mesh.subdivide_depth = size.y - 1
	
	height_shape.map_width = size.x + 1
	height_shape.map_depth = size.y + 1
	
	# Base from where to draw in case you're outside heightmap mesh. Add extra margin for responsivenes
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
		var pos_rel:Vector2 = Vector2(pos.x, pos.z)/terrain_mesh.size
		terrain_mesh.material.set_shader_parameter("brush_position", pos_rel)
		terrain_mesh.material.set_shader_parameter("brush_scale", brush_scale/100.0)
		if _active_brush == grass_color or _active_brush == terrain_color:
			terrain_mesh.material.set_shader_parameter("brush_color", _active_brush.color)
		else:
			terrain_mesh.material.set_shader_parameter("brush_color", _active_brush.t_color)
		return


func exit_terrain():
	terrain_mesh.material.set_shader_parameter("brush_position", Vector2(2,2)) #move brush outside viewing scope

func scale(value:float):
	if _active_brush:
		brush_scale = clampf(brush_scale+value, 1, 150)
		terrain_mesh.material.set_shader_parameter("brush_scale", brush_scale/100.0)

func paint(pos:Vector3, primary_action:bool):
	if _active_brush:
		_active_brush.paint(brush_scale/100.0, pos, primary_action)

func scene_active():
	pass

