@tool
extends UIProperty
class_name UITabs
## A toggle buttons group. Like the TabBar class but with a FlowContainer.
## Shows every tab without clipping or collapsing so we can have all content in view.

@export var _toggle_group := true
@onready var _tabs_holder:FlowContainer = %Tabs
var _button_group := ButtonGroup.new()

var tabs:Array[Node]:
	get: return _tabs_holder.get_children()

var selected_tab:Node:
	get: return _tabs_holder.get_child(selected_index)

var selected_index:int:
	get: return selected_index
	set(v):
		selected_index = v
		_tabs_holder.get_child(v).button_pressed = true

var layer_mask:int:
	get:
		var mask:int = 0
		for tab in enabled_tabs:
			if tab.button_pressed:
				mask |= (1<<tab.get_index())
		return mask

var enabled_tabs:Array[Node]:
	get: return tabs.filter(func(tab): return tab.button_pressed)


func _ready():
	$PanelContainer/VBoxContainer/Label.text = property_name
	for tab in _tabs_holder.get_children():
		if tab is BaseButton:
			tab.toggle_mode = true
			tab.button_group = _button_group if _toggle_group else null
			tab.toggled.connect( _on_toggled_tab.bind( tab.get_index() ) )


func _on_toggled_tab(button_pressed:bool, tab_index:int):
	if button_pressed and selected_index != tab_index:
		selected_index = tab_index
		change()


func add_tab(tab:Node, index:int):
	_tabs_holder.add_child(tab)
	tab.owner = owner
	_tabs_holder.move_child( tab, index )

func remove_tab(tab_name:String):
	var tab:Node = _tabs_holder.get_node( tab_name )
	tab.queue_free()
