## Abstract class for all effect classes.
##
## Implement '_apply' to run custom effects and stack them on controller.effects
## Run the Chunkifier at the end so all of the previous effects are passed to the chunks

@tool
@abstract
extends Resource
class_name GLEffect


## Helps remembering to unapply side-effects. Tough clearing it must be run manually for responsivenes sakee
@export_storage var is_applied:bool = false

## Keeps the effect inside the controller but does not apply it.
@export var enable:bool = true

## Flag for async awaits
var is_running:bool = false


# ========= PUBLIC INTERFACE =============
static func apply_all(effects:Array[GLEffect], controller:GLController) -> bool:
	for i in effects.size():
		if effects[i] and effects[i].is_running:
			GLDebug.error("Please wait until effect with index '%s' finishes running or delete it and add it again" %i)
			return false
	
	for i in effects.size():
		var effect:GLEffect = effects[i]
		if not effect:
			continue
		if not effect.enable:
			continue
		
		effect.is_running = true
		var success:bool = await effect._apply( controller )
		await _frame()
		effect.is_running = false
		effect.is_applied = true
		
		if not success:
			GLDebug.error("The effect with index '%s' failed to be applied" %i)
			return false
	return true


static func clear_all(effects:Array[GLEffect], controller:GLController) -> bool:
	for i in effects.size():
		if effects[i] and effects[i].is_running:
			GLDebug.error("Please wait until effect with index '%s' finishes running or delete it and add it again" %i)
			return false
	
	for i in effects.size():
		var effect:GLEffect = effects[i]
		if not effect:
			continue
		if not effect.enable:
			continue
		
		effect.is_running = true
		var success:bool = await effect._clear( controller )
		effect.is_running = false
		effect.is_applied = false
		
		if not success:
			effect.is_applied = true
			GLDebug.error("The effect with index '%s' failed to be cleared" %i)
			return false
	return true


# ========= EXECUTABLE INTERFACE =============
## Implement using frame skip utilities every so often for heavy loads
@abstract
func _apply(controller:GLController) -> bool

@abstract
func _clear(controller:GLController) -> bool


# ========= FRAME SKIP UTILITIES ==============
func _100_index(index:int):
	if index % 100 == 0:
		await Engine.get_main_loop().process_frame

func _10_index(index:int):
	if index % 10 == 0:
		await Engine.get_main_loop().process_frame

static func _frame():
	await Engine.get_main_loop().process_frame

static func _timeout(time:float):
	await Engine.get_main_loop().create_timer(time).timeout


# ========= OTHER UTILITIES ==============
func _format_chunk(chunk:Vector2i) -> String:
	return "Chunk_%s_%s" %[chunk.x, chunk.y]
