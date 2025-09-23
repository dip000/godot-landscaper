extends Node
class_name SceneElement
## Base functionality for high level commands from Landscaper and InspectorTools
## -Manages scene references
## -Hosts scene configurations and global settings
## -Routes commands down to Brush classes


# ========= DEBUGS ===========================
## The amount of messages printed from Godot Landscaper
@export var level:GLDebug.Level=GLDebug.Level.STATES:
	set(v): GLDebug.level = v
	get: return GLDebug.level


## Diameter of the 3D brush sphere. Keybind is [Shift] + [MouseWheel]
@export_range(0.1, 20, 0.1) var brush_size:float = 2.0:
	set(v):
		if Landscaper.running():
			Landscaper.scene.brush.set_scale_ratio(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_scale_ratio()
		return 0.1

## Color of the 3D brush shpere
@export var brush_color:Color = Color(0.859, 0.439, 0.576, 0.5):
	set(v):
		if Landscaper.running():
			Landscaper.scene.brush.set_color(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_color()
		return Color(0.859, 0.439, 0.576, 0.5)

# ========= LIFEHACKS ========================
# This avoids calling notify_property_list_changed() too often or stack overflowing it
var _notify_dirty:bool
func _notify_property_list_changed_once() -> void:
	_notify_dirty = true
	_call_notify_property_list.call_deferred()
func _call_notify_property_list() -> void:
	if _notify_dirty:
		_notify_dirty = false
		notify_property_list_changed()
		GLDebug.spam("Notified property list change once")

# This avoids clicktrhough
var is_ready:bool
func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	is_ready = true


# ========= UNDO - REDO ========================
func _create_undo_redo(action:String) -> void:
	Landscaper.undo_redo.commit_action(false) # closes previous commits in case of errors
	Landscaper.undo_redo.create_action("godot_landscaper/%s/%s" %[name.to_snake_case(), action.to_snake_case()])

func _commit_undo_redo() -> void:
	Landscaper.undo_redo.commit_action(false)

func clear_undo_redo() -> void:
	Landscaper.undo_redo.commit_action(false)
	Landscaper.undo_redo.clear_history( EditorUndoRedoManager.GLOBAL_HISTORY )

func _add_redo(save_data:GLSaveData) -> void:
	var undo_redo:EditorUndoRedoManager = Landscaper.undo_redo
	undo_redo.add_do_property( save_data, "top_colors", save_data.top_colors.duplicate() )
	undo_redo.add_do_property( save_data, "bottom_colors", save_data.bottom_colors.duplicate() )
	undo_redo.add_do_property( save_data, "transforms", save_data.transforms.duplicate() )
	undo_redo.add_do_method( self, "stroke_rebuild" )

func _add_undo(save_data:GLSaveData) -> void:
	var undo_redo:EditorUndoRedoManager = Landscaper.undo_redo
	undo_redo.add_undo_property( save_data, "top_colors", save_data.top_colors.duplicate() )
	undo_redo.add_undo_property( save_data, "bottom_colors", save_data.bottom_colors.duplicate() )
	undo_redo.add_undo_property( save_data, "transforms", save_data.transforms.duplicate() )
	undo_redo.add_undo_method( self, "stroke_rebuild" )


# ========= BRUSH STROKES INTERFACE ========================
func select_brush(brush_name:String):
	pass

func stroke_start(hit_info:Dictionary) -> void:
	pass

func stroke_primary(hit_info:Dictionary) -> void:
	pass

func stroke_secondary(hit_info:Dictionary) -> void:
	pass

func stroke_end() -> void:
	pass
