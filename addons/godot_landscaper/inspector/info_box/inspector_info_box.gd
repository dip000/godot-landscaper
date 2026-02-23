@tool
extends MarginContainer
class_name GLInfoBox

@onready var _panel_container = $PanelContainer

func _ready():
	var settings:EditorSettings = EditorInterface.get_editor_settings()
	var accent_color:Color = settings.get_setting("interface/theme/accent_color")
	var panel:StyleBoxFlat = _panel_container["theme_override_styles/panel"]
	panel.bg_color = Color(accent_color, 0.1)


func set_info(info:String):
	%Info.text = info
