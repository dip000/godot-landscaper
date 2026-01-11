## BUILDER GRASS: 
##

@tool
extends GLBuilder
class_name GLBuilderGrass


func build() -> bool:
	_controller = _controller as GLControllerGrass
	var build_data:GLBuildDataGrass = _controller.source
	var mmi:MultiMeshInstance3D = _controller.multimesh_instance
	var mm:MultiMesh = mmi.multimesh
	mm.instance_count = build_data.size()
	
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, build_data.transforms[i] )
		mm.set_instance_color( i, build_data.top_colors[i] )
		mm.set_instance_custom_data( i, build_data.bottom_colors[i] )
	return true
	
