@tool
extends UIProperty
class_name CustomVector2Input
## Same as a @export Vector2 on the inspector
## Set step=1 to act like a Vector2i

@export var _step:float = 1
@onready var _input_x:SpinBox = $HBoxContainer/X
@onready var _input_y:SpinBox = $HBoxContainer/Y
var _prev_text:String

var x:float:
	get: return _input_x.value
	set(v): _input_x.set_value_no_signal(v)

var y:float:
	get: return _input_y.value
	set(v): _input_y.set_value_no_signal(v)

var value:Vector2:
	get: return Vector2(x, y)
	set(v): x=v.x; y=v.y


func _ready():
	$Label.text = property_name
	_input_x.value_changed.connect( _on_x_changed )
	_input_y.value_changed.connect( _on_y_changed )
	_input_x.step = _step
	_input_y.step = _step

func _on_x_changed(x:float):
	change()

func _on_y_changed(y:float):
	change()
