## Validator base class.
##
## Used in GLController framework for validating every entry.
## Call from static functions because as they say: "Quis verificat ipsos verificatores".

@tool
@abstract
extends Resource
class_name GLValidator

var _controller:GLController
var validated_ready:bool = false
var validated_start:bool = false


func _init(controller:GLController):
	_controller = controller


@abstract
func _validate_initialization() -> bool
static func validate_initialization(validator:GLValidator) -> bool:
	if not validator:
		GLDebug.error("Inizialization failed: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	if not validator._controller:
		GLDebug.error("Inizialization failed: Controller is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	if not validator._controller.brushes:
		GLDebug.error("Inizialization failed: There's no brushes in _controller '%s'. Make sure to set at least one on _setup_controller() and restart this scene" %validator._controller.name)
		return false
	if not validator._controller.builder:
		GLDebug.error("Inizialization failed: There's no builder in _controller '%s'. Make sure to set one on _setup_controller() and restart this scene" %validator._controller.name)
		return false
	validator.validated_ready = validator._validate_initialization()
	return validator.validated_ready


@abstract
func _validate_select_brush(brush:GLBrush) -> bool
static func validate_select_brush(validator:GLValidator, brush:GLBrush) -> bool:
	if not validate_base( validator ):
		return false
	if not brush:
		GLDebug.error("Select brush failed: Brush is null. Check if GLInspectorManager has thrown any errors")
		return false
	return validator._validate_select_brush( brush )


@abstract
func _validate_stroke_start(action:GLandscaper.Action, scan_data:GLScanData) -> bool
static func validate_stroke_start(validator:GLValidator, action:GLandscaper.Action, scan_data:GLScanData) -> bool:
	if not validate_base( validator ):
		return false
	if not scan_data:
		GLDebug.error("Stroke start failed: scan_data is invalid. Check for GLSceneRaycaster errors")
		return false
	if not validator._controller.brushes:
		GLDebug.error("Stroke start failed: There's no brushes in controller '%s'. Make sure to set at least one on _setup_controller() and restart this scene" %validator._controller.name)
		return false
	if not validator._controller.current_brush:
		GLDebug.error("Stroke start failed: There's no current_brush in controller '%s'. The controller should have been assigned it in select_brush(brush), try re-selecting the brush tab or the controller" %validator._controller.name)
		return false
	if validator._controller.effects.any(func(e:GLEffect): return e.is_applied):
		GLDebug.warning("An effect is marked as applied. Results might not be as expected; clear effects before stroking then apply effects at the end manually")
	validator.validated_start = validator._validate_stroke_start( action, scan_data )
	return validator.validated_start


@abstract
func _validate_stroking(action:GLandscaper.Action, scan_data:GLScanData) -> bool
static func validate_stroking(validator:GLValidator, action:GLandscaper.Action, scan_data:GLScanData) -> bool:
	if not validate_base( validator ):
		return false
	if not validator.validated_start:
		return false
	return validator._validate_stroking( action, scan_data )


@abstract
func _validate_stroke_end(action:GLandscaper.Action) -> bool
static func validate_stroke_end(validator:GLValidator, action:GLandscaper.Action) -> bool:
	if not validate_base( validator ):
		return false
	if not validator.validated_start:
		GLDebug.error("Stroke end failed: Stroke Start was not validated. Check for Stroke Start errors")
		return false
	validator.validated_start = false
	return validator._validate_stroke_end( action )


@abstract
func _validate_rebuild_from_source() -> bool
static func validate_rebuild_from_source(validator:GLValidator) -> bool:
	if not validate_base( validator ):
		return false
	if not validator._controller.source:
		GLDebug.error("Rebuild From Source: 'source' data is null. Create one or load a project")
		return false
	return validator._validate_rebuild_from_source()
	
	
@abstract
func _validate_clear_effects() -> bool
static func validate_clear_effects(validator:GLValidator) -> bool:
	if not validate_base( validator ):
		return false
	if not validator._controller.source:
		GLDebug.error("Clear Effects Failed: 'source' data is null. Create one or load a project")
		return false
	return validator._validate_clear_effects()


@abstract
func _validate_apply_effects() -> bool
static func validate_apply_effects(validator:GLValidator) -> bool:
	if not validate_base( validator ):
		return false
	if not validator._controller.source:
		GLDebug.error("Apply Effects Failed: 'source' data is null. Create one or load a project")
		return false
	if validator._controller.effects:
		var clean_empty:Callable = func (effect:GLEffect): return effect
		validator._controller.effects = validator._controller.effects.filter( clean_empty )
	return validator._validate_apply_effects()
	


static func validate_base(validator:GLValidator) -> bool:
	if not validator:
		GLDebug.error("Base validation failed: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	if not validator.validated_ready:
		GLDebug.error("Base validation failed: Ready was not validated. Restart this scene and check for initialization errors")
		return false
	return true
	
	
	
