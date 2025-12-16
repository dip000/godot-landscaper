## BUILDER: Interface members for all builder classes
##

@tool
@abstract
extends Resource
class_name GLBuilder


@abstract
func build(stroke_data:GLBuildData, controller:GLController) -> bool
