@tool
extends Control
class_name UIControl
## Manages the Landscaper Dock elements:
## * Opens/closes UI.
## * Receives control from PluginLandscaper.
## * Routes control to active brush and terrain overlay.

const COMMON_DESCRIPTION := ", and mouse wheel + Shift to change brush size."

@onready var _blocker_full:Panel = $BlockerFull
@onready var _blocker_dock:Panel = $BlockerDock
@onready var _blocker_foot:Panel = $Foot/BlockerFoot

@onready var _description_label:Label = $Dock/Description
@onready var _tabs:CustomTabs = $Dock/Tabs

@onready var _brushes_holder:Control = $Dock/Body/ScrollContainer/MarginContainer
@onready var brush_size:CustomSliderUI = $Dock/BrushSize

# For easier public acces
@onready var terrain_builder:TerrainBuilder = _brushes_holder.get_node( "TerrainBuilder" )
@onready var terrain_color:TerrainColor = _brushes_holder.get_node( "TerrainColor" )
@onready var terrain_height:TerrainHeight = _brushes_holder.get_node( "TerrainHeight" )
@onready var grass_color:GrassColor = _brushes_holder.get_node( "GrassColor" )
@onready var grass_spawn:GrassSpawn = _brushes_holder.get_node( "GrassSpawner" )
@onready var instancer:Instancer = _brushes_holder.get_node( "Instancer" )
@onready var assets_manager:AssetsManager = $Foot/AssetsManager

var brushes:Array[Brush]
var _scene:SceneLandscaper
var _active_brush:Brush
var _prev_brush:Brush


func _ready():
	set_enable( false )
	set_dock_enable( true )
	set_foot_enable( true )
	
	_tabs.on_change.connect( _brush_changed )
	brush_size.on_change.connect( _on_brush_size_changed )
	brush_size.value = 0.05
	Brush.ui = self
	
	# For a type safe array
	for brush in _brushes_holder.get_children():
		brushes.append( brush )
	_brush_changed(0)
	

func _on_brush_size_changed(value):
	_scene.overlay.set_brush_scale( value )

func _brush_changed(index:int):
	# Change to active brush properties
	_active_brush = brushes[index]
	_active_brush.show()
	_active_brush.selected_brush()
	
	if _scene:
		_scene.overlay.set_brush_index( index )
	
	if _prev_brush:
		_prev_brush.hide()
		_active_brush.deselected_brush()
	_prev_brush = _active_brush
	
	# Show description
	_description_label.text = _active_brush.DESCRIPTION + COMMON_DESCRIPTION


# Blockers
func set_enable(enable:bool):
	fade( _blocker_full, enable )

func set_dock_enable(enable:bool):
	fade( _blocker_dock, enable )

func set_foot_enable(enable:bool, msg:String=""):
	fade( _blocker_foot, enable )
	_blocker_foot.get_node("Label").text = msg

func fade(blocker:Control, fade_out:bool):
	var tween:Tween = create_tween()
	if fade_out:
		tween.tween_property( blocker, "modulate", Color.TRANSPARENT, 0.2 )
		tween.finished.connect( blocker.hide )
	else:
		blocker.show()
		tween.tween_property( blocker, "modulate", Color.WHITE, 0.2 )


# Control routing
func selected_scene(scene:SceneLandscaper):
	_scene = scene
	set_enable( true )
	assets_manager.selected_scene( scene )

func deselected_scene(scene:SceneLandscaper):
	_scene = null
	set_enable( false )
	assets_manager.deselected_scene( scene )

func save_ui():
	assets_manager.save_ui()

func over_terrain(pos:Vector3):
	_scene.overlay.hover_terrain( pos )

func paint_start(pos:Vector3):
	_active_brush.paint_start( pos )
	_scene.overlay.paint_start()

func paint_primary(pos:Vector3):
	_active_brush.paint_primary( pos )

func paint_secondary(pos:Vector3):
	_active_brush.paint_secondary( pos )

func paint_end():
	_active_brush.paint_end()
	_scene.overlay.paint_end()

func scale_by(sca:float):
	brush_size.value += sca
	_scene.overlay.set_brush_scale( brush_size.value )
	

