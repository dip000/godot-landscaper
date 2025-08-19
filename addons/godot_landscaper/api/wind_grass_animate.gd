## Grass Wind Utility Animations. Examples..
## ---------------Use static methods---------------
## func _ready():
##    WindGrassAnimate.animate_wind_start(my_material, Vector3.LEFT, Vector3.ONE, 3.0)
##    WindGrassAnimate.animate_wind_start(my_other_material, Vector3.RIGHT, Vector3.ONE, 3.0)
##
## ---------------Setup export from inspector------
## @export var wind:WindGrassAnimate
## func _ready():
##   wind.blow_breeze()
##
## ---------------Setup from constructor------------
## func _ready():
##   var wind = WindGrassAnimate.create(my_material, Vector3.LEFT, Vector3.ONE, 3.0)
##   wind.start_wind()
##   wind.blow_breeze()

@tool
extends Resource
class_name WindGrassAnimate

const FREQUENCY_PATH := "shader_parameter/sway_frequency_animatable"
const DIRECTION_PATH := "shader_parameter/wind_strength"

static var _current_wind_animations:Dictionary[ShaderMaterial, Tween]

## Material where the grass shader is hosted.
## Must have 'sway_frequency_animatable' and 'wind_direction' properties
@export var grass_material:ShaderMaterial

## Wind direction and strenght; how much the grass will strech towards a direction
@export var strength:Vector3
## Sway speed; how fast the grass will shake
@export var frequency:Vector3

## Starting transition time
@export var start_time:float
## Time to wait before subsiding. Only applicable on breezes
@export var holding_time:float
## Ending transition time
@export var end_time:float

@export_tool_button("Wind Breeze", "FogVolume") var _blow_breeze:Callable = blow_breeze
@export_tool_button("Wind Start", "FogVolume") var _wind_start:Callable = start_wind
@export_tool_button("Wind End", "FogVolume") var _wind_end:Callable = end_wind


static func _get_wind_animation(material:ShaderMaterial) -> Tween:
	if not (material in _current_wind_animations):
		_current_wind_animations[material] = Landscaper.scene.create_tween()
	return _current_wind_animations[material]


static func _reset_wind_animation(material:ShaderMaterial):
	var wind_animation:Tween = _get_wind_animation( material )
	if wind_animation.is_running():
		wind_animation.kill()
	_current_wind_animations.erase( material )


static func _set_wind_animation(material:ShaderMaterial, to_strength:Vector3, to_frequency:Vector3, time:float) -> PropertyTweener:
	var wind_animation:Tween = _get_wind_animation( material )
	
	#[TODO] Make freq constantly increase until end() is called
	wind_animation.tween_property(
		material, FREQUENCY_PATH, to_frequency, time
	).set_trans( Tween.TRANS_BACK )
	
	return wind_animation.parallel().tween_property(
		material, DIRECTION_PATH, to_strength, time
	).set_trans( Tween.TRANS_BACK )


static func _validate(material:ShaderMaterial) -> bool:
	if not material:
		GLDebug.error("Material is null")
		return false
	for path in [FREQUENCY_PATH, DIRECTION_PATH]:
		if not (path in material):
			GLDebug.error("Shader property '%s', not found in material '%s'" %[path, material.resource_path])
			return false
	return true


## Constructor
static func create(material:ShaderMaterial, to_strength:Vector3, to_frequency:Vector3, start_time_transition:float=0, hold_time:float=0, end_time_transition:float=0) -> WindGrassAnimate:
	var inst := WindGrassAnimate.new()
	inst.grass_material = material
	inst.direction = to_strength
	inst.frequency = to_frequency
	inst.start_time = start_time_transition
	inst.holding_time = hold_time
	inst.end_time = end_time_transition
	return inst


## Starts and ends a wind breeze
static func animate_wind_breeze(material:ShaderMaterial, to_strength:Vector3, to_frequency:Vector3, start_time_transition:float, hold_time:float, end_time_transition:float):
	if not _validate(material): return
	_reset_wind_animation( material )
	var anim:PropertyTweener = _set_wind_animation( material, to_strength, to_frequency, start_time_transition )
	anim.set_delay( hold_time )
	return _set_wind_animation( material, to_strength, to_frequency, start_time_transition )



## Starts a constant wind. Call animate_wind_end(..) to reset
static func animate_wind_start(material:ShaderMaterial, to_strength:Vector3, to_frequency:Vector3, duration:float) -> PropertyTweener:
	if not _validate(material): return
	_reset_wind_animation( material )
	return _set_wind_animation(material, to_strength, to_frequency, duration)


## Ends a previously started wind. Starts with animate_wind_start(..)
static func animate_wind_end(material:ShaderMaterial, transition_time:float) -> PropertyTweener:
	if not _validate(material): return
	_reset_wind_animation( material )
	var property_anim:PropertyTweener = _set_wind_animation(material, Vector3.ZERO, Vector3.ZERO, transition_time)
	#cleanup
	var anim:Tween = _get_wind_animation( material )
	anim.tween_callback(_reset_wind_animation.bind( material ))
	return property_anim


## Blow wind as specified by export variables
func blow_breeze():
	animate_wind_breeze( grass_material, strength, frequency, start_time, holding_time, end_time )

## Start wind as specified by export variables
func start_wind():
	animate_wind_start( grass_material, strength, frequency, start_time )

## End wind as specified by export variables
func end_wind():
	animate_wind_end( grass_material, end_time )
