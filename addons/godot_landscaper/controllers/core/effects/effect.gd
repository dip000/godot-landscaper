## Abstract class for all effect classes.
##
## Implement '_apply' to run custom effects and stack them on controller.effects
## Run the Chunkifier at the end so all of the previous effects are passed to the chunks

@tool
@abstract
extends Resource
class_name GLEffect


## Helps remembering to unapply side-effects. Though clearing it must be run manually for responsivenes sake
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
	
	var applied:int = 0
	
	for i in effects.size():
		var effect:GLEffect = effects[i]
		GLDebug.internal("Effect i=%s, enabled=%s, is_applied=%s" %[i, effect.enable, effect.is_applied])
		
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
			GLDebug.error("The effect with index '%s' failed to be applied. Next effects will not be applied" %i)
			return false
		
		applied += 1
	
	if effects.is_empty():
		GLDebug.state("No Effects Were Applied. Add effects under 'GLController > Effects'")
	else:
		GLDebug.state("'%s/%s' Effects Were Applied" %[applied, effects.size()])
	return true


static func clear_all(effects:Array[GLEffect], controller:GLController) -> bool:
	for i in effects.size():
		if effects[i] and effects[i].is_running:
			GLDebug.error("Please wait until effect with index '%s' finishes running or delete it and add it again" %i)
			return false
	
	var cleared:int = 0
	
	for i in effects.size():
		var effect:GLEffect = effects[i]
		GLDebug.internal("Effect i=%s, enabled=%s, is_applied=%s" %[i, effect.enable, effect.is_applied])
		
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
			GLDebug.error("The effect with index '%s' failed to be cleared. Next effects will not be cleared" %i)
			return false
		
		cleared += 1
	
	if effects.is_empty():
		GLDebug.state("No Effects Were Cleared. Add effects under 'GLController > Effects'")
	else:
		GLDebug.state("'%s/%s' Effects Were Cleared" %[cleared, effects.size()])
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
