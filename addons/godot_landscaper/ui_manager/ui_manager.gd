@tool
extends Control
class_name UIManager
## Manages the Landscaper Dock elements:
##  * Opens/closes UI using StateMachine resource
##  * Routes control calls from Landscaper class

@onready var brush_size:CustomRange = %BrushSize
@onready var settings:Settings = %Settings
@onready var grass_scatter:GrassScatter = %GrassScatter
@onready var grass_color:GrassColor = %GrassColor
@onready var undo:Button = %Undo
@onready var redo:Button = %Redo
@onready var active:CheckButton = %Active
@onready var save:Button = %Save
@onready var load:Button = %Load

@onready var _tabs:CustomTabs = %Tabs
@onready var _brushes_holder:Control = %BrushesHolder
@onready var _sm:StateMachine = StateMachine.new( grass_scatter )

var brushes:Array:
	get: return _brushes_holder.get_children()


func _ready():
	UIProperty.disable_events = false
	Debug.debug_level = settings.debug_level
	
	_tabs.on_change.connect( _brush_changed )
	brush_size.on_change.connect( _on_brush_size_changed )
	brush_size.value = 1.0


func _brush_changed():
	var brush:UIBrush = _brushes_holder.get_node( NodePath(_tabs.selected_tab.name) )
	_sm.switch( brush )

func _on_brush_size_changed():
	pass


func over_surface(info:Dictionary):
	pass

func not_over_surface():
	pass

func paint_start(info:Dictionary):
	Debug.other("Painting started")
	_sm.current._paint_start( info )

func paint_primary(info:Dictionary):
	Debug.spam("Painting with primary..")
	_sm.current._paint_primary( info )

func paint_secondary(info:Dictionary):
	Debug.spam("Painting with secondary..")
	_sm.current._paint_secondary( info )

func paint_end():
	Debug.other("Painting ended")
	_sm.current._paint_end()

func scale_by(sca:float):
	Debug.other("Scaled by %s" %sca)
	brush_size.value += sca
	
