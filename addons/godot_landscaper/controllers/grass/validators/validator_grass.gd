@tool
extends GLValidator
class_name GLValidatorGrass


func validate_ready() -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller:
		GLDebug.error("There's no _controller assigned. Make sure to set one on _setup_controller()")
		return false
	if not _controller.builder:
		GLDebug.error("There's no builder in _controller %s. Make sure to set one on _setup_controller()" %_controller.name)
		return false
	if not _controller.brush_tabs:
		GLDebug.error("There's no brush_tabs in _controller %s. Make sure to set at least one on _setup_controller()" %_controller.name)
		return false
	
	# Fill with global shader and material if none
	if not _controller.shader:
		_controller.shader = AssetsManager.grass.shader
	if not _controller.material:
		_controller.material = AssetsManager.grass.material
	
	# Fill with a demo if the mesh is missing
	if not _controller.mesh:
		_controller.mesh = AssetsManager.grass.mesh_textured_polyquad
		_controller.texture_instance = AssetsManager.grass.texture_polyquad
		_controller.texture_array = Texture2DArray.new()
		_controller.name = "PolyquadGrass"
		_controller.texture_detail_color = Color.SEA_GREEN
	
	if not _controller.source:
		_controller.source = GLBuildDataGrass.new()
	return true


func validate_select_brush(brush:GLBrush) -> bool:
	if not validate_ready():
		return false
	if not brush:
		GLDebug.error("There's no brush to select for _controller %s. Make sure all tabs have brushes in res://addons/godot_landscaper/assets_manager/tabs/*" %_controller.name)
		return false
	return true


func validate_stroke_start(hit_info:Dictionary) -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller is GLControllerGrass:
		GLDebug.error("Controller '%s' is not a GLControllerGrass instance. I don't know why would this happen though" %_controller.name)
		return false
	
	if not _controller.is_ready:
		GLDebug.error("Controller '%s' has not been initialized correctly. Try closing and opening the current scene" %_controller.name)
		return false
	
	if not _controller.current_brush:
		GLDebug.error("There's no brush resource in selected tab of _controller '%s'. Make sure all GLInspectorTab resources in 'assets_manager/tabs/' have non-null brushes" %_controller.name)
		return false
	
	if _controller.effects.any(func(e:GLEffect): return e.is_applied):
		GLDebug.warning("An effect is marked as applied. Results might not be as espected; clear effects to stroke then apply effects at the end")
	
	# Fill with global shader and material if none
	if not _controller.shader:
		_controller.shader = AssetsManager.grass.shader
	if not _controller.material:
		_controller.material = AssetsManager.grass.material
	if not _controller.texture_array:
		_controller.texture_array = Texture2DArray.new()
	
	# Fill with a demo if the mesh is missing
	if not _controller.mesh:
		_controller.mesh = AssetsManager.grass.mesh_textured_polyquad
		_controller.texture_instance = AssetsManager.grass.texture_polyquad
		_controller.texture_array = Texture2DArray.new()
		_controller.name = "PolyquadGrass"
		_controller.texture_detail_color = Color.SEA_GREEN
		GLDebug.warning("A mesh was not selected so a demo was loaded. To visualize it fully, please bake the layer texture by pressing the button under GLControllerGrass.texture -> Bake Texture Layer")
	
	# Force set values
	_controller.material.shader = _controller.shader
	_controller.mesh.surface_set_material(0, _controller.material)
	
	# Complain about texture configuration missmatch
	if _controller.texture_instance and _controller.texture_layer < 0:
		GLDebug.warning("You've set a texture but the instance index is invalid and textures will not be show. Set settings.texture_layer>=0 and bake the texture")
	
	var collider:Node = hit_info.get("collider")
	if not _controller.multimesh_instance and collider:
		var brush_surface:Node3D = GLScanner.scan_mesh( collider, _controller )
		var parent:Node3D = brush_surface if brush_surface else self
		_controller.multimesh_instance = SceneManager.find_or_create_node(MultiMeshInstance3D, parent, _controller.name)
		GLDebug.warning("Auto selected MultiMeshInstance '%s'. If this is not your intention please select the node manually" %_controller.multimesh_instance.name)
	
	_controller.multimesh_instance = _format_mmi( _controller.multimesh_instance )
	
	if not _controller.source:
		_controller.source = GLBuildDataGrass.new()
	
	return true


func validate_stroke_primary(hit_info:Dictionary) -> bool:
	return true


func validate_stroke_secondary(hit_info:Dictionary) -> bool:
	return true


func validate_stroke_end() -> bool:
	return true


func validate_clear_effects() -> bool:
	if not _controller.multimesh_instance:
		_controller.multimesh_instance = SceneManager.find_or_create_node( MultiMeshInstance3D, _controller, _controller.name )
		GLDebug.warning("multimesh_instance is null. A new one was creater under the controller, move it if this is not your intention")
	_controller.multimesh_instance = _format_mmi( _controller.multimesh_instance )
	return true


func validate_apply_effects() -> bool:
	_controller = _controller as GLControllerGrass
	if _controller.effects:
		var clean_empty:Callable = func (effect:GLEffect): return effect
		_controller.effects = _controller.effects.filter( clean_empty )
	else:
		GLDebug.warning("Effects are empty. Append them under GLController > Effects")
	
	if not _controller.multimesh_instance:
		_controller.multimesh_instance = SceneManager.find_or_create_node( MultiMeshInstance3D, _controller, _controller.name )
		GLDebug.warning("multimesh_instance is null. A new one was creater under the controller, move it if this is not your intention")
	_controller.multimesh_instance = _format_mmi( _controller.multimesh_instance )
	return true


func validate_texture_bake() -> bool:
	_controller = _controller as GLControllerGrass
	if not _controller.builder:
		GLDebug.error("There's no builder in _controller %s. Make sure to set one on _setup_controller()" %_controller.name)
		return false
	
	if not _controller.texture_baker:
		GLDebug.error("There's no texture_baker in _controller %s. Make sure to set one on _setup_controller()" %_controller.name)
		return false
	return true


func validate_texture_clear() -> bool:
	return validate_texture_bake()


func _format_mmi(mmi:MultiMeshInstance3D) -> MultiMeshInstance3D:
	if not mmi.multimesh:
		mmi.multimesh = MultiMesh.new()
		mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mmi.multimesh.use_colors = true
		mmi.multimesh.use_custom_data = true
	mmi.multimesh.mesh = _controller.mesh
	mmi.set_instance_shader_parameter("texture_layer", _controller.texture_layer)
	return mmi
