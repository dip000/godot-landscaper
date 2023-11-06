@tool
extends Button

@onready var paths_clip:Control = %PathsClip


func _ready():
	toggled.connect( _on_toggled_paths )

func _on_toggled_paths(button_pressed:bool):
	if button_pressed:
		text = "Hide File Paths"
		create_tween().tween_property( paths_clip, "custom_minimum_size", Vector2(0, 310), 0.4 ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		create_tween().tween_property( paths_clip, "custom_minimum_size", Vector2.ZERO, 0.4 ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		text = "Show File Paths"
		
