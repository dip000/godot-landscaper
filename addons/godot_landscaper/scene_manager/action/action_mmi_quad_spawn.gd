@tool
extends ActionMMISpawn
class_name ActionMMIQuadSpawn


func start(instance:Instancer):
	# Add Multimesh if needed
	mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, instance.root_node, instance.resource_name )
	if not mmi.multimesh:
		instance.mesh.surface_set_material( 0, AssetsManager.MATERIAL )
		mmi.multimesh = MultiMesh.new()
		mmi.multimesh.mesh = instance.mesh
		mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mmi.multimesh.use_colors = true
		mmi.multimesh.use_custom_data = true
	
	mmi.global_position = instance.surface_position
	mmi.set_instance_shader_parameter("variant_index", instance.instance_index)
	
	#var mat:ShaderMaterial = AssetsManager.MATERIAL
	#mat["shader_parameter/ground_gradient"] = instance.ground_gradient
	#mat["shader_parameter/variants"][instance.instance_index] = instance.texture
	#mat["shader_parameter/enable_details"][instance.instance_index] = int(instance.details_enable)
	#mat["shader_parameter/detail_color"][instance.instance_index] = instance.details_color
	#mmi.multimesh.mesh.subdivide_depth = instance.quality
	#mmi.multimesh.mesh.center_offset.z = -instance.size_base.y*0.5
	# Initialize
	_get_all( instance )
