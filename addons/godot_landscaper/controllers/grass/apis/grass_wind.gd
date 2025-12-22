## Grass Wind Animations API. Examples..
##
## --------------- 1. Using instance methods -----------------------
## func _ready():
##   var wind = GLAPIGrassWind.create(my_material, Vector3.LEFT, Vector3.ONE)
##   wind.start_wind()
##   wind.blow_breeze()
##
## --------------- 2. Using static methods with global keys --------
## func _ready():
##    GLAPIGrassWind.global_create(my_material, Vector3.LEFT, Vector3.ONE) # setup initial-finishing values
## func on_breeze():
##    GLAPIGrassWind.global_breeze(my_material, 1, 5, 5) # set start-hold-reset times
##
## --------------- 3. Setting up exports from inspector ------------
## @export var wind:GLAPIGrassWind
## @export_tool_button(..) var _on_breeze_button=wind.global_breeze
##

@tool
extends GLAPI
class_name GLAPIGrassWind

const FREQUENCY_PATH := "shader_parameter/sway_frequency_animatable"
const DIRECTION_PATH := "shader_parameter/wind_direction"

@export_tool_button("Test Breeze", "AtlasTexture") var _on_breeze_button=_test_breeze
func _test_breeze():
	assert(tween_direction and tween_frequency, "Set tween properties to test the grass wind API")
	assert(tween_direction.resource and tween_frequency.resource, "Set tween resources as the material to test the grass wind API")
	assert(typeof(tween_direction.initial_value)==TYPE_VECTOR3, "Wind direction initial value must be a Vector3")
	assert(typeof(tween_direction.final_value)==TYPE_VECTOR3, "Wind direction final value must be a Vector3")
	assert(typeof(tween_frequency.initial_value)==TYPE_VECTOR3, "Wind frequency initial value must be a Vector3")
	assert(typeof(tween_frequency.final_value)==TYPE_VECTOR3, "Wind frequency final value must be a Vector3")
	tween_frequency.property = FREQUENCY_PATH
	tween_direction.property = DIRECTION_PATH
	breeze()


## Sway speed; how aggressively the grass will shake
@export var tween_frequency:GLAPITween

## Wind direction and strenght; how much the grass will strech towards a direction
@export var tween_direction:GLAPITween


## Constructor for creating a GLAPIGrassWind instance.
static func create(tween_frequency:GLAPITween, tween_direction:GLAPITween) -> GLAPIGrassWind:
	var wind:GLAPIGrassWind = GLAPIGrassWind.new()
	wind.tween_frequency = tween_frequency
	wind.tween_direction = tween_direction
	return wind


## Constructor for globally registering a GLAPIGrassWind.
## Wind is global for each material so you may want to set key=material as well
static func global_create(key:Variant, tween_frequency:GLAPITween, tween_direction:GLAPITween) -> GLAPIGrassWind:
	var wind:GLAPIGrassWind = _find_or_create( key, GLAPIGrassWind )
	wind.tween_frequency = tween_frequency
	wind.tween_direction = tween_direction
	return wind


## Starts and ends a wind breeze
static func global_breeze(key:Variant):
	var wind:GLAPIGrassWind = _find_or_create( key, GLAPIGrassWind )
	wind.tween_frequency.start_hold_and_reset()
	wind.tween_direction.start_hold_and_reset()


## Starts a constant wind. Call animate_wind_end(..) to reset
static func global_start(key:Variant):
	var wind:GLAPIGrassWind = _find_or_create( key, GLAPIGrassWind )
	wind.start()


## Ends a previously started wind. Starts with animate_wind_start(..)
static func global_reset(key:Variant, reset_time:float):
	var wind:GLAPIGrassWind = _find_or_create( key, GLAPIGrassWind )
	wind.reset()


## Blow wind as specified by tweens
func breeze():
	tween_frequency.start_hold_and_reset()
	tween_direction.start_hold_and_reset()


## Start wind as specified by tweens
func start():
	tween_frequency.start()
	tween_frequency.start()


## End wind as specified by tweens
func reset():
	tween_frequency.reset()
	tween_frequency.reset()
	
	
