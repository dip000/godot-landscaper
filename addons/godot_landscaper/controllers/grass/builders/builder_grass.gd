## Grass Builder. Based on MultiMeshInstance3D
##
## 

@tool
extends GLBuilder
class_name GLBuilderGrass


func quick_start(from_data:GLBuildData) -> bool:
	return true


func quick_build(from_data:GLBuildData) -> bool:
	return _build( from_data, _controller.multimesh_instance )


func quick_end(from_data:GLBuildData) -> bool:
	return true


func build(from_data:GLBuildData) -> bool:
	return _build( from_data, _controller.multimesh_instance )


func _build(build_data:GLBuildDataGrass, multimesh_instance:MultiMeshInstance3D) -> bool:
	var mm:MultiMesh = multimesh_instance.multimesh
	mm.instance_count = build_data.size()
	
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, build_data.transforms[i] )
		mm.set_instance_color( i, build_data.top_colors[i] )
		mm.set_instance_custom_data( i, build_data.bottom_colors[i] )
	
	mm.mesh = build_data.mesh
	build_data.material.shader = build_data.shader
	mm.mesh.surface_set_material( 0, build_data.material )
	return true
	






	
