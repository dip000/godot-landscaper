## 
@tool
extends GLValidator
class_name GLValidatorPackedScene


func _validate_initialization() -> bool:
	_controller = _controller as GLControllerPackedScene
	if not _controller.holder:
		_controller.holder = _controller
	if not _controller.source:
		_controller.source = GLBuildDataPackedScene.new()
	return true


func _validate_select_brush(brush:GLBrush) -> bool:
	return true


func _validate_stroke_start(scan_data:GLScanData) -> bool:
	_controller = _controller as GLControllerPackedScene
	if not _controller.holder:
		_controller.holder = _controller
	if not _controller.source:
		_controller.source = GLBuildDataPackedScene.new()
	if not _controller.source.scene:
		_controller.source.scene = GLAssetsManager.load_controller_resource( "packed_scene", "tree.glb" )
		_controller.name = "PackedSceneTree"
		GLDebug.state("A template scene was loaded. Use your own scenes under 'GLController > Source > Scene'")
	return true



func _validate_stroke_primary(scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_secondary(scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_end() -> bool:
	return true


func _validate_rebuild_from_source() -> bool:
	_controller = _controller as GLControllerPackedScene
	if not _controller.holder:
		_controller.holder = _controller
	if not _controller.source:
		GLDebug.error("Rebuild From Source Failed: Source is null. Create or load a source under 'GLController > Source'")
	if not _controller.source.scene:
		GLDebug.error("Rebuild From Source Failed: Scene is null. Select a PackedScene to instance under 'GLController > Source > Scene'")
	return true


func _validate_clear_effects() -> bool:
	return true


func _validate_apply_effects() -> bool:
	return true
	
	












	
