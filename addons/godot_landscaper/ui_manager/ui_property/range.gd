@tool
extends UIProperty
class_name CustomRange
## Custom slider UI
## Sets percentage label and value on value_changed
## Call "property" or "value" externally from code

@export var _min_value:float
@export var _max_value:float
@onready var _name_label:Label = $Name
@onready var _suffix_label:Label = $HBoxContainer/Percentage
@onready var _slider:HSlider = $HBoxContainer/Slider

var value:float:
	get: return _slider.value
	set(v):
		v = clampf( v, _min_value, _max_value )
		_slider.set_value_no_signal(v)
		update_percentage( v )


func _ready():
	_name_label.text = property_name
	_slider.min_value = _min_value
	_slider.max_value = _max_value
	_slider.step = (_max_value - _min_value) / 100.0
	
	_slider.value_changed.connect( _on_slider_changed )
	update_percentage( _slider.value )

func _on_slider_changed(val:float):
	update_percentage( val )
	change()

func update_percentage(val:float):
	_suffix_label.text = String.num( 100*val/(_max_value), 1 ) + "%"
