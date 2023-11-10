@tool
extends PropertyUI
class_name CustomTabs
# A toggle buttons group. Like the TabBar class but with a FlowContainer.
# Shows every tab without clipping or collapsing so we can have all content in view.

@onready var tabs_holder:FlowContainer = $Tabs


# Emits 'PropertyUI.on_change' every press of a button
func _ready():
	$Label.text = property_name
	var tabs:Array = tabs_holder.get_children()
	for index in tabs.size():
		tabs[index].toggled.connect( _on_toggled_tab.bind(index) )

func _on_toggled_tab(button_pressed:bool, index:int):
	if button_pressed:
		on_change.emit(index)


# PropertyUI implementation
func set_value(value):
	for tab in tabs_holder.get_children():
		tab.queue_free()
	for tab in value:
		tabs_holder.add_child(tab)

func get_value():
	return tabs_holder.get_children()
