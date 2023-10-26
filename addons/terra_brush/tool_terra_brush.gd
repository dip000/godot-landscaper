@tool
extends Node
class_name TerraBrush
# Tool for terraforming and coloring
# 1. Instantiate a TerraBrush node in scene tree and select it
# 2. Activate the brush you want from the inspector
# 3. Hover over your terrain and left-click-and-drag to start terra-brushing!


## Folder to save or load assets. 
@export_dir() var assets_folder:String = "res://generated_terrain/"
@export var map_size:Vector2i: set=_set_map_size

# Brushes
@export var terrain_color := TBrushTerrainColor.new()
@export var terrain_height := TBrushTerrainHeight.new()
@export var grass_color := TBrushGrassColor.new()
@export var grass_spawn := TBrushGrassSpawn.new()

var brush_scale:float = 20
var grass_holder:Node3D
var terrain:MeshInstance3D
var height_shape:HeightMapShape3D
var base_shape:BoxShape3D

var overlay_mesh:PlaneMesh

# Keeps track of which brush is currently active
var _active_brush:TBrush

# Set mesh to every used multimesh (grass)
var grass_mesh:QuadMesh:
	set(v):
		grass_mesh = v
		if grass_holder:
			for child in grass_holder.get_children():
				child.multimesh.mesh = v

# Just for consistency with "grass_mesh"
var terrain_mesh:PlaneMesh:
	set(v):
		terrain_mesh = v
		if terrain:
			terrain.mesh = v


func _ready():
	# There's no point in running during gameplay
	if not Engine.is_editor_hint():
		return
	
	# Initialize these only if this is the first time this object has been instantiated
	# Needs to wait a frame to let this node finish updating first
	if not has_node("Terrain"):
		await  get_tree().process_frame
		_create_children()
		terrain_mesh = AssetsManager.generate_terrain_mesh( self, false )
		grass_mesh = AssetsManager.generate_grass_mesh( self )
		_set_map_size( Vector2i(10, 10) )
	
	# Setup brushes. Keeps only one brush active at a time
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.on_active.connect( _deactivate_brushes.bind(brush) )
		brush.tb = self
		brush.setup()
	

func _set_map_size(size:Vector2i):
	map_size = size
	
	# ignore when setter is being called in gameplay-time or export-time or when size is zero
	if not terrain or not Engine.is_editor_hint() or not is_node_ready() or size.x <= 0 or size.y <= 0:
		return
	
	# Subdivissions are one less than meters, while vertices are one more. Heh..
	terrain_mesh.size = size
	terrain_mesh.subdivide_width = size.x - 1
	terrain_mesh.subdivide_depth = size.y - 1
	
	overlay_mesh.size = size
	overlay_mesh.subdivide_width = size.x - 1
	overlay_mesh.subdivide_depth = size.x - 1
	
	height_shape.map_width = size.x + 1
	height_shape.map_depth = size.y + 1
	
	# Base from where to draw in case you're outside heightmap mesh. Add extra margin for responsivenes
	base_shape.size = Vector3(size.x+1, 0.05, size.y+1)
	
	grass_mesh.material.set_shader_parameter("terrain_size", size)
	
	# Update terrain collider first, then place grass according to the colliders
	terrain_height.update_terrain_collider()
	grass_spawn.populate_grass()


func _create_children():
	terrain = create_node( MeshInstance3D.new(), self, "Terrain" )
	grass_holder = create_node( Node3D.new(), terrain, "Grass" )
	
	var static_body:StaticBody3D = create_node( StaticBody3D.new(), terrain, "Body" )
	var height_collider:CollisionShape3D = create_node( CollisionShape3D.new(), static_body, "Height" )
	var base_collider:CollisionShape3D = create_node( CollisionShape3D.new(), static_body, "Base" )
	
	height_collider.shape = HeightMapShape3D.new()
	height_shape = height_collider.shape
	base_collider.shape = BoxShape3D.new()
	base_shape = base_collider.shape
	
	var overlay_mesh_inst:MeshInstance3D = create_node( MeshInstance3D.new(), self, "Overlay" )
	overlay_mesh_inst.mesh = AssetsManager.generate_terrain_mesh( self, true )
	overlay_mesh = overlay_mesh_inst.mesh
	overlay_mesh_inst.position.y += 0.18;
	overlay_mesh_inst.owner = self

func create_node(node:Node, parent:Node, node_name:String) -> Node:
	parent.add_child( node )
	node.owner = parent.owner
	node.name = node_name
	return node

func _deactivate_brushes(caller_brush:TBrush):
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.active = false
	_active_brush = caller_brush

func set_enable_updates(value:bool):
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.enable_updates = value

func over_terrain(pos:Vector3):
	# The shader draws a circle over mouse pointer to show where and what size are you hovering
	if _active_brush and terrain_mesh:
		var pos_rel:Vector2 = Vector2(pos.x, pos.z)/terrain_mesh.size
		overlay_mesh.material.set_shader_parameter("brush_position", pos_rel)
		overlay_mesh.material.set_shader_parameter("brush_scale", brush_scale/100.0)
		
		if _active_brush == grass_color or _active_brush == terrain_color:
			overlay_mesh.material.set_shader_parameter("brush_color", _active_brush.color)
		else:
			overlay_mesh.material.set_shader_parameter("brush_color", _active_brush.t_color)
		return


func exit_terrain():
	if terrain_mesh:
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

