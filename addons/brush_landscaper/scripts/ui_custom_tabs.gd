@tool
extends PropertyUI
class_name CustomTabs

@onready var tabs_holder:FlowContainer = $Tabs


func _ready():
	$Label.text = property_name
	var tabs:Array = tabs_holder.get_children()
	for index in tabs.size():
		tabs[index].toggled.connect( _on_toggled_tab.bind(index) )

func _on_toggled_tab(button_pressed:bool, index:int):
	if button_pressed:
		on_change.emit(index)


func set_value(value):
	for tab in tabs_holder.get_children():
		tab.queue_free()
	for tab in value:
		tabs_holder.add_child(tab)

func get_value():
	return tabs_holder.get_children()
