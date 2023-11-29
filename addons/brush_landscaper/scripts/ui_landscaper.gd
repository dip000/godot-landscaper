@tool
extends Control
class_name UILandscaper
# * Opens/closes UI.
# * Receives control from PluginLandscaper.
# * Routes control values to active brush.



const _COMMON_DESCRIPTION := ", and mouse wheel + Shift to change brush size."
const _DESCRIPTIONS:PackedStringArray = [
	"Left click to build, right click to erase terrain",
	"Paint with left click, smooth color with right click",
	"Create mountains with left click, valleys with right click",
	"Paint with left click, smooth color with right click",
	"Spawn selected grass with left click, erase any grass with right click",
]


@onready var _blocker_full:Panel = $BlockerFull
@onready var _blocker_dock:Panel = $BlockerDock
@onready var _blocker_foot:Panel = $Foot/BlockerFoot

@onready var _description_label:Label = $Dock/Description
@onready var _tabs:CustomTabs = $Dock/Tabs

@onready var _brushes_holder:Control = $Dock/Body/ScrollContainer/MarginContainer
@onready var brush_size:CustomSliderUI = $Dock/BrushSize

# For easier public acces
@onready var terrain_builder:TerrainBuilder = _brushes_holder.get_node( "TerrainBuilder" )
@onready var terrain_clor:TerrainColor = _brushes_holder.get_node( "TerrainColor" )
@onready var terrain_height:TerrainHeight = _brushes_holder.get_node( "TerrainHeight" )
@onready var grass_color:GrassColor = _brushes_holder.get_node( "GrassColor" )
@onready var grass_spawn:GrassSpawn = _brushes_holder.get_node( "GrassSpawner" )
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
	brush_size.value = 0.01
	
	# For a type safe array
	for brush in _brushes_holder.get_children():
		brushes.append( brush )
	_brush_changed(0)

func _on_brush_size_changed(value):
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_scale", value)

func _brush_changed(index:int):
	# Change to active brush properties
	_active_brush = brushes[index]
	_active_brush.show()
	
	if _prev_brush:
		_prev_brush.hide()
	_prev_brush = _active_brush
	
	# Show description
	_description_label.text = _DESCRIPTIONS[index] + _COMMON_DESCRIPTION


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



# Brush control routing
func change_scene(scene:SceneLandscaper):
	_scene = scene
	set_enable( true )
	assets_manager.change_scene( self, _scene, brushes )
	
func save_ui():
	assets_manager.save_ui()

func over_terrain(pos:Vector3):
	var is_color_brush:bool = (_active_brush == terrain_clor or _active_brush == grass_color)
	var color:Color = _active_brush.color.value if is_color_brush else _active_brush.out_color
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_color", color)
	
	var brush_position:Vector2 = Vector2( pos.x, pos.z ) / Vector2( RawLandscaper.MAX_BUILD_REACH )
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_position", brush_position)
	
	pos.y += 1
	_scene.brush_sprite.global_position = pos
	_scene.brush_sprite.frame = _tabs.selected_tab

func paint(pos:Vector3, main_action:bool):
	_active_brush.paint( pos, main_action )
	_scene.terrain_overlay.position.y = 0.02

func paint_end():
	_active_brush.paint_end()
	_scene.terrain_overlay.position.y = 0.07

func scale_by(sca:float):
	brush_size.value += sca
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_scale", brush_size.value)
