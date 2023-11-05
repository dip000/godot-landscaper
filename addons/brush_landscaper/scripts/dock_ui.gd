@tool
extends VBoxContainer
class_name DockUI
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
#[NOTE] Using Array[PackedStringArray] causes Godot to crash..
const _NOTES:Array[Array] = [
	["Building new terrain will increase all brush texture sizes accodringly.", "This won't affect your current terrain placements"],
	["This will generate a texture in your selected directory"],
	[],
	["This will generate a texture in your selected directory"],
	["You can spawn up to 4 grass variants in Mobile or Forward+ renderers, but only one in Compatibility"],
]

static var _description_label:Label
static var _tabs:TabBar
static var _brushes:Array
static var _notes_label:Label

static var brush_size:CustomSliderUI
static var active_brush:int


func _ready():
	_description_label = $Description
	_tabs = $TabBar
	_brushes = $Panel/MarginContainer.get_children()
	_notes_label = $Notes
	brush_size = $BrushSize
	
	_tabs.tab_changed.connect( _brush_changed )
	_brush_changed( Brush.TERRAIN_BUILDER )

func _brush_changed(index:int):
	# Change to active brush properties
	for brush_property in _brushes:
		brush_property.hide()
	
	_brushes[index].show()
	active_brush = index

	# Show description and notes
	_description_label.text = _DESCRIPTIONS[active_brush] + _COMMON_DESCRIPTION
	
	_notes_label.text = ""
	for note in _NOTES[active_brush]:
		_notes_label.text += note + "\n\n"


# Generic getter for any property in dock. See 'Brush'
static func get_property(active_brush:int, property_index:int):
	var brush_ui:Control = _brushes[active_brush]
	var custom_property:PropertyUI = brush_ui.get_child( property_index )
	return custom_property.value

