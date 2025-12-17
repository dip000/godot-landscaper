## BUILDER GRASS: 
##

@tool
extends GLBuilder
class_name GLBuilderGrass


func build(mm:MultiMesh, build_data:GLBuildData) -> bool:
	mm.instance_count = build_data.transforms.size()
	
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, build_data.transforms[i] )
		mm.set_instance_color( i, build_data.top_colors[i] )
		mm.set_instance_custom_data( i, build_data.bottom_colors[i] )
	return true
	
