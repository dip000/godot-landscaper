@tool
extends PropertyUI
class_name CustomColorPicker
# Used a StyleBoxFlat in each style override to round the borders.
# Seting a color will update the border color and the hex code.

var stylebox:StyleBoxFlat = get_theme_stylebox("normal")
@onready var color_code:LineEdit = $ColorCode
@onready var property_name:Label = $Name


func _ready():
	# Here's a lil' trick to use properties of ColorPickerButton class being a Control
	#[TODO] Use an actual Control node as the root in case this trick stops working
	self.color_changed.connect( _on_color_changed )
	_on_color_changed( self.color )

func _on_color_changed(c:Color):
	stylebox.bg_color = c
	color_code.text = "#" + c.to_html()
	
	# Text inverted and gray scaled for contrast
	# Outline works as boldness
	var lum:float = c.get_luminance()
	var inv:Color = Color(lum, lum, lum).inverted()
	color_code["theme_override_colors/font_uneditable_color"] = inv
	property_name["theme_override_colors/font_color"] = inv
	property_name["theme_override_colors/font_outline_color"] = inv


# PropertyUI implementations
func set_value(value):
	_on_color_changed( value )

func get_value():
	return self.color
