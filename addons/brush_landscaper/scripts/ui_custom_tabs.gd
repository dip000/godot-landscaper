@tool
extends PropertyUI
class_name CustomTabs
# A toggle buttons group. Like the TabBar class but with a FlowContainer.
# Shows every tab without clipping or collapsing so we can have all content in view.

@export var tab_size := Vector2i(30, 30)
@onready var _tabs_holder:FlowContainer = $PanelContainer/VBoxContainer/Tabs
var _button_group := ButtonGroup.new()

var selected_tab:int:
	set(v):
		selected_tab = v
		_tabs_holder.get_child(v).button_pressed = true


# Emits 'PropertyUI.on_change' every press of a button
func _ready():
	$PanelContainer/VBoxContainer/Label.text = property_name
	var tabs:Array = _tabs_holder.get_children()
	for tab_index in tabs.size():
		tabs[tab_index].toggle_mode = true
		tabs[tab_index].button_group = _button_group
		tabs[tab_index].toggled.connect( _on_toggled_tab.bind(tab_index) )


func _on_toggled_tab(button_pressed:bool, tab_index:int):
	if button_pressed and selected_tab != tab_index:
		selected_tab = tab_index
		on_change.emit( tab_index )


# PropertyUI implementation
func set_value(tab_icons):
	for i in tab_icons.size():
		var dropbox:CustomDropbox = _tabs_holder.get_child(i)
		dropbox.value = tab_icons[i]

func get_value():
	var tab_icons:Array[Texture2D]
	for dropbox in _tabs_holder.get_children():
		tab_icons.append( dropbox.value )
	return tab_icons
