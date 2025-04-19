@tool
extends Control
class_name UIManager

@onready var spawner:Button = $Spawner
@onready var color:Button = $Color

static var action:String


func _ready():
	spawner.pressed.connect( _on_spawner_pressed )
	color.pressed.connect( _on_color_pressed )

func _on_spawner_pressed():
	action = "Spawn"
	Landscaper.instancer.notify_property_list_changed()
	

func _on_color_pressed():
	action = "Color"
	Landscaper.instancer.notify_property_list_changed()
