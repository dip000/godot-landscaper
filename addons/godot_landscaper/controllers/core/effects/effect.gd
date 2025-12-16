## EFFECT: Interface members for all effect classes
##

@tool
@abstract
extends Resource
class_name GLEffect


const AWAIT_INDEX_COUNT:int = 100
var running:bool = false


func apply_safe(stroke_data:GLBuildData, controller:GLController) -> void:
	if not stroke_data:
		GLDebug.error("There's no stroke_data to apply effect. An error while brushing might have caused this")
		return
	
	if running:
		GLDebug.error("Please wait until effect finishes running")
		return
	
	running = true
	var result = await _apply(stroke_data, controller)
	running = false
	
	if not result:
		GLDebug.error("Executable failed")
	

# ========= APPLY INTERFACE ===================
## Implement using frame skip utilities every so often for heavy loads
@abstract
func _apply(stroke_data:GLBuildData, controller:GLController) -> bool


# ========= FRAME SKIP UTILITIES ==============
func _index(index:int):
	if index % AWAIT_INDEX_COUNT == 0:
		await Engine.get_main_loop().process_frame
	
func _frame():
	await Engine.get_main_loop().process_frame
	
