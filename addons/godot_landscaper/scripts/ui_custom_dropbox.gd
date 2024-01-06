@tool
extends PropertyUI
class_name CustomDropbox

@export var preview_size:Vector2i = Vector2i(40, 40)
@onready var _property:Label = $Label
@onready var _reset:Button = $Close

var _default_icon:Texture2D = self.icon
var _icon:Texture2D


func _ready():
	_property.text = property_name
	_reset.pressed.connect( _on_reset_pressed )

func _on_reset_pressed():
	self.icon = _default_icon
	self.disabled = true
	_property.text = property_name
	tooltip_text = ""
	_reset.hide()
	_icon = null
	on_change.emit( false )

# Drag and drop functionality
func _can_drop_data(at_position, data):
	if typeof(data) != TYPE_DICTIONARY or data.type != "files" or data.files.size() != 1:
		return false
	if not data.files[0].get_extension() in ["tres", "res", "svg", "png", "jpg"]:
		return false
	return true

func _drop_data(at_position, data):
	_icon = load(data.files[0])
	tooltip_text = _icon.resource_path.get_file()
	on_change.emit( true )
	set_value( _icon )


func set_value(btn_icon):
	if btn_icon:
		self.icon = AssetsManager.format_texture( btn_icon, preview_size )
		self.disabled = false
		_icon = btn_icon
		_reset.show()
	else:
		self.icon = _default_icon
		self.disabled = true
		_property.text = property_name
		tooltip_text = ""
		_reset.hide()
		_icon = null

func get_value():
	return _icon

