## Receivers of GLBuildData commands + GLController context
##
## Builders apply the build data to make the actual changes.
## Another responsibility is to ensure the references are set correctly.

@tool
@abstract
extends Resource
class_name GLBuilder

var _controller:GLController


func _init(controller:GLController):
	_controller = controller


## Builds from deltas, maps or flags so the build is cheaper
@abstract func build_from_dirty() -> bool

## Builds completely from GLController.source
@abstract func build_from_source() -> bool

## Builds completely from GLController.processed
@abstract func build_from_processed() -> bool




	
