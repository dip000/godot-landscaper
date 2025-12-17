## Abstract class for all effect classes.
## Implement '_apply' to run custom effects and stack them on controller.effects
##
## DO NOT modify controller.resources.source,
## duplicate and use controller.resources.processed instead
##
## Run the Chunkifier at the end so all of the previous effects are passed to the chunks

@tool
@abstract
extends Resource
class_name GLEffect


const AWAIT_INDEX_COUNT:int = 100
var running:bool = false


func apply_safe(controller:GLController) -> void:
	if running:
		GLDebug.error("Please wait until effect finishes running")
		return
	
	running = true
	var result = await _apply(controller)
	running = false
	
	if not result:
		GLDebug.error("Effect with index '%s' failed" %controller.effects.find(self))
	

# ========= APPLY INTERFACE ===================
## Implement using frame skip utilities every so often for heavy loads
@abstract
func _apply(controller:GLController) -> bool


# ========= FRAME SKIP UTILITIES ==============
func _index(index:int):
	if index % AWAIT_INDEX_COUNT == 0:
		await Engine.get_main_loop().process_frame
	
func _frame():
	await Engine.get_main_loop().process_frame
	
