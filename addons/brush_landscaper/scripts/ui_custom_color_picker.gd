@tool
extends PropertyUI
class_name CustomColorPicker
# Used a StyleBoxFlat in each style override to round the borders.
# Seting a color will update the border color and the hex code.

@onready var _property:Label = $HBoxContainer/Name
@onready var _color_code:LineEdit = $HBoxContainer/Code
@onready var _stylebox:StyleBoxFlat = self.get_theme_stylebox("normal")


func _ready():
	_property.text = property_name
	self.color_changed.connect( _on_color_changed )
	_on_color_changed( self.color )

func _on_color_changed(c:Color):
	_stylebox.bg_color = c
	_color_code.text = "#" + c.to_html()
	
	# Text inverted and gray scaled for contrast
	# Outline works as boldness
	var lum:float = c.get_luminance()
	var inv:Color = Color(lum, lum, lum).inverted()
	_color_code["theme_override_colors/font_uneditable_color"] = inv
	_property["theme_override_colors/font_color"] = inv
	_property["theme_override_colors/font_outline_color"] = inv
	on_change.emit( c )


# PropertyUI implementations
func set_value(value):
	self.color = value
	_on_color_changed( value )

func get_value():
	return self.color
