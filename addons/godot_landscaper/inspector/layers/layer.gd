@tool
extends PanelContainer
class_name GLUILayer

@onready var drag:Button = %Drag
@onready var active:CheckBox = %Active
@onready var channel:LineEdit = %Channel

var _layer:GLPaintLayer


func _ready() -> void:
	active.toggled.connect( on_active_toggled )
	channel.text_changed.connect( on_channel_changed )


func on_active_toggled(toggled_on:bool):
	_layer.active = toggled_on


func on_channel_changed(new_text:String):
	_layer.material_channel = new_text


func fill(layer:GLPaintLayer):
	_layer = layer
	active.button_pressed = layer.active
	channel.text = layer.material_channel


func set_color_variation(variation:float):
	print(variation)
	var settings:EditorSettings = EditorInterface.get_editor_settings()
	var accent_color:Color = settings.get_setting("interface/theme/accent_color")
	var style_box:StyleBoxFlat = get_theme_stylebox("panel")
	accent_color.ok_hsl_h = wrapf( accent_color.ok_hsl_h + variation, 0, 1 )
	accent_color.a = 0.2
	style_box.bg_color = accent_color







	
