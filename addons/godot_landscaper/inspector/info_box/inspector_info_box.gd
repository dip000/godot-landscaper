@tool
extends MarginContainer
class_name InfoBox

@onready var _panel_container = $PanelContainer

const LIGHT:Color = Color(0.898, 0.925, 0.965)
const DARK:Color = Color(0.125, 0.145, 0.176)


func _ready():
	var settings:EditorSettings = EditorInterface.get_editor_settings()
	var base_color:Color = settings.get_setting("interface/theme/base_color")
	var panel:StyleBoxFlat = _panel_container["theme_override_styles/panel"]
	panel.bg_color = DARK if base_color.get_luminance() < 0.5 else LIGHT


func set_info(info:String):
	%Info.text = info
