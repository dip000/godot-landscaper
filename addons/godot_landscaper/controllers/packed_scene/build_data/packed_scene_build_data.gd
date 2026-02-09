extends GLBuildData
class_name GLBuildDataPackedScene


@export_group("Resources")
@export var scene:PackedScene

@export_group("Raw Data")
## Positions, rotations and scales of each instance
@export var transforms:Array[Transform3D]

# For runtime building
# Sometimes bugs if it's not stored..
@export_storage var dirty_instances:PackedInt32Array
@export_storage var dirty_erases:PackedInt32Array





	
