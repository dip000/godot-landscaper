@tool
extends Control
class_name UILandscaper
# UI Manager: Opens/closes UI, and routes UI values to brushes.
#  * Order of node brushes must follow enumerators in 'Brush'
#  * Order of node properties must follow enumerators in brush extensions like 'GrassSpawn'
#  * Each property must implement 'PropertyUI'


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
@onready var _tabs:TabBar = $Dock/TabBar

@onready var brushes_holder:Control = $Dock/Body/MarginContainer
@onready var brush_size:CustomSliderUI = $Dock/BrushSize

@onready var terrain_builder:TerrainBuilder = $Dock/Body/MarginContainer/TerrainBuilder
@onready var terrain_clor:TerrainColor = $Dock/Body/MarginContainer/TerrainColor
@onready var terrain_height:TerrainHeight = $Dock/Body/MarginContainer/TerrainHeight
@onready var grass_color:GrassColor = $Dock/Body/MarginContainer/GrassColor
@onready var grass_spawn:GrassSpawn = $Dock/Body/MarginContainer/GrassSpawner

var _scene:SceneLandscaper
var _previous_brush:Brush
var active_brush:Brush


func _ready():
	set_enable( false )
	active_brush = terrain_builder
	active_brush.enter()
	brush_size.on_change.connect( _on_brush_size_changed )
	_tabs.tab_changed.connect( _brush_changed )

func set_enable(enable:bool):
	_blocker.visible = not enable

func update_from_scene(scene:SceneLandscaper):
	print("update_from_scene")
	_scene = scene
	set_enable( true )
	for brush in brushes_holder.get_children():
		brush.scene = scene
		brush.ui = self
		brush.setup()
		brush.template( Vector2i(10, 10) )
	

func _on_brush_size_changed(value):
	_scene.terrain_overlay.material_override.set_shader_parameter("brush_scale", value/100)

func _brush_changed(index:int):
	# Change to active brush properties
	active_brush = brushes_holder.get_child(index)
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
