@tool
extends PropertyUI
class_name CustomVector2Input
## Same as a @export Vector2 on the inspector
## Set step=1 to act like a Vector2i

@export var step:float = 1
@onready var _input_x:SpinBox = $HBoxContainer/X
@onready var _input_y:SpinBox = $HBoxContainer/Y
var _prev_text:String


func _ready():
	$Label.text = property_name
	_input_x.step = step
	_input_x.value_changed.connect( _on_x_changed )
	_input_y.step = step
	_input_y.value_changed.connect( _on_y_changed )

func _on_x_changed(x:float):
	on_change.emit( Vector2(x, _input_y.value) )

func _on_y_changed(y:float):
	on_change.emit( Vector2(_input_x.value, y) )

func set_value(value):
	_input_x.value = value.x
	_input_y.value = value.y

func get_value():
	return Vector2(_input_x.value, _input_y.value)

