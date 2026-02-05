@tool
extends GLValidator
class_name GLValidatorTerrain


func _validate_initialization() -> bool:
	_controller = _controller as GLControllerTerrain
	if not _controller.brush_shape:
		_controller.brush_shape = GLAssetsManager.load_controller_resource("terrain", "brush_shape.tres").duplicate(true)
	if not _controller.source:
		_controller.source = GLBuildDataTerrain.new()
	if not _controller.source.material:
		_controller.source.material = ShaderMaterial.new()
	if not _controller.source.shader:
		_controller.source.shader = GLAssetsManager.load_controller_resource("terrain", "shader.gdshader")
	return true


func _validate_select_brush(brush:GLBrush) -> bool:
	return true


func _validate_stroke_start(scan_data:GLScanData) -> bool:
	_controller = _controller as GLControllerTerrain
	if _controller.terrain and (not is_instance_valid(_controller.terrain) or not _controller.terrain.is_inside_tree()):
		GLDebug.warning("terrain='%s' is set but its invalid. It was cleaned up" %_controller.terrain)
		_controller.terrain = null
	
	if not _controller.brush_shape:
		_controller.brush_shape = GLAssetsManager.load_controller_resource("terrain", "brush_shape.tres").duplicate(true)
	if not _controller.source:
		_controller.source = GLBuildDataTerrain.new()
	
	var source:GLBuildDataTerrain = _controller.source
	if not source.uvs_map.is_empty() and source.uvs_map.size() != source.vertices_map.size():
		GLDebug.error("Stroke Start Failed: Vertex maps size '%s' do not match UVs map size '%s'. Fix UVs map or clear it to regenerate it" %[source.vertices_map.size(), source.uvs_map.size()])
		return false
	
	if not source.shader:
		source.shader = GLAssetsManager.load_controller_resource("terrain", "shader.gdshader")
	if not source.material:
		source.material = ShaderMaterial.new()
	
	# The only type capable of image processing is ImageTexture
	if not source.texture:
		source.texture = ImageTexture.new()
	if not source.texture is ImageTexture:
		GLDebug.warning("Texture type '%s' was converted to ImageTexture for image processing. Convert back manually to restore" %source.texture.get_class())
		source.texture = ImageTexture.create_from_image( source.texture.get_image() )
	if source.texture.get_size() <= Vector2.ZERO:
		var terrain_rect:Rect2i = GLBrushTerrainBuider.get_bounding_box_from_mesh( _controller.terrain )
		var terrain_size_px:Vector2i = GLBrushTerrainPaint.meters_to_pixels( terrain_rect.size )
		var image:Image = GLBrushTerrainPaint.create_image( terrain_size_px, _controller.primary_color )
		source.texture.set_image( image )
	
	# Create terrain
	if not _controller.terrain:
		_controller.terrain = GLSceneManager.find_or_create_node(MeshInstance3D, _controller, _controller.name)
		GLDebug.warning("Auto selected MeshInstance3D '%s'. If this is not your intention please select the node manually" %_controller.name)
	if not _controller.terrain.mesh:
		_controller.terrain.mesh = ArrayMesh.new()
	
	# Force set values
	source.material.shader = source.shader
	source.material.set_shader_parameter( "terrain_texture", source.texture )
	_controller.terrain.material_override = source.material
	return true



func _validate_stroke_primary(scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_secondary(scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_end() -> bool:
	return true


func _validate_rebuild_from_source() -> bool:
	_controller = _controller as GLControllerTerrain
	if not _controller.source is GLBuildDataTerrain:
		GLDebug.error("Rebuild From Source Failed: 'source' is null. Create or load one under 'GLController > Source'")
		return false
	
	var source:GLBuildDataTerrain = _controller.source
	if not source.uvs_map.is_empty() and source.uvs_map.size() != source.vertices_map.size():
		GLDebug.error("Stroke Start Failed: Vertex maps size '%s' do not match UVs map size '%s'. Fix UVs map or clear it to regenerate it" %[source.vertices_map.size(), source.uvs_map.size()])
		return false
	
	if _controller.terrain and (not is_instance_valid(_controller.terrain) or not _controller.terrain.is_inside_tree()):
		GLDebug.warning("terrain='%s' is set but its invalid. It was cleaned up" %_controller.terrain)
		_controller.terrain = null
	
	if not source.shader:
		source.shader = GLAssetsManager.load_controller_resource("terrain", "shader.gdshader")
	if not source.material:
		source.material = ShaderMaterial.new()
	
	# The only type capable of image processing is ImageTexture
	if not source.texture:
		source.texture = ImageTexture.new()
	if not source.texture is ImageTexture:
		GLDebug.warning("Texture type '%s' was converted to ImageTexture for image processing. Convert back manually to restore" %source.texture.get_class())
		source.texture = ImageTexture.create_from_image( source.texture.get_image() )
	if source.texture.get_size() <= Vector2.ZERO:
		var terrain_rect:Rect2i = GLBrushTerrainBuider.get_bounding_box_from_mesh( _controller.terrain )
		var terrain_size_px:Vector2i = GLBrushTerrainPaint.meters_to_pixels( terrain_rect.size )
		var image:Image = GLBrushTerrainPaint.create_image( terrain_size_px, _controller.primary_color )
		source.texture.set_image( image )
		GLDebug.warning("Texture has been resized to match terrain size of '%s'" %terrain_size_px)
	
	# Create terrain
	if not _controller.terrain:
		_controller.terrain = GLSceneManager.find_or_create_node(MeshInstance3D, _controller, _controller.name)
		GLDebug.warning("Auto selected MeshInstance3D '%s'. If this is not your intention please select the node manually" %_controller.name)
	if not _controller.terrain.mesh:
		_controller.terrain.mesh = ArrayMesh.new()
	
	# Force set values
	source.material.shader = source.shader
	source.material.set_shader_parameter( "terrain_texture", source.texture )
	_controller.terrain.material_override = source.material
	return true


func _validate_clear_effects() -> bool:
	_controller = _controller as GLControllerTerrain
	if not _controller.terrain:
		GLDebug.error("Clear Effects Failed: 'terrain' is null. Assign one under GLControllerTerrain > Multimesh Instance")
		return false
	return true


func _validate_apply_effects() -> bool:
	_controller = _controller as GLControllerTerrain
	if not _controller.terrain:
		GLDebug.error("Apply Effects Failed: 'terrain' is null. Assign one under GLControllerTerrain > Multimesh Instance")
		return false
	return true
	
	
