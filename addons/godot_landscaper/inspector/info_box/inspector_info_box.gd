@tool
extends MarginContainer
class_name GLInfoBox

const EXPAND:String = "⯇"
const COLLAPSE:String = "⯆"

@onready var _panel_container = $PanelContainer
@onready var _button:Button = %ExpandCollapse
@onready var _expand_collapse:Button = %ExpandCollapse


func _ready():
	var settings:EditorSettings = EditorInterface.get_editor_settings()
	var accent_color:Color = settings.get_setting("interface/theme/accent_color")
	var panel:StyleBoxFlat = _panel_container["theme_override_styles/panel"]
	panel.bg_color = Color(accent_color, 0.1)

	_button.toggled.connect( _on_button_pressed )
	_expand_collapse.toggled.connect( _on_expand_collapse_toggle )


func _on_button_pressed(toggled_on:bool):
	if toggled_on:
		_button.text = COLLAPSE
	else:
		_button.text = EXPAND


func _on_expand_collapse_toggle(toggled_on:bool):
	%Info.visible = toggled_on


func set_info(info:String):
	%Info.text = info
	%ExpandCollapse.visible = (size.y > 22)


func set_title(title:String):
	%TitleContainer.show()
	%Info.hide()
	%Title.text = title









	
