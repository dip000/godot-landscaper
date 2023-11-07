@tool
extends VBoxContainer
class_name AssetsManager

@onready var toggle_content:CustomToggleContent = $ToggleContent
@onready var save_all:Button = $SaveLoadAll/SaveAll
@onready var load_all:Button = $SaveLoadAll/LoadAll


func _ready():
	save_all.pressed.connect( _on_save_all )
	load_all.pressed.connect( _on_load_all )


func _on_save_all():
	for file_input in toggle_content.value:
		file_input.on_file_save()

func _on_load_all():
	for file_input in toggle_content.value:
		if not FileAccess.file_exists( file_input.value ):
			$AcceptDialog.dialog_text = "%s in path '%s' does not exist and cannot be loaded"%[file_input.property_name, file_input.value]
			$AcceptDialog.popup()
			return
	
	for file_input in toggle_content.value:
		print("Loaded: ", file_input.value)
	
	
