## DATA: Interface members for all data classes
##

@tool
@abstract
extends Resource
class_name GLResources


## [TODO] Impement versioning and migration
@export_storage var version:String

## Runtime metadata to store the region where the data applies (for performance)
## [TODO] Impement region and previews
var region:Rect2


@export_group("Build Data")
@export var source:GLBuildData
@export var processed:GLBuildData



@abstract
func fix_references(settings:GLSettings) -> bool
