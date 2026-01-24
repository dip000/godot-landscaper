@tool
extends GLEffect
class_name GLTerrainLoD

@export var end_margin:float = 2.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain LoD failed: This effect is only valid for GLControllerTerrain controller types")
		return false
		
	controller = controller as GLControllerTerrain
	var original_terrain:MeshInstance3D = controller.terrain
	original_terrain.visibility_range_end = custom_lod_meters
	original_terrain.visibility_range_end_margin = end_margin
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
	return true
	
