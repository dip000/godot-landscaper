## BUILDER: Interface members for all builder classes
##

@tool
@abstract
extends Resource
class_name GLBuilder


@abstract
func build(mm:MultiMesh, build_data:GLBuildData) -> bool
