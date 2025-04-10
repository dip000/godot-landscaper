@tool
extends UIProperty
class_name UIDropbox
## Dropper of texture resources, usefull for previewing a texture input

@onready var _confirmation_dialog:ConfirmationDialog = $ConfirmationDialog
@onready var _property:Label = $Label
@onready var _reset:Button = $Close

@export var _default_icon:Texture2D
@export var _initial_icon:Texture2D

var drop_icon:Texture2D:
	get: return self.icon
	set(v): set_drop_icon(v)


func set_drop_icon(drop_icon:Texture2D):
	if drop_icon:
		self.icon = drop_icon
		self.disabled = false
		name = tooltip_text.get_basename().get_file().to_pascal_case()
		_reset.show()
		tooltip_text = drop_icon.resource_path
		_property.text = tooltip_text.get_basename().get_file().capitalize()
	else:
		self.icon = _default_icon
		self.disabled = true
		_reset.hide()
		name = "Empty"
		_property.text = name
		tooltip_text = ""


func _ready():
	drop_icon = _initial_icon
	_reset.pressed.connect( _on_reset_pressed )
	_confirmation_dialog.confirmed.connect( _on_confirm_reset )
	_property.text = property_name
	name = property_name

func _on_reset_pressed():
	_confirmation_dialog.popup_centered()

func _on_confirm_reset():
	set_drop_icon(null)
	change()

# Drag and drop functionality
func _can_drop_data(at_position:Vector2, data:Variant):
	if typeof(data) != TYPE_DICTIONARY or data.type != "files" or data.files.size() != 1:
		return false
	if not data.files[0].get_extension() in ["tres", "res", "svg", "png", "jpg"]:
		return false
	return true

func _drop_data(at_position:Vector2, data:Variant):
	set_drop_icon( load(data.files[0]) )
	change()
