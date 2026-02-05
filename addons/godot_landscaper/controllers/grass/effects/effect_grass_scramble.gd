## Grass Scrambler. Randomizes instance positions.
##
## Usefull when using MultiMesh.visible_instances != 0. Example:
## - Before scrambling: Will most likely hide entire uneven patches of grass.
## - After scrambling: Will always hide them as density-based
##

@tool
extends GLEffect
class_name GLGrassScramble


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Scrambler Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	
	controller = controller as GLControllerGrass
	var source:GLBuildDataGrass = controller.source
	var processed:GLBuildDataGrass = controller.processed
	var deck_transforms:Array[Transform3D] = processed.transforms.duplicate()
	var hand_transforms:Array[Transform3D]
	
	for i in processed.size():
		var random_transform:int = randi_range( 0, deck_transforms.size()-1 )
		var transform:Transform3D = deck_transforms.pop_at( random_transform )
		hand_transforms.append( transform )
		await _100_index( i )
	
	processed.transforms = hand_transforms
	GLDebug.state("Grass Scrambler Succesfull")
	return true
	

func _clear(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Scrambler Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	return true
	
	
