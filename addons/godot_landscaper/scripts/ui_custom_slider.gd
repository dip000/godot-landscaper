@tool
extends PropertyUI
class_name CustomSliderUI
## Custom slider UI
## Sets percentage label and value on value_changed
## Call "property" or "value" externally from code

@export var _min_value:float
@export var _max_value:float
@onready var _name_label:Label = $Name
@onready var _suffix_label:Label = $HBoxContainer/Percentage
@onready var _slider:HSlider = $HBoxContainer/Slider


func _ready():
	_name_label.text = property_name
	_slider.min_value = _min_value
	_slider.max_value = _max_value
	_slider.step = (_max_value - _min_value) / 100.0
	
	_slider.value_changed.connect( _on_slider_changed )
	update_percentage( _slider.value )

func _on_slider_changed(val:float):
	update_percentage( val )
	on_change.emit( val )

func update_percentage(val:float):
	_suffix_label.text = String.num( 100*val/(_max_value), 1 ) + "%"


# PropertyUI implementations
func set_value(val):
	val = clampf( val, _min_value, _max_value )
	_slider.set_value_no_signal( val )
	update_percentage( val )

func get_value():
	return _slider.value

