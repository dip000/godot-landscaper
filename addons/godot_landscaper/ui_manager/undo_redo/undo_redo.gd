@tool
extends HBoxContainer
class_name Undo

var _ur := UndoRedo.new()

@export_tool_button("Test action") var test_action:Callable=_test_action
@export_tool_button("Undo") var undo_pressed:Callable=_ur.undo
@export_tool_button("Redo") var redo_pressed:Callable=_ur.redo

@onready var _undo:Button = %Undo
@onready var _redo:Button = %Redo
@onready var _active:CheckButton = %Active

var enabled:bool:
	get: return _active.is_pressed()
	set(v): _active.set_pressed(v)



func _ready():
	_undo.pressed.connect( _ur.undo )
	_redo.pressed.connect( _ur.redo )
	_active.toggled.connect( _on_active_toggled )


func _on_active_toggled(toggled_on:bool):
	_active.text = "Eco Landscaper 0.3.0 "
	_active.text += "Enabled " if toggled_on else "Disabled"
	_undo.disabled = not toggled_on
	_redo.disabled = not toggled_on

func _test_action():
	_ur.create_action("idk", UndoRedo.MERGE_DISABLE)
	_ur.add_do_method(_test_do)
	_ur.add_undo_method(_test_undo)
	_ur.commit_action()


func _test_do():
	print("_test_do: %s" %_ur.get_current_action_name())

func _test_undo():
	print("_test_undo: %s" %_ur.get_current_action_name())
