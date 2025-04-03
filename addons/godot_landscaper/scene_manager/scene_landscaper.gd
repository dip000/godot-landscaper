@tool
extends Node3D
class_name SceneLandscaper
## Hosts and updates the scene references.
## Use the "Landscaper" Tab on the UI Dock to create, remove, save, or load a terrain.


## Project save/load data. Do not use. Do not delete. Do not replace. Use the "Landscaper" UI Dock
@export_storage var project:ProjectLandscaper

# Scene references for managers and brushes
var terrain:MeshInstance3D
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
