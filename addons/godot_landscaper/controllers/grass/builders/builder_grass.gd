## BUILDER GRASS: 
##

@tool
extends GLBuilder
class_name GLBuilderGrass


func build(stroke_data:GLBuildData, controller:GLController) -> bool:
	var mmi:MultiMeshInstance3D = controller.mmi
	var mm:MultiMesh = mmi.multimesh
	mm.instance_count = stroke_data.transforms.size()
	
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, stroke_data.transforms[i] )
		mm.set_instance_color( i, stroke_data.bottom_colors[i] )
		mm.set_instance_custom_data( i, stroke_data.top_colors[i] )
	return true
	
