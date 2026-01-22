@tool
extends GLValidator
class_name GLValidatorTerrain


func _validate_ready() -> bool:
	_controller = _controller as GLControllerTerrain
	if not _controller:
		GLDebug.error("Inizialization is not possible: Controller '%s' is not a GLControllerTerrain instance. Assign it correctly in _setup_controller() and restart this scene" %_controller.name)
		return false
	if not _controller.builder:
		GLDebug.error("Inizialization is not possible: There's no builder in _controller '%s'. Make sure to set one on _setup_controller() and restart this scene" %_controller.name)
		return false
	if not _controller.brushes:
		GLDebug.error("Inizialization is not possible: There's no brushes in _controller '%s'. Make sure to set at least one on _setup_controller() and restart this scene" %_controller.name)
		return false
	
	# Fill with global shader and material if none
	if not _controller.shader:
		_controller.shader = AssetsManager.load_controller_resource("terrain", "shader.gdshader")
	if not _controller.material:
		_controller.material = AssetsManager.load_controller_resource("terrain", "material.tres")
	
	if not _controller.source:
		_controller.source = GLBuildDataTerrain.new()
	return true



func _validate_select_brush(brush:GLBrush) -> bool:
	if not _validate_ready():
		return false
	if not brush:
		GLDebug.error("Selecting brush is not possible: Brush is null. Check if GLInspectorManager has thrown any errors")
		return false
	return true


func _validate_stroke_start(scan_data:GLScanData) -> bool:
	if not _controller is GLControllerTerrain:
		GLDebug.error("Stroke start is not possible: Controller '%s' is not a GLControllerTerrain instance. Assign it correctly in _setup_controller() and restart this scene" %_controller.name)
		return false
	
	_controller = _controller as GLControllerTerrain
	if not _controller.is_ready:
		GLDebug.error("Stroke start is not possible: Controller '%s' has flag is_ready=false. Try closing and opening the current scene so _ready() can be executed again, then inspect any initialization errors" %_controller.name)
		return false
	
	if not _controller.current_brush:
		GLDebug.error("Stroke start is not possible: There's no current_brush in _controller '%s'. The controller should have assigned it in select_brush(brush), then restart this scene" %_controller.name)
		return false
	
	if _controller.effects.any(func(e:GLEffect): return e.is_applied):
		GLDebug.warning("An effect is marked as applied. Results might not be as expected; clear effects before stroking then apply effects at the end manually")
	
	if _controller.terrain and (not is_instance_valid(_controller.terrain) or not _controller.terrain.is_inside_tree()):
		GLDebug.warning("terrain='%s' is set but its invalid. It was cleaned up" %_controller.terrain)
		_controller.terrain = null
	
	# Fill with global shader and material if none
	if not _controller.shader:
		_controller.shader = AssetsManager.load_controller_resource("terrain", "shader.gdshader")
	if not _controller.material:
		_controller.material = AssetsManager.load_controller_resource("terrain", "material.tres")
	if not _controller.brush_shape:
		_controller.brush_shape = AssetsManager.load_controller_resource("terrain", "brush_shape.tres")
	
	# The only type capable of image processing is ImageTexture
	if not _controller.texture:
		_controller.texture = ImageTexture.new()
	if not _controller.texture is ImageTexture:
		_controller.texture = ImageTexture.create_from_image( _controller.texture.get_image() )
	
	if not _controller.terrain:
		_controller.terrain = SceneManager.find_or_create_node(MeshInstance3D, _controller, _controller.name)
		GLDebug.warning("Auto selected MeshInstance3D '%s'. If this is not your intention please select the node manually" %_controller.name)
	if not _controller.terrain.mesh:
		_controller.terrain.mesh = ArrayMesh.new()
	if not _controller.source:
		_controller.source = GLBuildDataTerrain.new()
	
	# Force set values
	_controller.material.shader = _controller.shader
	_controller.terrain.material_override = _controller.material
	_controller.material.set_shader_parameter( "albedo_texture", _controller.texture )
	return true



func _validate_stroke_primary(scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_secondary(scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_end() -> bool:
	return true


func _validate_clear_effects() -> bool:
	return true


func _validate_apply_effects() -> bool:
	return true
	
	
