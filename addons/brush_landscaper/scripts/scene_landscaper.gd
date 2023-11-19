@tool
extends Node
class_name SceneLandscaper
## Creates a new 'paint-brush-able' terrain. Use "Landscaper" tab in the UI Dock
# Keeps track of scene references


## Raw save/load data. Do not use. Do not delete. Do not replace. Use the "Landscaper" UI Dock
@export var raw:RawLandscaper

# Scene references for managers and brushes
var terrain:MeshInstance3D
var terrain_overlay:MeshInstance3D
var grass_holder:Node3D
var terrain_body:StaticBody3D
var terrain_collider:CollisionShape3D
var overlay_body:StaticBody3D
var overlay_collider:CollisionShape3D

# Stores the grass mesh and sends it to each multimesh grass, if any
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
	if Engine.is_editor_hint():
		# Wait a frame to let this node finish its ready cycle first
		_fix_terrain.call_deferred()


func _fix_terrain():
	# Create or find nodes
	terrain = _create_or_find_node( MeshInstance3D, self , "Terrain" )
	terrain_body = _create_or_find_node( StaticBody3D, terrain, "Body" )
	terrain_collider = _create_or_find_node( CollisionShape3D, terrain_body, "Collider" )
	grass_holder = _create_or_find_node( Node3D, terrain, "Grass" )
	
	terrain_overlay = _create_or_find_node( MeshInstance3D, self, "Overlay" )
	overlay_body = _create_or_find_node( StaticBody3D, terrain_overlay, "Body" )
	overlay_collider = _create_or_find_node( CollisionShape3D, overlay_body, "Collider" )
	
	# Setup terrain
	if not terrain.mesh:
		terrain.mesh = ArrayMesh.new()
	if not terrain.material_override:
		terrain.material_override = StandardMaterial3D.new()
		terrain.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not terrain_collider.shape:
		terrain_collider.shape = HeightMapShape3D.new()
		terrain_collider.hide()
	
	terrain_body.set_collision_layer_value( PluginLandscaper.COLLISION_LAYER_TERRAIN, true )
	terrain.set_display_folded( true )
	
	# Setup grass
	if not grass_mesh:
		grass_mesh = QuadMesh.new()
		grass_mesh.material = ShaderMaterial.new()
		grass_mesh.material.shader = AssetsManager.GRASS_SHADER.duplicate()
	
	# Setup terrain overlay
	terrain_overlay.mesh = terrain.mesh
	terrain_overlay.position.y = 0.13
	terrain_overlay.owner = self
	overlay_collider.shape = BoxShape3D.new()
	overlay_collider.shape.size = Vector3(100, 0.1, 100)
	
	overlay_body.set_collision_layer_value( PluginLandscaper.COLLISION_LAYER_OVERLAY, true )
	terrain_overlay.set_display_folded( true )
	
	terrain_overlay.material_override = ShaderMaterial.new()
	terrain_overlay.material_override.shader = AssetsManager.TERRAIN_OVERLAY_SHADER
	terrain_overlay.material_override.set_shader_parameter( "brush_texture", AssetsManager.DEFAULT_BRUSH )


func _create_or_find_node(new_node_type, parent:Node, node_name:String) -> Node:
	var found_node:Node = parent.get_node_or_null( node_name )
	if found_node:
		return found_node
	
	# Yeah, I'm also surprised this works!
	var new_node:Node = new_node_type.new()
	parent.add_child( new_node )
	new_node.owner = parent.owner
	new_node.name = node_name
	return new_node

