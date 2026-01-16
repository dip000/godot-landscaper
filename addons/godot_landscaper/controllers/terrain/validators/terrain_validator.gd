@tool
extends GLValidator
class_name GLValidatorTerrain


func _validate_ready() -> bool:
	return true


func _validate_select_brush(brush:GLBrush) -> bool:
	return true


func _validate_stroke_start(hit_info:Dictionary) -> bool:
	return true


func _validate_stroke_primary(hit_info:Dictionary) -> bool:
	return true


func _validate_stroke_secondary(hit_info:Dictionary) -> bool:
	return true


func _validate_stroke_end() -> bool:
	return true


func _validate_clear_effects() -> bool:
	return true


func _validate_apply_effects() -> bool:
	return true
	
	
