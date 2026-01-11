## Gobal configuration chacheing for Tweens.
## NOTE: Doesn't keep the actual tween reference. It creates and destroys it dynamically.
##
## Regular Tweens are self-destroyed at their end of their lifetimes,
## this introduces too much boilerplate configuration each time.
## With this wrapper however, you can keep the configurations stored
## globally and call the api at any time from any place.
##
## --------------- 1. Using instance methods -----------------------
## # configure shader wind strength from 10 to 100
##  wind = GLAPITween.create(material, "shader_parameter/wind", 10, 100) 
##  # animate a "breeze" with 1s to reach 100 strength, 5s to hold, and reset to 10 in 5s
##  wind.set_hold_and_reset(1, 5, 5)
##  # gracefully cancel the breeze animation
##  wind.reset(2)
## 
## --------------- 2. Using static methods with global keys --------
##  GLAPITween.global_create("wind", material, "shader_parameter/wind", 10, 100) 
##  GLAPITween.global_set_hold_and_reset("wind", 1, 5, 5) 
##  GLAPITween.global_reset("wind", 2)
##
## --------------- 3. Setting up exports from inspector ------------
## NOT-IMPLEMENTED
##

@tool
extends GLAPI
class_name GLAPITween

@export_group("Target")
## Tween's target object
var object:Object:
	get: return object if object else resource
## Alternatively, Tween's target resource
@export var resource:Resource
## Property string of the target object
@export var property:String

@export_group("Start", "start_")
## Configurable time to start
@export var start_time:float
## Value after start time
@export var start_value:Variant

@export_group("Hold", "hold_")
## Configurable time to hold
@export var hold_time:float

@export_group("Reset", "reset_")
## Configurable time to reset
@export var reset_time:float
## Value after reset time
@export var reset_value:Variant

@export_group("Interpolation")
@export var trans:Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR
@export var ease:Tween.EaseType = Tween.EaseType.EASE_IN_OUT

## Will be created and destroyed dinamically
var tween:Tween


## Anonymous constructor for creating a GLAPITween.
static func create(
	object:Object, property:String,
	trans:Tween.TransitionType=Tween.TRANS_LINEAR, ease:Tween.EaseType=Tween.EASE_IN_OUT
	) -> GLAPITween:
	
	var new_tween:GLAPITween = GLAPITween.new()
	new_tween.object = object
	new_tween.property = property
	new_tween.trans = trans
	new_tween.ease = ease
	return new_tween


## Constructor for globally registering a tween.
## Use a key to identify the created tween, like a string "global_wind"
## Creates a tween instance and sets its properties for later use, like tween.set_hold_and_reset(..)
static func global_create(
	key:Variant, object:Object, property:String,
	trans:Tween.TransitionType=Tween.TRANS_LINEAR, ease:Tween.EaseType=Tween.EASE_IN_OUT
	) -> GLAPITween:
	
	var new_tween:GLAPITween = _find_or_create( key, GLAPITween )
	new_tween.key = key
	new_tween.object = object
	new_tween.property = property
	new_tween.trans = trans
	new_tween.ease = ease
	return new_tween


## Configure initial and finish values. Tip: use a daisy chain with constructors:
## create(..).set_values(..)
func set_values(initial_value:Variant, final_value:Variant):
	self.initial_value = initial_value
	self.final_value = final_value
	return self


## Configure times. Tip: use a daisy chain with constructors:
## create(..).set_times(..)
func set_times(start_time:float, hold_time:float, reset_time:float):
	self.start_time = start_time
	self.hold_time = hold_time
	self.reset_time = reset_time
	return self


## Uses the properties assigned in constructors to manage a start behavior
static func global_start(key:Variant):
	var tween:GLAPITween = _find_or_create( key, GLAPITween )
	tween.start()


## Uses the properties assigned in constructors to manage a reset behavior
static func global_reset(key:Variant):
	var tween:GLAPITween = _find_or_create( key, GLAPITween )
	tween.reset()


## Uses the properties assigned in constructors to manage a start_hold_and_reset behavior
static func global_start_hold_and_reset(key:Variant):
	var tween:GLAPITween = _find_or_create( key, GLAPITween )
	tween.start_hold_and_reset()


## Kills and unregisters this tween
func destroy():
	if tween:
		if tween.is_running():
			tween.kill()
		tween.free()
	super()


## Stops current animation and recreates the tween anew
## TODO: Find a reliable way to insert a tween inside the SceneTree
## TODO: Add a fade if it was running
func _revive_tween():
	if tween and tween.is_running():
		tween.kill()
	tween = Engine.get_main_loop().create_tween()


## Null tween for RefCounted freeing instead of doing it directly.
## This helps end users manage their references if needed.
func _kill_tween_on_end():
	tween.chain().tween_callback(_nullify_tween)
func _nullify_tween():
	tween = null


## Uses the properties assigned in constructors to manage a start behavior
func start() -> PropertyTweener:
	_revive_tween()
	var prop:PropertyTweener = tween.tween_property(
		object, property, start_value, start_time
	).set_trans(trans).set_ease(ease)
	_kill_tween_on_end()
	return prop


## Uses the properties assigned in constructors to manage a reset behavior
func reset() -> PropertyTweener:
	_revive_tween()
	var prop:PropertyTweener = tween.tween_property(
		object, property, reset_value, reset_time
	).set_trans(trans).set_ease(ease)
	_kill_tween_on_end()
	return prop


## Uses the properties assigned in create(..) to manage a set_hold_and_reset behavior
func start_hold_and_reset() -> PropertyTweener:
	_revive_tween()
	
	tween.chain().tween_property(
		object, property, start_value, start_time
	).set_trans(trans).set_ease(ease)
	
	tween.chain().tween_interval( hold_time )
	
	var prop:PropertyTweener = tween.chain().tween_property(
		object, property, reset_value, reset_time
	).set_trans(trans).set_ease(ease)
	
	_kill_tween_on_end()
	return prop
