@tool
extends PropertyUI
class_name CustomFileInput
# This custom property only stores a path to a file.
# To actually save or load a resource, refer to AssetsManager

@export var default_file_path:String = "res://landscaper/file.extension"
@onready var _input:LineEdit = $HBoxContainer/Input
@onready var _file_dialog:FileDialog = $FileDialog
@onready var _file_save:Button = $HBoxContainer/Save
@onready var _file_load:Button = $HBoxContainer/Load


func _ready():
	$Name.text = property_name
	_input.placeholder_text = default_file_path
	
	_file_save.pressed.connect( on_file_save )
	_file_load.pressed.connect( on_file_load )
	_input.text_changed.connect( _on_text_changed )
	_file_dialog.file_selected.connect( _on_file_select )


# Save and load
func on_file_save():
	if FileAccess.file_exists( _input.text ):
		print("Saving..")
	else:
		_input.text = _input.placeholder_text
		print("Saving with default file path..")

func on_file_load():
	print("Select a file to load")
	_file_dialog.title = "Load " + property_name
	_file_dialog.popup()

# Sync text input and file dialog paths
func _on_text_changed(new_text:String):
	if FileAccess.file_exists( new_text ):
		_file_dialog.set_current_dir( new_text )

func _on_file_select(dir:String):
	_input.text = dir
	print("Loading..")

# Drag and drop functionality
func _can_drop_data(at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.type == "files" and data.files.size() == 1

func _drop_data(at_position, data):
	_input.text = data.files[0]
	_file_load.set_disabled( false )
	print("Loading..")


# PropertyUI Implementation
func get_value():
	return _input.text

func set_value(value):
	_on_text_changed( value )

