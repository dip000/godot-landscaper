@tool
extends Node
class_name Landscaper
# Brushes manager:
#   Creates a new terrain and receives control from PluginLandscaper.
#  * Unparent the Terrain node outside and delete this when you've finished
#  * Saving/Loading mechanics are in reconstruction, again..


const BRUSH_HEIGHT_ON_IDLE:float = 0.13
const BRUSH_HEIGHT_ON_ACTION:float = 0.02
const DEFAULT_SIZE := Vector2i(10, 10)

# This node instance is managing these brushes
# The order should be as in 'Brush' class
var brushes:Array[Brush] = [
	TerrainBuilder.new(),
	TerrainColor.new(),
	TerrainHeight.new(),
	GrassColor.new(),
	GrassSpawn.new(),
]

var terrain:MeshInstance3D
var terrain_overlay:MeshInstance3D
var grass_holder:Node3D
var terrain_body:StaticBody3D
var terrain_collider:CollisionShape3D

# Stores the grass mesh and sends it to any multimesh grass, if any
var grass_mesh:QuadMesh:
	set(v):
		grass_mesh = v
		for grass in grass_holder.get_children():
			grass.multimesh.mesh = grass_mesh

# For consistency with 'grass_mesh'. Doesn't need to store the mesh here
var terrain_mesh:ArrayMesh:
	set(v):
		terrain.mesh = v
	get:
		return terrain.mesh



func _ready():
	var already_initialized:bool = (get_child_count() > 0)
	
	# Wait a frame to let this node finish its ready cycle first
	await get_tree().process_frame
	_fix_terrain()
	terrain_overlay.material_override.set_shader_parameter( "brush_scale", DockUI.brush_size.value/100 )
	
	for brush in brushes:
		brush.landscaper = self
		brush.setup()
		if not already_initialized:
			brush.template( DEFAULT_SIZE )
	

func _fix_terrain():
	# Create or find nodes
	terrain = _create_or_find_node( MeshInstance3D, self , "Terrain" )
	grass_holder = _create_or_find_node( Node3D, terrain, "Grass" )
	terrain_overlay = _create_or_find_node( MeshInstance3D, self, "Overlay" )
	terrain_body = _create_or_find_node( StaticBody3D, terrain, "Body" )
	terrain_collider = _create_or_find_node( CollisionShape3D, terrain_body, "Collider" )
	
	# Setup terrain
	if not terrain.mesh:
		terrain.mesh = ArrayMesh.new()
	if not terrain.material_override:
		terrain.material_override = StandardMaterial3D.new()
		terrain.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not terrain_collider.shape:
		terrain_collider.shape = ConcavePolygonShape3D.new()
	
	terrain_body.set_collision_layer_value( PluginLandscaper.COLLISION_LAYER, true )
	terrain.set_display_folded( true )
	
	# Setup grass
	if not grass_mesh:
		grass_mesh = QuadMesh.new()
		grass_mesh.material = ShaderMaterial.new()
		grass_mesh.material.shader = load("res://addons/brush_landscaper/shaders/grass_shader.gdshader").duplicate()
	
	# Setup terrain overlay
	terrain_overlay.mesh = terrain_mesh
	terrain_overlay.position.y = BRUSH_HEIGHT_ON_IDLE
	terrain_overlay.owner = owner #[TEST] set to self
	terrain_overlay.mesh = terrain.mesh
	
	terrain_overlay.material_override = ShaderMaterial.new()
	terrain_overlay.material_override.shader = load("res://addons/brush_landscaper/shaders/terrain_overlay_shader.gdshader")
	terrain_overlay.material_override.set_shader_parameter( "brush_texture", load("res://addons/brush_landscaper/textures/default_brush.tres") )

func _create_or_find_node(new_node_type, parent:Node, node_name:String) -> Node:
	var found_node:Node = parent.get_node_or_null( node_name )
	if found_node:
		print("Found node: ", found_node)
		return found_node
	
	# Yeah, I'm also surprised this works!
	var new_node:Node = new_node_type.new()
	parent.add_child( new_node )
	new_node.owner = parent.owner
	new_node.name = node_name
	print("Created node: ", new_node)
	return new_node


func exit_terrain():
	print("Exit")

func over_terrain(pos:Vector3):
	var color:Color = brushes[DockUI.active_brush].out_color
	terrain_overlay.material_override.set_shader_parameter("brush_color", color)
	
	var size:Vector2 = brushes[Brush.TERRAIN_BUILDER].bounds_size
	var pos_rel:Vector2 = Vector2(pos.x, pos.z) / size - Vector2(0.5, 0.5)
	terrain_overlay.material_override.set_shader_parameter("brush_position", pos_rel)

func paint(pos:Vector3, main_action:bool):
	brushes[DockUI.active_brush].paint( pos, main_action )
	terrain_overlay.position.y = BRUSH_HEIGHT_ON_ACTION

func paint_end():
	terrain_overlay.position.y = BRUSH_HEIGHT_ON_IDLE

func scale(sca:float):
	DockUI.brush_size.value += sca
	terrain_overlay.material_override.set_shader_parameter("brush_scale", DockUI.brush_size.value/100)

