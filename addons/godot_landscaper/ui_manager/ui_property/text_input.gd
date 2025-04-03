@tool
extends UIProperty
class_name UITextInput

@onready var _input:TextEdit = $Input

var text:String:
	get: return _input.text if _input.text else _input.placeholder_text
	set(v): _input.text = v


func _ready():
	$Property.text = property_name
	_input.text_changed.connect( change )
