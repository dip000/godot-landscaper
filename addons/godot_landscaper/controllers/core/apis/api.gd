## Abstraction for all GodorLandscaper Application Programming Interfaces
##
## * An API may implement static functions preffixed with "global_" with a "key" argument. Example:
##   2. GLAPI.global_create(key, ..) -> Creates and returns a globally accessed instance with a key
##   1. GLAPI.create(..) -> Not global, creates and returns an unregistered instance
##
## * An API is a resource, may be used in @export and may not implement _init()
##
## * An API may be used in 3 situations:
##
## --------------- 1. Using instance methods -----------------------
## func _ready():
##   var example_api:GLAPI = GLAPI.create(..)
##   example_api.do_example(..)
##
## --------------- 2. Using static methods with global keys --------
## func _ready():
##   GLAPI.global_create("my_global_key", ..)
## func on_example():
##   GLAPI.global_do_example("my_global_key")
##
## --------------- 3. Setting up exports from inspector ------------
## @export var example_api:GLAPI
## @export_tool_button(..) var _on_example_button=example_api.do_example
##

@tool
@abstract
extends Resource
class_name GLAPI


## Cache for GLAPITween.global_register(tween_key..)
## GLAPITween references are not destroyed automatically. Call GLAPITween.destroy_tween(tween_key) or tween.destroy()
static var _registered_apis:Dictionary[Variant, GLAPI]

## Identifier to be registered globally in _registered_apis
var key:Variant


## Finds a stored api instance by key or creates it if it didn't exist
static func _find_or_create(key:Variant, type) -> GLAPI:
	if key in _registered_apis:
		return _registered_apis[key]
	var new_tween:GLAPI = type.new()
	new_tween.key = key
	_registered_apis[key] = new_tween
	return new_tween


## Kills and unregisters tween, if exists
static func global_destroy(key:Variant):
	if key in _registered_apis:
		_registered_apis[key].destroy()


## Kills and unregisters all registered apis
static func global_destroy_all():
	for api in _registered_apis.values():
		api.destroy()
	_registered_apis.clear()


## Unregisters this api.
## Override for specific behavior
func destroy():
	_registered_apis.erase( key )
