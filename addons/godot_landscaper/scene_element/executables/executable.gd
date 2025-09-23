@tool
extends Resource
class_name Executable

const AWAIT_INDEX_COUNT:int = 100
var running:bool = false

## [NOT-IMPLEMENTED]
@export var auto_execute_on_rebuild:bool = false
@export_tool_button("    Run    ", "UndoRedo") var _run:Callable = _run_executable
@export_tool_button("    Reset  ", "Object") var _reset:Callable = _reset_executable


func _run_executable():
	_executable( run )
	
func _reset_executable():
	_executable( reset )

func _executable(callback:Callable):
	var grass:Grass3D = Landscaper.element as Grass3D
	if not grass:
		GLDebug.error("You can't run executables on non-Grass3D classes")
		return
	
	if running:
		GLDebug.warning("Please wait until exectutable finishes running")
		return
	
	running = true
	var result = await callback.call(grass, grass.save_data)
	running = false
	
	if result == null:
		GLDebug.error("Executable failed unexpectedly. Please report")
	elif result != "OK":
		GLDebug.warning("Executable failed: %s" %result)
	

# ========= EXEC INTERFACE ===================
## Implement using frame skip utilities every so often for heavy loads
func run(element:SceneElement, save_data:GLSaveData) -> String:
	return "Not implemented"

func reset(element:SceneElement, save_data:GLSaveData) -> String:
	return "Not implemented"


# ========= FRAME SKIP UTILITIES ==============
func _index(index:int):
	if index % AWAIT_INDEX_COUNT == 0:
		await Engine.get_main_loop().process_frame
	
func _frame():
	await Engine.get_main_loop().process_frame
	
