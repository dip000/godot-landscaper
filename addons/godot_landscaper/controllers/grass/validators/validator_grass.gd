@tool
extends GLValidator
class_name GLValidatorGrass


func _validate_ready() -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller:
		GLDebug.error("Inizialization is not possible: Controller '%s' is not a GLControllerGrass instance. Assign it correctly in _setup_controller() and restart this scene" %_controller.name)
		return false
	if not _controller.builder:
		GLDebug.error("Inizialization is not possible: There's no builder in _controller '%s'. Make sure to set one on _setup_controller() and restart this scene" %_controller.name)
		return false
	if not _controller.brushes:
		GLDebug.error("Inizialization is not possible: There's no brushes in _controller '%s'. Make sure to set at least one on _setup_controller() and restart this scene" %_controller.name)
		return false
	
	# Fill with global shader and material if none
	if not _controller.shader:
		_controller.shader = AssetsManager.load_controller_resource("grass", "shader.gdshader")
	if not _controller.material:
		_controller.material = AssetsManager.load_controller_resource("grass", "material.tres")
	
	# Fill with a demo if the mesh is missing
	if not _controller.mesh:
		GLGrassTemplater.load_random_template( _controller )
	
	if not _controller.source:
		_controller.source = GLBuildDataGrass.new()
	return true


func _validate_select_brush(brush:GLBrush) -> bool:
	if not _validate_ready():
		return false
	if not brush:
		GLDebug.error("Selecting brush is not possible: Brush is null. Check if GLInspectorManager has thrown any errors")
		return false
	return true


func _validate_stroke_start(hit_info:Dictionary) -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller is GLControllerGrass:
		GLDebug.error("Stroke start is not possible: Controller '%s' is not a GLControllerGrass instance. Assign it correctly in _setup_controller() and restart this scene" %_controller.name)
		return false
	
	if not _controller.is_ready:
		GLDebug.error("Stroke start is not possible: Controller '%s' has flag is_ready=false. Try closing and opening the current scene so _ready() can be executed again, then inspect any initialization errors" %_controller.name)
		return false
	
	if not _controller.current_brush:
		GLDebug.error("Stroke start is not possible: There's no current_brush in _controller '%s'. The controller should have assigned it in select_brush(brush), then restart this scene" %_controller.name)
		return false
	
	if _controller.effects.any(func(e:GLEffect): return e.is_applied):
		GLDebug.warning("An effect is marked as applied. Results might not be as expected; clear effects before stroking then apply effects at the end manually")
	
	# Fill with global shader and material if none
	if not _controller.shader:
		_controller.shader = AssetsManager.load_controller_resource("grass", "shader.gdshader")
	if not _controller.material:
		_controller.material = AssetsManager.load_controller_resource("grass", "material.tres")
	if not _controller.texture_array:
		_controller.texture_array = Texture2DArray.new()
	
	# Fill with a demo if the mesh is missing
	if not _controller.mesh:
		GLGrassTemplater.load_random_template( _controller )
		GLDebug.warning("A mesh was not selected so a template was loaded. To visualize it fully, please bake the layer texture by pressing the button under Inspector > Resources > Texture > Bake Texture Into Array")
	
	# Force set values
	_controller.material.shader = _controller.shader
	_controller.mesh.surface_set_material(0, _controller.material)
	
	# Complain about texture configuration missmatch
	if _controller.texture_instance and _controller.texture_layer < 0:
		GLDebug.warning("You've set a texture but the instance index is invalid and textures will not be show. Set texture_layer>=0 and bake the texture under Inspector > Resources > Texture > Layer, .. Bake Texture Into Array")
	
	if _controller.multimesh_instance and not (is_instance_valid(_controller.multimesh_instance) or _controller.multimesh_instance.is_inside_tree()):
		GLDebug.warning("multimesh_instance='%s' is set but its invalid. It was cleaned up" %_controller.multimesh_instance)
		_controller.multimesh_instance = null
	
	# Create a MultiMeshInstance3D under the scanned surface if not selected
	var collider:Node = hit_info.get("collider")
	if not _controller.multimesh_instance and collider:
		var scanner:GLSurfaceScanner = GLSurfaceScanner.new( _controller )
		var brush_surface:Node3D = scanner.scan_mesh( collider )
		var parent:Node3D = brush_surface if brush_surface else self
		_controller.multimesh_instance = SceneManager.find_or_create_node(MultiMeshInstance3D, parent, _controller.name)
		GLDebug.warning("Auto selected MultiMeshInstance '%s'. If this is not your intention please select the node manually" %_controller.multimesh_instance.name)
	
	_controller.multimesh_instance = _format_mmi( _controller.multimesh_instance )
	
	if not _controller.source:
		_controller.source = GLBuildDataGrass.new()
	
	return true


func _validate_stroke_primary(hit_info:Dictionary) -> bool:
	return true


func _validate_stroke_secondary(hit_info:Dictionary) -> bool:
	return true


func _validate_stroke_end() -> bool:
	return true


func _validate_clear_effects() -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller.multimesh_instance:
		GLDebug.warning("Clearing effects is not possible: multimesh_instance is null. Assign a multimesh_instance under Inspector > Brushes > Multimesh Instance")
		return false
	_controller.multimesh_instance = _format_mmi( _controller.multimesh_instance )
	return true


func _validate_apply_effects() -> bool:
	_controller = _controller as GLControllerGrass
	if _controller.effects:
		var clean_empty:Callable = func (effect:GLEffect): return effect
		_controller.effects = _controller.effects.filter( clean_empty )
	else:
		GLDebug.warning("Effects are empty. Append them under GLController > Effects")
	
	if not _controller.multimesh_instance:
		GLDebug.error("Applying effects is not possible: multimesh_instance is null. Assign a multimesh_instance under Inspector > Brushes > Multimesh Instance")
		return false
	_controller.multimesh_instance = _format_mmi( _controller.multimesh_instance )
	
	return true


func _validate_texture_bake() -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller.builder:
		GLDebug.error("Texture bake is not possible: There's no builder in _controller %s. Make sure to set one on _setup_controller()" %_controller.name)
		return false
	
	if not _controller.texture_baker:
		GLDebug.error("Texture bake is not possible: There's no texture_baker in _controller %s. Make sure to set one on _setup_controller()" %_controller.name)
		return false
	
	var requested_layer:int = _controller.texture_layer
	if requested_layer < 0:
		GLDebug.error("Texture bake is not possible: Invalid texture_layer. Set texture_layer to a positive value under Inspector > Brushes > Resources > Texture > Layer")
		return false
	
	var requested_texture:Texture2D = _controller.texture_instance
	if not requested_texture:
		GLDebug.error("Texture bake is not possible: texture_instance is null. Set a texture under Inspector > Brushes > Resources > Texture > Instance")
		return false
	
	return true


func _validate_texture_clear() -> bool:
	return _validate_texture_bake()


func _format_mmi(mmi:MultiMeshInstance3D) -> MultiMeshInstance3D:
	if not mmi.multimesh:
		mmi.multimesh = MultiMesh.new()
		mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mmi.multimesh.use_colors = true
		mmi.multimesh.use_custom_data = true
	mmi.multimesh.mesh = _controller.mesh
	mmi.set_instance_shader_parameter("texture_layer", _controller.texture_layer)
	return mmi
