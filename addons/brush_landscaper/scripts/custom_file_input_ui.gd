@tool
extends PropertyUI
class_name CustomFileInput

@onready var _input:LineEdit = $HBoxContainer/Input
@onready var _file_dialog:FileDialog = $FileDialog
@onready var _file_open:Button = $HBoxContainer/Open
@onready var _file_save:Button = $HBoxContainer/Save
@onready var _file_load:Button = $HBoxContainer/Load


func _ready():
	$Name.text = property_name
	_file_open.pressed.connect( _file_dialog.popup )
	_file_save.pressed.connect( func(): print("Save") )
	_file_load.pressed.connect( func(): print("Load") )
	
	_input.text_changed.connect( _on_text_changed )
	_file_dialog.file_selected.connect( _on_file_select )

# Sync paths
func _on_text_changed(new_text:String):
	if FileAccess.file_exists( new_text ):
		_file_dialog.set_current_dir( new_text )

func _on_file_select(dir:String):
	_input.text = dir


# Drag and drop functionality
func _can_drop_data(at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.type == "files" and data.files.size() == 1

func _drop_data(at_position, data):
	var file_path:String = data.files[0]
	_input.text = file_path


# PropertyUI Implementation
func get_value():
	return _input.text

func set_value(value):
	_on_text_changed( value )

