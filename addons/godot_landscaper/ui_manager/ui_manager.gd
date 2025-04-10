@tool
extends Control
class_name UIManager
## Manages the Landscaper Dock elements:
##  * Opens/closes UI using StateMachine resource
##  * Routes control calls from Landscaper class

@onready var brush_diameter:UIRange = %BrushDiameter
@onready var active:CheckButton = %Active
@onready var action_tabs:UITabs = %ActionTabs

@onready var _actions_holder:Control = %ActionsHolder
@onready var _sm := StateMachine.new( %Spawner )


func _ready():
	Debug.debug_level = %DebugLevel
	action_tabs.on_change.connect( _on_action_changed )


func _on_action_changed():
	var tab_name:String = action_tabs.selected_tab.name
	var action:UIAction = _actions_holder.get_node( tab_name )
	_sm.switch( action )


func action_start(hit_info:Dictionary):
	(_sm.current as UIAction).action_start( hit_info )

func action_primary(hit_info:Dictionary):
	(_sm.current as UIAction).action_primary( hit_info )

func action_secondary(hit_info:Dictionary):
	(_sm.current as UIAction).action_secondary( hit_info )

func action_end():
	(_sm.current as UIAction).action_end()


func scale_by(value:float):
	brush_diameter.value += value
