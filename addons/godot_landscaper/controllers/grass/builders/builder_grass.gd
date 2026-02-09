## Grass Builder. Based on MultiMeshInstance3D
##
## 

@tool
extends GLBuilder
class_name GLBuilderGrass


func build_from_dirty() -> bool:
	return _build( _controller.source, _controller.multimesh_instance.multimesh )


func build_from_source() -> bool:
	return _build( _controller.source, _controller.multimesh_instance.multimesh )


func build_from_processed() -> bool:
	return _build( _controller.processed, _controller.multimesh_instance.multimesh )


func _build(build_data:GLBuildDataGrass, mm:MultiMesh) -> bool:
	mm.instance_count = build_data.size()
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, build_data.transforms[i] )
		mm.set_instance_color( i, build_data.top_colors[i] )
		mm.set_instance_custom_data( i, build_data.bottom_colors[i] )
	return true
	
