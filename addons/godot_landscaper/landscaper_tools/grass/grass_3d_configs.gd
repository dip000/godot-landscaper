## Per-instance configuration file for Brush classes
## Managed by LandscaperTool classes
@tool
@icon("res://addons/godot_landscaper/config_icon.svg")
extends InstanceConfigs
class_name Grass3DConfigs

const CAP:int = 8


func load_template():
	rotation_randomize.y = PI

func fix_dependencies():
	if not shader:
		shader = AssetsManager.grass.shader_3d.duplicate()
	if not material:
		material = AssetsManager.grass.material_3d.duplicate()
	material.shader = shader
	if not mesh:
		mesh = AssetsManager.grass.mesh_3d.duplicate()
	mesh.surface_set_material( 0, material )
