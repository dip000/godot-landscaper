## Abstract class for all effect classes.
## Implement '_apply' to run custom effects and stack them on controller.effects
##
## Run the Chunkifier at the end so all of the previous effects are passed to the chunks

@tool
@abstract
extends Resource
class_name GLEffect

const AWAIT_INDEX_COUNT:int = 100

@export_storage var is_applied:bool = false
@export var enable:bool = true

var running:bool = false


# ========= PUBLIC INTERFACE =============
## The controller calls apply on each effect.
## Does not modify the GLBuildData in GLController.source
func apply(controller:GLController) -> void:
	if not enable:
		return
	
	if running:
		GLDebug.error("Please wait until effect finishes running")
		return
	
	running = true
	var result = await _apply(controller)
	running = false
	is_applied = true
	
	if not result:
		GLDebug.error("Effect with index '%s' failed" %controller.effects.find(self))


## Some effects may apply other side-effects like creating nodes.
## The controller calls clear on each effect to make sure the side-effects are cleaned up 
func clear(controller:GLController) -> void:
	if not enable:
		return
	
	if running:
		GLDebug.error("Please wait until effect finishes running")
		return
	
	running = true
	var result = await _clear(controller)
	running = false
	is_applied = false
	
	if not result:
		GLDebug.error("Effect with index '%s' failed" %controller.effects.find(self))


# ========= EXECUTABLE INTERFACE =============
## Implement using frame skip utilities every so often for heavy loads
@abstract
func _apply(controller:GLController) -> bool

@abstract
func _clear(controller:GLController) -> bool


# ========= FRAME SKIP UTILITIES ==============
func _index(index:int):
	if index % AWAIT_INDEX_COUNT == 0:
		#await Engine.get_main_loop().process_frame
		pass
	
func _frame():
	pass
	#await Engine.get_main_loop().process_frame
	
