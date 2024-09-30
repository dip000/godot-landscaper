@tool
extends PropertyUI
class_name CustomToggleContent
## Shows content nodes if you press a button. Hides them if you press it again
## Usefull to preview large content without polluting the UI


@export var property_name_pressed:String = ""
@export var max_size:float = 100

@onready var _content_clip:ScrollContainer = $PanelContainer/ContentClip
@onready var _toggle_button:Button = $ToggleButton
@onready var _content:VBoxContainer = $PanelContainer/ContentClip/Content
@onready var _panel:PanelContainer = $PanelContainer


func _ready():
	_toggle_button.text = property_name
	_toggle_button.toggled.connect( _on_toggled )
	_panel.hide()

func _on_toggled(button_pressed:bool):
	on_change.emit(button_pressed)
	var final_value:Vector2
	if button_pressed:
		_panel.show()
		_content_clip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		_toggle_button.text = property_name_pressed
		final_value.y = min( _content.size.y, max_size )
	else:
		_toggle_button.text = property_name
		final_value = Vector2.ZERO
	
	var tween := create_tween()
	tween.tween_property(
		_content_clip,
		"custom_minimum_size",
		final_value,
		0.4
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if not button_pressed:
		await tween.finished
		_panel.hide()
		_content_clip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


func set_value(value):
	for element in _content.get_children():
		element.queue_free()
	for element in value:
		_content.add_child(element)
func get_value():
	return _content.get_children()
func add_value(value):
	_content.add_child(value)
