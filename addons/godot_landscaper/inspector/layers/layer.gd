## Handy UI Layer visualizer for [GLUILayers] pannel using [GLPaintLayer] resource.
##
## It only assigns [member GLPaintLayer.active] and [member GLPaintLayer.sampler].
## For more operations use the raw data in [member GLControllerTerrain.layers]

@tool
extends PanelContainer
class_name GLUILayer

@onready var _sampler:LineEdit = %Channel
@onready var active:CheckBox = %Active
@onready var delete: Button = %Delete

var _layer:GLPaintLayer


func _ready() -> void:
	active.toggled.connect( _on_active_toggled )
	_sampler.text_changed.connect( _on_sampler_changed )


func _on_active_toggled(toggled_on:bool):
	_layer.active = toggled_on


func _on_sampler_changed(new_text:String):
	_layer.sampler = new_text


## Fills the UI elements with given [GLPaintLayer] resource
func fill(layer:GLPaintLayer):
	_layer = layer
	_sampler.text = layer.sampler
	active.button_pressed = layer.active


## Shifts the layer hue to a variation value in range of -1.0 to 1.0
func set_color_variation(variation:float):
	var settings:EditorSettings = EditorInterface.get_editor_settings()
	var accent_color:Color = settings.get_setting("interface/theme/accent_color")
	var style_box:StyleBoxFlat = get_theme_stylebox("panel")
	accent_color.ok_hsl_h = wrapf( accent_color.ok_hsl_h + variation, 0, 1 )
	accent_color.a = 0.2
	style_box.bg_color = accent_color







	
