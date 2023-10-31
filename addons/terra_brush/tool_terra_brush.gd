@tool
extends Node
class_name TerraBrush
# MANAGER OF BRUSHES:
#  Receives control from the main EditorPlugin and sends it towards any active brush.
#  The brush then performs its respective rol and updates any shader, collider, material, etc..
#
# THE IDEA IS THIS:
#  Ths manager instance will paint, heighten, scatter, etc.. one child terrain and it must be
#  completely add-on independent, so the TERRAIN CAN BE SEPPARATED AND USED AS PRODUCTION-READY AT ANY MOMENT.
#  It manages to do that by creating its own resources and a hidden mesh for the terrain brush overlay.


const BRUSH_HEIGHT_ON_IDLE:float = 0.02
const BRUSH_HEIGHT_ON_ACTION:float = 0.13


## Folder to save or load assets. 
@export_dir() var assets_folder:String

# Brushes
@export var terrain_color := TBrushTerrainColor.new()
@export var terrain_height := TBrushTerrainHeight.new()
@export var grass_color := TBrushGrassColor.new()
@export var grass_spawn := TBrushGrassSpawn.new()

## Use the mouse wheel to increase or decrease brush scale
@export var brush_scale:float = 20
## Will increase or decrease the texture space instead of expanding it
@export var map_size:Vector2i: set=_set_map_size

# Brushes will make use of these
var grass_holder:Node3D
var height_shape:HeightMapShape3D
var overlay_mesh:PlaneMesh
var overlay:MeshInstance3D
var terrain:MeshInstance3D

# Set mesh to every used multimesh (grass)
var grass_mesh:QuadMesh:
	set(v):
		grass_mesh = v
		if grass_holder:
			for child in grass_holder.get_children():
				child.multimesh.mesh = v

# This is just for consistensy with grass_mesh
# Calling from outside would have been "terra_brush.grass_mesh" and "terra_brush.terrain.mesh"
var terrain_mesh:PlaneMesh:
	set(v):
		if terrain:
			terrain.mesh = v
	get:
		return terrain.mesh if terrain else null

var _painting_with_primary:bool
var active_brush:TBrush
var unsaved_changes:bool = true


func _ready():
	# There's no point in running during gameplay
	if not Engine.is_editor_hint():
		return
	
	# Needs to wait a frame to let this node finish its updating cycle first
	await  get_tree().process_frame
	_create_terrain()
	_set_map_size( Vector2i(10, 10) )
	
	var loadable:bool = assets_folder and FileAccess.file_exists( assets_folder.path_join("metadata.tres") )
	
	# Setup brushes. Create templates if it is not loadable
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.tb = self
		brush.setup()
		if not loadable:
			brush.template( map_size )
	
	# We need the boilerplate from _create_terrain() and brush.setup() to have all of the updated references
	if loadable:
		AssetsManager.load_assets( self )
	

func _process(_delta):
	if terrain:
		terrain.global_position = Vector3.ZERO
		terrain.global_rotation = Vector3.ZERO


func _create_terrain():
	for child in get_children():
		child.queue_free()
	
	# Create the asset-independent terrain
	terrain = _create_node( MeshInstance3D.new(), self , "Terrain" )
	grass_holder = _create_node( Node3D.new(), terrain, "Grass" )
	
	var static_body:StaticBody3D = _create_node( StaticBody3D.new(), terrain, "Body" )
	var height_collider:CollisionShape3D = _create_node( CollisionShape3D.new(), static_body, "Height" )
	
	height_collider.shape= HeightMapShape3D.new()
	height_shape = height_collider.shape
	static_body.set_collision_layer_value( MainPlugin.COLLISION_LAYER, true )
	
	terrain_mesh = _create_mesh( PlaneMesh.new(), AssetsManager.TERRAIN_SHADER.duplicate() )
	grass_mesh = _create_mesh( QuadMesh.new(), AssetsManager.GRASS_SHADER_DOUBLE_SIDE.duplicate() )
	
	# Create the hidden terrain for the brush overlay.
	# Should not be under the actual terrain so the user don't carry it away
	overlay = _create_node( MeshInstance3D.new(), self, "Overlay" )
	overlay.mesh = _create_mesh( PlaneMesh.new(), AssetsManager.TERRAIN_SHADER_OVERLAY )
	overlay.mesh.material.set_shader_parameter( "brush_texture", AssetsManager.DEFAULT_BRUSH )
	overlay.position.y += BRUSH_HEIGHT_ON_IDLE
	terrain.set_display_folded( true )
	overlay.owner = self
	
	overlay_mesh = overlay.mesh
	overlay_mesh.size = map_size
	overlay_mesh.subdivide_width = map_size.x - 1
	overlay_mesh.subdivide_depth = map_size.x - 1

func _create_node(new_node:Node, parent:Node, node_name:String) -> Node:
	parent.add_child( new_node )
	new_node.owner = parent.owner
	new_node.name = node_name
	return new_node

func _create_mesh(mesh:PrimitiveMesh, shader:Shader) -> PrimitiveMesh:
	mesh.material = ShaderMaterial.new()
	mesh.material.shader = shader
	return mesh


func _set_map_size(size:Vector2i):
	map_size = size
	
	# ignore when setter is being called in gameplay-time or export-time or when size is zero
	if not Engine.is_editor_hint() or not is_node_ready() or size.x <= 0 or size.y <= 0:
		return
		
	# Subdivissions are one less than meters, while shape vertices are one more. Heh..
	terrain_mesh.size = size
	terrain_mesh.subdivide_width = size.x - 1
	terrain_mesh.subdivide_depth = size.y - 1
	
	height_shape.map_width = size.x + 1
	height_shape.map_depth = size.y + 1
	
	# Update the hidden mesh that has the brush overlay
	overlay_mesh.size = size
	overlay_mesh.subdivide_width = size.x - 1
	overlay_mesh.subdivide_depth = size.x - 1
	
	# Needs the terrain size to accurately paint the grass
	grass_mesh.material.set_shader_parameter( "terrain_size", size )
	
	# Extpands or clips every texture
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.resize_texture( size )
	
	# Update terrain collider first, then place grass according to the colliders
	terrain_height.update_terrain_collider()
	grass_spawn.populate_grass()



# ALL OF THESE ARE CALLED FROM MainPlugin 
func paint(pos:Vector3, primary_action:bool):
	if active_brush:
		_painting_with_primary = primary_action
		active_brush.paint( brush_scale/100.0, pos, primary_action )
		overlay.position.y = BRUSH_HEIGHT_ON_IDLE
		unsaved_changes = true
		AssetsManager.update_saved_state( self )

func paint_end():
	overlay.position.y = BRUSH_HEIGHT_ON_ACTION

func over_terrain(pos:Vector3):
	# The shader draws a circle over mouse pointer to show where and what size are you hovering
	if active_brush and terrain_mesh:
		var pos_rel:Vector2 = Vector2(pos.x, pos.z) / terrain_mesh.size
		overlay_mesh.material.set_shader_parameter( "brush_color", active_brush.out_color )
		overlay_mesh.material.set_shader_parameter( "brush_position", pos_rel )
		overlay_mesh.material.set_shader_parameter( "brush_scale", brush_scale/100.0 )
		
func exit_terrain():
	# Move brush outside viewing scope
	overlay_mesh.material.set_shader_parameter( "brush_position", Vector2(2, 2) )

func scale(value:float):
	if active_brush:
		brush_scale = clampf( brush_scale+value, 1, 150 )
		terrain_mesh.material.set_shader_parameter("brush_scale", brush_scale/100.0 )
