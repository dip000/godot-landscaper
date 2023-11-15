@tool
extends PropertyUI
class_name CustomSliderUI
# Custom slider UI
# Sets percentage label and value on value_changed
# Call "property" or "value" externally from code

@onready var _name_label:Label = $Name
@onready var _percentage_label:Label = $Percentage
@onready var _slider:HSlider = $Slider


func _ready():
	_name_label.text = property_name
	_slider.value_changed.connect( _on_slider_changed )
	_on_slider_changed( _slider.value ) #start with inspector value

func _on_slider_changed(value:float):
	_percentage_label.text = str(value) + " %"
	on_change.emit( value )
	

# PropertyUI implementations
func set_value(value):
	_slider.set_value_no_signal(value)
	_percentage_label.text = str(value) + " %"

func get_value():
	return _slider.value

