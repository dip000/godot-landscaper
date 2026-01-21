## Validator base class.
##
## Used in GLController framework for validating every entry.
## Call from static functions because as they say: "Quis verificat ipsos verificatores".

@tool
@abstract
extends RefCounted
class_name GLValidator

var _controller:GLController


func _init(controller:GLController):
	_controller = controller


@abstract
func _validate_ready() -> bool
static func validate_ready(validator:GLValidator) -> bool:
	if not validator:
		GLDebug.error("Inizialization is not possible: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	return validator._validate_ready()


@abstract
func _validate_select_brush(brush:GLBrush) -> bool
static func validate_select_brush(validator:GLValidator, brush:GLBrush) -> bool:
	if not validator:
		GLDebug.error("Inizialization is not possible: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	return validator._validate_select_brush( brush )


@abstract
func _validate_stroke_start(scan_data:GLScanData) -> bool
static func validate_stroke_start(validator:GLValidator, scan_data:GLScanData) -> bool:
	if not validator:
		GLDebug.error("Inizialization is not possible: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	return validator._validate_stroke_start( scan_data )


@abstract
func _validate_stroke_primary(scan_data:GLScanData) -> bool
static func validate_stroke_primary(validator:GLValidator, scan_data:GLScanData) -> bool:
	if not validator:
		GLDebug.error("Inizialization is not possible: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	return validator._validate_stroke_primary( scan_data )


@abstract
func _validate_stroke_secondary(scan_data:GLScanData) -> bool
static func validate_stroke_secondary(validator:GLValidator, scan_data:GLScanData) -> bool:
	if not validator:
		GLDebug.error("Inizialization is not possible: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	return validator._validate_stroke_secondary( scan_data )


@abstract
func _validate_stroke_end() -> bool
static func validate_stroke_end(validator:GLValidator) -> bool:
	if not validator:
		GLDebug.error("Inizialization is not possible: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	return validator._validate_stroke_end()


@abstract
func _validate_clear_effects() -> bool
static func validate_clear_effects(validator:GLValidator) -> bool:
	if not validator:
		GLDebug.error("Inizialization is not possible: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	return validator._validate_clear_effects()


@abstract
func _validate_apply_effects() -> bool
static func validate_apply_effects(validator:GLValidator) -> bool:
	if not validator:
		GLDebug.error("Inizialization is not possible: Validator is null. Assign it correctly in _setup_controller() and restart this scene")
		return false
	return validator._validate_apply_effects()
