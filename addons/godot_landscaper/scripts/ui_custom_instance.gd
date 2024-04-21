@tool
extends PropertyUI
class_name CustomInstance
# Loads a scene and a range property only for Instancer brush.
# The following tree shows the UI hierarchy:
# ┖╴CustomTabs
#    ┠╴CustomInstance
#    ┃  ┠╴CustomFileInput
#    ┃  ┖╴CustomRange
#    ┖╴CustomInstance..

@onready var randomness:CustomSliderUI = $Content/MarginBody/VBoxContainer/CustomSlider
@onready var _file:CustomFileInput = $Content/MarginBody/VBoxContainer/FileInput
@onready var _label:Label = $Content/MarginHead/Label

var scene:PackedScene:
	set(value):
		scene = value
		self.disabled = not value
		_set_enable( true if value else false )


func _ready():
	_label.text = property_name
	self.toggled.connect( _on_toggled )
	_file.on_change.connect( _on_file_changed )
	randomness.on_change.connect( _on_randomness_changed )

func _on_toggled(button_pressed:bool):
	_set_enable( button_pressed )

func _on_file_changed(file:String):
	if not FileAccess.file_exists( file ):
		scene = null
		return
	
	var resource:Resource = load( file )
	if not resource is PackedScene:
		scene = null
		return
	
	scene = resource
	self.button_pressed = true
	on_change.emit()
	
func _on_randomness_changed(value:float):
	if not self.disabled:
		self.button_pressed = true
		on_change.emit()

func _set_enable(value:bool):
	if scene:
		_file.value = scene.resource_path
	
	var label_stylebox:StyleBoxFlat = _label["theme_override_styles/normal"]
	var basename:String = _file.value.get_file().get_basename()
	
	if value:
		_label.text = "Spawning '%s'" % basename
		label_stylebox.bg_color = Color(0.275, 0.439, 0.584)
	else:
		_label.text = "Select To Spawn '%s'" % basename
		label_stylebox.bg_color = Color(0.251, 0.267, 0.298)
	
	if not scene:
		_label.text = "Open A Scene"
		_file.value = "res://"

