@tool
extends PropertyUI
class_name CustomDropbox

@export var dropeable:bool = true
@export var can_reset:bool = true
@onready var _property:Label = $Label
@onready var _reset:Button = $Close

var _default_icon:Texture2D = self.icon
var _icon:Texture2D


func _ready():
	_property.text = property_name
	if can_reset:
		_reset.pressed.connect( _on_reset_pressed )
	if self.disabled or not dropeable:
		_reset.hide()

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
	if not dropeable:
		return false
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


func _set_icon(btn_icon):
	var img:Image = btn_icon.get_image().duplicate()
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	
	img.resize( 40, 40 )
	self.icon = ImageTexture.create_from_image( img )
	_icon = btn_icon


func set_value(btn_icon):
	if btn_icon:
		_set_icon( btn_icon )
		self.disabled = false
		_reset.show()
	elif dropeable:
		_on_reset_pressed()

func get_value():
	return _icon

