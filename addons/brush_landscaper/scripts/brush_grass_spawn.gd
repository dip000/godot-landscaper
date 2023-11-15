@tool
extends Brush
class_name GrassSpawn
# Brush that spawns grass when you paint over the terrain
# Paints different shades of gray over the "texture" depending on the grass variant



func save_ui():
	_raw.gs_texture = _texture
	_raw.gs_resolution = _resolution

func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	super(ui, scene, raw)
	_texture = _raw.gs_texture
	_resolution = _raw.gs_resolution
	_preview_texture()
