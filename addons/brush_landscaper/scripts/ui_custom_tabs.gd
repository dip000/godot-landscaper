@tool
extends PropertyUI
class_name CustomTabs
# A toggle buttons group. Like the TabBar class but with a FlowContainer.
# Shows every tab without clipping or collapsing so we can have all content in view.

@onready var _tabs_holder:FlowContainer = $Tabs
var _current_index:int


# Emits 'PropertyUI.on_change' every press of a button
func _ready():
	$Label.text = property_name
	var tabs:Array = _tabs_holder.get_children()
	for index in tabs.size():
		tabs[index].toggled.connect( _on_toggled_tab.bind(index) )

func _on_toggled_tab(button_pressed:bool, index:int):
	if button_pressed and _current_index != index:
		on_change.emit(index)
		_current_index = index


# PropertyUI implementation
func set_value(value):
	for tab in _tabs_holder.get_children():
		tab.queue_free()
	for tab in value:
		_tabs_holder.add_child(tab)

func get_value():
	return _tabs_holder.get_children()
	
func add_value(value):
	_tabs_holder.add_child(value)
