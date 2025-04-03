@tool
extends Panel
class_name UIBlocker


func set_enable(fade_out:bool):
	var tween:Tween = create_tween()
	if fade_out:
		tween.tween_property( self, "modulate", Color.TRANSPARENT, 0.2 )
		tween.finished.connect( hide )
	else:
		show()
		tween.tween_property( self, "modulate", Color.WHITE, 0.2 )
