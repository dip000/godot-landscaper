@tool
@abstract
extends RefCounted
class_name GLValidator

var _controller:GLController


func _init(controller:GLController):
	_controller = controller


@abstract
func validate_ready() -> bool

@abstract
func validate_select_brush(brush:GLBrush) -> bool

@abstract
func validate_stroke_start(hit_info:Dictionary) -> bool

@abstract
func validate_stroke_primary(hit_info:Dictionary) -> bool

@abstract
func validate_stroke_secondary(hit_info:Dictionary) -> bool

@abstract
func validate_stroke_end() -> bool

@abstract
func validate_clear_effects() -> bool

@abstract
func validate_apply_effects() -> bool
