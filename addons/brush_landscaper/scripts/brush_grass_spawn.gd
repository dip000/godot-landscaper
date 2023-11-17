@tool
extends Brush
class_name GrassSpawn
# Brush that spawns grass when you paint over the terrain
# Paints different shades of gray over the "texture" depending on the grass variant

@onready var density:CustomNumberInput = $Density
@onready var quality:CustomNumberInput = $Quality
@onready var gradient:CustomSliderUI = $Gradient
@onready var grass_size:CustomVectorInput = $Size
@onready var detail_color:CustomColorPickerEnable = $DetailColor
@onready var variants:CustomTabs = $Variants
@onready var billboard:CustomTabs = $Billboard


func _ready():
	gradient.on_change.connect( _on_gradient_change )

func _on_gradient_change(value:float):
	_raw.gs_gradient_mask.fill_to.y = value


func save_ui():
	_raw.gs_texture = _texture
	_raw.gs_resolution = _resolution
	_raw.gs_variants = variants.value
	_raw.gs_selected_variant = variants.selected_tab
	_raw.gs_density = density.value
	_raw.gs_selected_billboard = billboard.selected_tab
	_raw.gs_quality = quality.value
	_raw.gs_gradient_value = gradient.value
	_raw.gs_size = grass_size.value
	_raw.gs_detail_color = detail_color.value
	_raw.gs_enable_details = detail_color.enabled
	
func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	super(ui, scene, raw)
	_texture = _raw.gs_texture
	_resolution = _raw.gs_resolution
	variants.value = _raw.gs_variants
	variants.selected_tab = _raw.gs_selected_variant
	density.value = _raw.gs_density
	billboard.selected_tab = _raw.gs_selected_billboard
	quality.value = _raw.gs_quality
	gradient.value = _raw.gs_gradient_value
	grass_size.value = _raw.gs_size
	detail_color.enabled = _raw.gs_enable_details
	detail_color.value = _raw.gs_detail_color
	_preview_texture()

