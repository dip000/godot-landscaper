@tool
extends GLEffect
class_name GLTerrainLoD

## Margin for the visibility_range_end threshold.
## The GeometryInstance3D will only change its visibility state when it goes over or under the visibility_range_end threshold by this amount.
@export var end_margin:float = 2.0
## Distance from which the GeometryInstance3D will be hidden, taking visibility_range_end_margin into account as well.
## The default value of 0 is used to disable the range check.
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32
## Changes how quickly the mesh transitions to a lower level of detail.[br]
## - A value of 0 will force the mesh to its lowest level of detail.[br]
## - A value of 1 will use the default settings.[br]
## - Larger values will keep the mesh in a higher level of detail at farther distances.
@export_range(0.001, 128.0, 0.001, "exp") var mesh_lod_bias:float = 1.0


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain LoD failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var original_terrain:MeshInstance3D = controller.terrain
	original_terrain.visibility_range_end = custom_lod_meters
	original_terrain.visibility_range_end_margin = end_margin
	original_terrain.lod_bias = mesh_lod_bias
	GLDebug.state("Effect LoD Applied to Terrain '%s'" %original_terrain.name)
	return true


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain LoD failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var original_terrain:MeshInstance3D = controller.terrain
	original_terrain.visibility_range_end = 0.0
	original_terrain.visibility_range_end_margin = 0.0
	original_terrain.lod_bias = 1.0
	return true
	
