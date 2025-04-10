@tool
extends UIProperty
class_name UIToggleContent
## Shows content nodes if you press a button. Hides them if you press it again
## Usefull to preview large content without polluting the UI


@export var _property_name_pressed:String = ""
@export var _max_size:float = 100
@export var _initial_value:bool = false
@export var _toggle_group := true

@onready var _content_clip:ScrollContainer = %ContentClip
@onready var _toggle_button:Button = $ToggleButton
@onready var _panel:PanelContainer = $PanelContainer
@onready var _arrow:Label = %Arrow

var content:Array:
	get: return _content_clip.get_child(0).get_children()

var layer_mask:int:
	get:
		var mask:int = 0
		for tab in content:
			if tab.button_pressed:
				mask |= (1<<tab.get_index())
		return mask
	

func _ready():
	_toggle_button.toggled.connect( _on_toggled )
	_toggle_button.set_pressed_no_signal(_initial_value)
	_on_toggled(_initial_value)

func _on_toggled(button_pressed:bool):
	var final_value:Vector2
	
	if button_pressed:
		_panel.show()
		_content_clip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		_toggle_button.text = _property_name_pressed
		final_value.y = _max_size
		_arrow.text = "⇧  "
	else:
		_toggle_button.text = property_name
		final_value = Vector2.ZERO
		_arrow.text = "⇩  "
	
	var tween := create_tween()
	tween.tween_property(
		_content_clip,
		"custom_minimum_size",
		final_value,
		0.2
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	if not button_pressed:
		await tween.finished
		_panel.hide()
		_content_clip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	change()
