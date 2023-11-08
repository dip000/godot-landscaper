@tool
extends Control
class_name UILandscaper
# * Opens/closes UI.
# * Receives control from PluginLandscaper.
# * Routes control values to active brush.



const _COMMON_DESCRIPTION := ", and mouse wheel to change brush size."
const _DESCRIPTIONS:PackedStringArray = [
	"Left click to build, right click to erase terrain",
	"Paint with left click, smooth color with right click",
	"Create mountains with left click, valleys with right click",
	"Paint with left click, smooth color with right click",
	"Spawn selected grass with left click, erase any grass with right click",
]


@onready var _blocker:Panel = $Blocker
@onready var _description_label:Label = $Dock/Description
@onready var _tabs:CustomTabs = $Dock/Tabs
@onready var _assets_manager:AssetsManager = $Dock/AssetsManager

@onready var _brushes_holder:Control = $Dock/Body/MarginContainer
@onready var brush_size:CustomSliderUI = $Dock/BrushSize

# For easy acces from Brush classes
@onready var terrain_builder:TerrainBuilder = $Dock/Body/MarginContainer/TerrainBuilder
@onready var terrain_clor:TerrainColor = $Dock/Body/MarginContainer/TerrainColor
@onready var terrain_height:TerrainHeight = $Dock/Body/MarginContainer/TerrainHeight
@onready var grass_color:GrassColor = $Dock/Body/MarginContainer/GrassColor
@onready var grass_spawn:GrassSpawn = $Dock/Body/MarginContainer/GrassSpawner

var _brushes:Array[Brush]
var _scene:SceneLandscaper
var _previous_brush:Brush
var active_brush:Brush


func _ready():
	set_enable( false )
	active_brush = terrain_builder
	active_brush.enter()
	brush_size.on_change.connect( _on_brush_size_changed )
	_tabs.on_change.connect( _brush_changed )
	
	for brush in _brushes_holder.get_children():
		_brushes.append( brush )

func set_enable(enable:bool):
	_blocker.visible = not enable

func unpack(scene:SceneLandscaper):
	_scene = scene
	_assets_manager.unpack( self, _scene, _brushes )
	set_enable( true )

func pack():
	_assets_manager.pack()


func _on_brush_size_changed(value):
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_scale", value/100)

func _brush_changed(index:int):
	# Change to active brush properties
	active_brush = _brushes[index]
	active_brush.enter()
	
	if _previous_brush:
		_previous_brush.exit()
	_previous_brush = active_brush
	
	# Show description
	_description_label.text = _DESCRIPTIONS[index] + _COMMON_DESCRIPTION



func exit_terrain():
	print("Exit")

func over_terrain(pos:Vector3):
	var color_brush:bool = (active_brush == terrain_clor or active_brush == grass_color)
	var color:Color = active_brush.color.value if color_brush else active_brush.out_color
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_color", color)
	
	var bounds_size:Vector2 = terrain_builder.bounds_size
	var pos_rel:Vector2 = Vector2(pos.x, pos.z) / bounds_size - Vector2(0.5, 0.5)
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_position", pos_rel)

func paint(pos:Vector3, main_action:bool):
	active_brush.paint( pos, main_action )
	_scene.terrain_overlay.position.y = 0.02

func paint_end():
	_scene.terrain_overlay.position.y = 0.13

func scale_by(sca:float):
	brush_size.value += sca
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_scale", brush_size.value/100)
