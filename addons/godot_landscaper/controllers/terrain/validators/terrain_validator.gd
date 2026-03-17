@tool
extends GLValidator
class_name GLValidatorTerrain


func _validate_initialization() -> bool:
	_controller = _controller as GLControllerTerrain
	if not _initialize_resources():
		return false
	return true


func _validate_select_brush(brush:GLBrush) -> bool:
	return true


func _validate_stroke_start(action:GLandscaper.Action, scan_data:GLScanData) -> bool:
	_controller = _controller as GLControllerTerrain
	if _controller.terrain and (not is_instance_valid(_controller.terrain) or not _controller.terrain.is_inside_tree()):
		GLDebug.warning("terrain='%s' is set but it's invalid. It was cleaned up" %_controller.terrain)
		_controller.terrain = null
	
	if not _initialize_resources():
		return false
	
	var source:GLBuildDataTerrain = _controller.source
	if not source.uvs_map.is_empty() and source.uvs_map.size() != source.vertices_map.size():
		GLDebug.error("Stroke Start Failed: Vertex maps size '%s' do not match UVs map size '%s'. Fix UVs map or clear it to regenerate it" %[source.vertices_map.size(), source.uvs_map.size()])
		return false
	
	if not _cleanup_layers():
		return false
	return true



func _validate_stroking(action:GLandscaper.Action, scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_end(action:GLandscaper.Action) -> bool:
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
	
	if not _initialize_resources():
		return false
	
	if not _cleanup_layers():
		return false
	
	source.layers = GLPaintLayer.compose_sampler_outputs( _controller.layers )
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


func _initialize_resources() -> bool:
	if not _controller.primary_paint_stencil:
		_controller.primary_paint_stencil = GLAssetsManager.load_controller_resource("terrain", "paving_stones.svg").duplicate(true)
	if not _controller.secondary_paint_stencil:
		_controller.secondary_paint_stencil = GLAssetsManager.load_controller_resource("terrain", "brush_shape.tres").duplicate(true)
	if not _controller.source:
		_controller.source = GLBuildDataTerrain.new()
	if not _controller.source.material:
		_controller.source.material = GLAssetsManager.load_controller_resource("terrain", "material.tres").duplicate( true )
	if not _controller.source.shader:
		_controller.source.shader = GLAssetsManager.load_controller_resource("terrain", "terrain_shader.gdshader")
	if not _controller.layers:
		_controller.layers.resize(1)
		_controller.layers[0] = GLPaintLayer.new()
	return true
	

func _cleanup_layers() -> bool:
	var layers:Array[GLPaintLayer] = _controller.layers
	var any_active:bool = false
	
	for layer in layers:
		if not layer:
			continue
		if layer.active:
			any_active = true
		if not layer.texture:
			var terrain_rect:Rect2i = GLBrushTerrainBuider.get_bounding_box_from_mesh( _controller.terrain )
			var terrain_size_px:Vector2i = layer.meters_to_pixels( terrain_rect.size )
			var image:Image = GLBrushTerrainPaint.create_image( terrain_size_px, Color.TRANSPARENT )
			layer.texture = ImageTexture.create_from_image( image )
	
	if not any_active:
		GLDebug.error("Cleanup Layers Failed: No layer is active. Make sure at least there's one layer enabled to paint.")
		return false
		
	_controller.layers = layers
	return true
	








	
