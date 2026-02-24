@tool
extends GLValidator
class_name GLValidatorGrass


func _validate_initialization() -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller.source:
		_controller.source = GLBuildDataGrass.new()
	var source:GLBuildDataGrass = _controller.source
	if not source.shader:
		source.shader = GLAssetsManager.load_controller_resource("grass", "grass_shader.gdshader")
	if not source.material:
		source.material = GLAssetsManager.load_controller_resource("grass", "material.tres")
	if not source.texture_array_layer:
		source.texture_array_layer = GLTextureAtlasLayer.new()
	return true


func _validate_select_brush(brush:GLBrush) -> bool:
	return true


func _validate_stroke_start(action:GLandscaper.Action, scan_data:GLScanData) -> bool:
	_controller = _controller as GLControllerGrass
	if _controller.multimesh_instance and (not is_instance_valid(_controller.multimesh_instance) or not _controller.multimesh_instance.is_inside_tree()):
		GLDebug.warning("multimesh_instance='%s' is set but its invalid. It was cleaned up" %_controller.multimesh_instance.name)
		_controller.multimesh_instance = null
	
	if not _controller.source:
		_controller.source = GLBuildDataGrass.new()
	var source:GLBuildDataGrass = _controller.source
	
	if not source.mesh:
		GLTemplaterGrass.load_random_template( _controller )
	if not _controller.multimesh_instance:
		_controller.multimesh_instance = GLSceneManager.find_or_create_node(MultiMeshInstance3D, _controller, _controller.name)
		GLDebug.warning("Auto selected MultiMeshInstance '%s'. If this is not your intention please select the node manually" %_controller.multimesh_instance.name)
	
	if not source.shader:
		source.shader = GLAssetsManager.load_controller_resource("grass", "grass_shader.gdshader")
	if not source.material:
		source.material = GLAssetsManager.load_controller_resource("grass", "material.tres")
	if not source.texture_array_layer:
		source.texture_array_layer = GLTextureAtlasLayer.new()
	if source.texture_array_layer.texture_array:
		source.material.set_shader_parameter("texture_array", source.texture_array_layer.texture_array)
	
	# Force set values
	_format_mmi( _controller )
	source.material.shader = source.shader
	source.mesh.surface_set_material(0, source.material)
	return true


func _validate_stroking(action:GLandscaper.Action, scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_end(action:GLandscaper.Action) -> bool:
	return true


func _validate_rebuild_from_source() -> bool:
	_controller = _controller as GLControllerGrass
	if _controller.multimesh_instance and (not is_instance_valid(_controller.multimesh_instance) or not _controller.multimesh_instance.is_inside_tree()):
		GLDebug.warning("multimesh_instance='%s' is set but its invalid. It was cleaned up" %_controller.multimesh_instance.name)
		_controller.multimesh_instance = null
	if not _controller.multimesh_instance:
		GLDebug.error("Rebuild From Source Failed: multimesh_instance is null. Assign a multimesh_instance under Inspector > Brushes > Multimesh Instance")
		return false
	_format_mmi( _controller )
	return true


func _validate_clear_effects() -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller.multimesh_instance:
		GLDebug.error("Clear Effects Failed: multimesh_instance is null. Assign a multimesh_instance under Inspector > Brushes > Multimesh Instance")
		return false
	_format_mmi( _controller )
	return true


func _validate_apply_effects() -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller.multimesh_instance:
		GLDebug.error("Apply Effects Failed: 'multimesh_instance' is null. Assign one or create it under 'GLController > Rebuild Source'")
		return false
	_format_mmi( _controller )
	return true


static func validate_texture_bake(validator:GLValidatorGrass) -> bool:
	if not validate_base( validator ):
		GLDebug.error("Texture Array Layer Failed: 'texture_texture' is null. Set a texture under 'Brushes > Texture Layers > Texture'")
		return false
	var controller:GLControllerGrass = validator._controller
	
	if not controller.texture_texture:
		GLDebug.error("Texture Array Layer Failed: 'texture_texture' is null. Set a texture under 'Brushes > Texture Layers > Texture'")
		return false
	
	if controller.texture_layer < 0:
		GLDebug.error("Texture Array Layer Failed: Invalid 'texture_layer'. Set to a positive value under 'Brushes > Texture Layers > Layer'")
		return false
	
	if controller.multimesh_instance and (not is_instance_valid(controller.multimesh_instance) or not controller.multimesh_instance.is_inside_tree()):
		controller.multimesh_instance = null
	
	if not controller.multimesh_instance:
		GLDebug.error("Texture Array Layer Failed: 'multimesh_instance' is null. Select one or create it with 'GLController > Rebuild Source'")
		return false
	
	if not controller.source:
		controller.source = GLBuildDataGrass.new()
	var source:GLBuildDataGrass = controller.source
	
	if not source.mesh:
		GLTemplaterGrass.load_random_template( controller )
	
	if not source.shader:
		source.shader = GLAssetsManager.load_controller_resource("grass", "grass_shader.gdshader")
	if not source.material:
		source.material = GLAssetsManager.load_controller_resource("grass", "material.tres")
	if not source.texture_array_layer:
		source.texture_array_layer = GLTextureAtlasLayer.new()
	if not source.texture_array_layer.texture_array:
		source.texture_array_layer.texture_array = GLAssetsManager.load_controller_resource("grass", "texture_atlas.res")
	
	# Force set values
	_format_mmi( controller )
	source.material.shader = source.shader
	source.mesh.surface_set_material(0, source.material)
	source.material.set_shader_parameter("texture_array", source.texture_array_layer.texture_array)
	return true


static func validate_texture_clear(validator:GLValidatorGrass) -> bool:
	if not validate_texture_bake( validator ):
		return false
	var controller:GLControllerGrass = validator._controller
	if controller.texture_layer >= controller.source.texture_array_layer.texture_array.get_layers():
		GLDebug.error("Texture Array Layer Failed. 'texture_array' doesn't have layer '%s'" %controller.texture_layer)
		return false
	return true



static func _format_mmi(controller:GLControllerGrass):
	var mmi:MultiMeshInstance3D = controller.multimesh_instance
	if not mmi.multimesh:
		mmi.multimesh = MultiMesh.new()
		mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mmi.multimesh.use_colors = true
		mmi.multimesh.use_custom_data = true
	mmi.multimesh.mesh = controller.source.mesh
	mmi.multimesh.mesh = controller.source.mesh
	var layer:int = controller.source.texture_array_layer.layer if controller.source.texture_array_layer else -1
	mmi.set_instance_shader_parameter("texture_layer", layer)
	
	
