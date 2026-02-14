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


func _validate_stroke_start(action:GLandscaper.Action, scan_data:GLScanData) -> bool:
	_controller = _controller as GLControllerPackedScene
	if not _controller.holder:
		_controller.holder = _controller
	if not _controller.source:
		_controller.source = GLBuildDataPackedScene.new()
	if not _controller.source.scene:
		GLTemplaterPackedScene.load_random_template( _controller )
	return true


func _validate_stroking(action:GLandscaper.Action, scan_data:GLScanData) -> bool:
	return true


func _validate_stroke_end(action:GLandscaper.Action) -> bool:
	return true


func _validate_rebuild_from_source() -> bool:
	_controller = _controller as GLControllerPackedScene
	if not _controller.holder:
		_controller.holder = _controller
	if not _controller.source:
		GLDebug.error("Rebuild From Source Failed: Source is null. Create or load a source under 'GLController > Source'")
		return false
	if not _controller.source.scene:
		GLDebug.error("Rebuild From Source Failed: Scene is null. Select a PackedScene to instance under 'GLController > Source > Scene'")
		return false
	return true


func _validate_clear_effects() -> bool:
	_controller = _controller as GLControllerPackedScene
	if not _controller.holder:
		_controller.holder = _controller
	return true


func _validate_apply_effects() -> bool:
	_controller = _controller as GLControllerPackedScene
	if not _controller.holder:
		_controller.holder = _controller
	return true
	
	












	
