@tool
extends PropertyUI
class_name CustomNumberInput
## Same as a @export float on the inspector
## Set step=1 to act like an int

@export var suffix:String = ""
@export var step:float = 1
@onready var _input:SpinBox = $SpinBox
var _prev_text:String


func _ready():
	$Label.text = property_name
	_input.suffix = suffix
	_input.step = step
	_input.value_changed.connect( _on_value_changed )

func _on_value_changed(val:float):
	on_change.emit( val )

func set_value(value):
	_input.value = value

func get_value():
	return _input.value
