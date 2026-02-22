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


## Builds completely from given build_data
@abstract func build(from_data:GLBuildData) -> bool


## Optional first step for delta_build.
@abstract func quick_start(from_data:GLBuildData) -> bool


## Builds from a temporal delta object so the build is faster.
@abstract func quick_build(from_data:GLBuildData) -> bool


## Optional last step for delta_build.
@abstract func quick_end(from_data:GLBuildData) -> bool







	
