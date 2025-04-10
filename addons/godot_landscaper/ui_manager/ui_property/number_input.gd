@tool
extends UIProperty
class_name UINumberInput
## Same as a @export float on the inspector
## Set step=1 to act like an int

@export var _suffix:String = ""
@export var _step:float = 1
@onready var _input:SpinBox = $SpinBox
var _prev_text:String

var value:float:
	get: return _input.value
	set(v): _input.set_value_no_signal(v)


func _ready():
	$Label.text = property_name
	_input.suffix = _suffix
	_input.step = _step
	_input.value_changed.connect( _on_value_changed )

func _on_value_changed(val:float):
	change()
