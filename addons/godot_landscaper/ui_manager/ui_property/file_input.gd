@tool
extends UIProperty
class_name UIFileInput
## This custom property only stores a path to a file.
## To actually save or load a resource, refer to AssetsManager

@export var _default_file_path:String = ""
@export var _default_file_on_dir_open:String = ""

@onready var _input:LineEdit = $HBoxContainer/Input
@onready var _file_dialog:FileDialog = $FileDialog
@onready var _file_open:Button = $HBoxContainer/Open

var path:String:
	get: return _input.text
	set(v): _input.text = v


func _ready():
	$Name.text = property_name
	path = _default_file_path
	
	_file_open.pressed.connect( _on_file_open )
	_input.text_changed.connect( _on_text_changed )
	_file_dialog.file_selected.connect( _on_file_select )
	_file_dialog.dir_selected.connect( _on_dir_select )


# Open, Load and Save
func _on_file_open():
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_ANY
	_file_dialog.title = "Open '%s' or select a folder to save it" %property_name
	_file_dialog.popup()


# Sync text input and file dialog paths
func _on_text_changed(new_text:String):
	if FileAccess.file_exists( new_text ):
		_file_dialog.set_current_dir( new_text )

func _on_file_select(file:String):
	path = file
	change()

func _on_dir_select(dir:String):
	path = dir.path_join( _default_file_on_dir_open )
	change()

# Drag and drop functionality
func _can_drop_data(at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.type == "files" or data.type == "files_and_dirs" and data.files.size() == 1

func _drop_data(at_position, data):
	if data.type == "files_and_dirs":
		path = _input.text.path_join( _default_file_on_dir_open )
	else:
		path = data.files[0]
	change()
