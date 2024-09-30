@tool
extends PropertyUI
class_name CustomDoubleButtons
## Selector using two buttons

func _ready():
	$PropertyName.text = property_name
	$HBoxContainer/Heighten.pressed.connect( _on_button_pressed.bind(true) )
	$HBoxContainer/Lower.pressed.connect( _on_button_pressed.bind(false) )

func _on_button_pressed(is_height:bool):
	on_change.emit( is_height )
