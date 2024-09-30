@tool
extends Node
class_name SceneLandscaper
## Hosts and updates the scene references.
## Use the "Landscaper" Tab on the UI Dock to create, remove, save, or load a terrain.


## Project save/load data. Do not use. Do not delete. Do not replace. Use the "Landscaper" UI Dock
@export var project:ProjectLandscaper

# When the scene or the editor is closed, this variable will be automatically reseted to false
# Altough you could say the same for any other non-export variable, it's good to be explicit
var updated:bool = false

# Scene references for managers and brushes
var terrain:MeshInstance3D
var overlay:TerrainOverlay
var grass_holder:Node3D
var instance_holder:Node3D
var body:StaticBody3D
var collider:CollisionShape3D

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


func update_terrain():
	# Create or find nodes
	terrain = _create_or_find_node( MeshInstance3D, self , "Terrain" )
	body = _create_or_find_node( StaticBody3D, terrain, "Body" )
	collider = _create_or_find_node( CollisionShape3D, body, "Collider" )
	grass_holder = _create_or_find_node( Node3D, terrain, "Grass" )
	instance_holder = _create_or_find_node( Node3D, terrain, "Instances" )
	
	# Setup terrain
	if not terrain_mesh:
		terrain_mesh = ArrayMesh.new()
	if not terrain.material_override:
		terrain.material_override = StandardMaterial3D.new()
		terrain.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not collider.shape:
		collider.shape = HeightMapShape3D.new()
		collider.hide()
	
	terrain.set_display_folded( true )
	
	# Setup grass
	if grass_holder.get_child_count() > 0:
		grass_mesh = grass_holder.get_child(0).multimesh.mesh
	else:
		grass_mesh = QuadMesh.new()
		grass_mesh.material = ShaderMaterial.new()
		grass_mesh.material.shader = AssetsManager.GRASS_SHADER.duplicate()
	
	# Setup terrain overlay
	overlay = get_node_or_null("Overlay")
	if not overlay:
		overlay = AssetsManager.TERRAIN_OVERLAY.instantiate()
		add_child( overlay )
		overlay.owner = self # hides it from scene tree
		overlay.resize(project.canvas.size.x, project.canvas.size.y)
		overlay.snap( terrain.global_position )
	
	updated = true


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


var _prev_snap:Vector3
func _process(delta):
	if updated:
		var terrain:MeshInstance3D = get_child(0)
		var snap:Vector3 = terrain.global_position.round()
		terrain.global_position = snap
		if _prev_snap != snap:
			update_grass_texture()
			overlay.snap( snap )
		_prev_snap = snap

func update_grass_texture():
	var node:Vector3 = terrain.global_position
	var offset:Vector2 = project.world.position + Vector2i(node.x, node.z)
	var texure_size:Vector2 = project.gc_texture.get_size()
	var resolution:Vector2 = texure_size / Vector2(project.world.size)
	
	var world_position = -resolution * offset / texure_size
	grass_mesh.material.set_shader_parameter( "world_position", world_position )



