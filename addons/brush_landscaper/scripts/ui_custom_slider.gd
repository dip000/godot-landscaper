@tool
extends PropertyUI
class_name CustomSliderUI
# Custom slider UI
# Sets percentage label and value on value_changed
# Call "property" or "value" externally from code

@onready var _name_label:Label = $Name
@onready var _suffix_label:Label = $HBoxContainer/Percentage
@onready var _slider:HSlider = $HBoxContainer/Slider


func _ready():
	_name_label.text = property_name
	_slider.value_changed.connect( _on_slider_changed )
	_on_slider_changed( _slider.value ) #start with inspector value

func _on_slider_changed(value:float):
	_suffix_label.text = str(value) + "%"
	on_change.emit( value/100.0 )
	

# PropertyUI implementations
func set_value(value):
	value = roundf( clamp(value*100.0, 1, 100) )
	_slider.set_value_no_signal(value)
	_suffix_label.text = str(value) + " %"

func get_value():
	return _slider.value/100.0

