@tool
extends Control
class_name UIManager

static var spawn:bool = true
static var color:bool = false


func _ready():
	$Spawner.pressed.connect( _on_spawner_pressed )
	$Color.pressed.connect( _on_colorer_pressed )
	if spawn:
		$Spawner.set_pressed_no_signal(true)
	if color:
		$Color.set_pressed_no_signal(true)

func _on_spawner_pressed():
	spawn = true
	color = false
	Landscaper.instancer.notify_property_list_changed()


func _on_colorer_pressed():
	spawn = false
	color = true
	Landscaper.instancer.notify_property_list_changed()
