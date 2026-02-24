## Wrapper for EditorUndoRedoManager
##

@tool
extends Object
class_name GLUndoRedo

var _manager:EditorUndoRedoManager



func _init(manager:EditorUndoRedoManager):
	_manager = manager


func create(action:String) -> void:
	_manager.commit_action( false ) # closes previous commits in case of errors
	_manager.create_action( "godot_landscaper/%s" %action.to_snake_case() )

func commit() -> void:
	_manager.commit_action(false)

func clear() -> void:
	_manager.commit_action( false )
	_manager.clear_history( EditorUndoRedoManager.GLOBAL_HISTORY )

func add_redo(obj, data:GLBuildData) -> void:
	_manager.add_do_property( data, "top_colors", data.top_colors.duplicate() )
	_manager.add_do_property( data, "bottom_colors", data.bottom_colors.duplicate() )
	_manager.add_do_property( data, "transforms", data.transforms.duplicate() )
	_manager.add_do_method( obj, "stroke_rebuild" )

func add_undo(obj, data:GLBuildData) -> void:
	_manager.add_undo_property( data, "top_colors", data.top_colors.duplicate() )
	_manager.add_undo_property( data, "bottom_colors", data.bottom_colors.duplicate() )
	_manager.add_undo_property( data, "transforms", data.transforms.duplicate() )
	_manager.add_undo_method( obj, "stroke_rebuild" )
