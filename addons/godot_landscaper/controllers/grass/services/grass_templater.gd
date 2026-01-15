extends Resource
class_name GLGrassTemplater

# Deck for card shuffling
static var _deck:Array[int]


static func _card_shuffle_next() -> int:
	if not _deck:
		_deck = [0, 1, 2, 3]
	var hand:int = _deck.pop_back()
	_deck.push_front( hand )
	return hand


static func load_random_template(controller:GLControllerGrass):
	var random_index:int = _card_shuffle_next()
	GLDebug.internal("Random template load index: %s" %random_index)
	load_template( controller, random_index )


static func load_template(controller:GLControllerGrass, template_index:int):
	match template_index:
		0:
			controller.mesh = AssetsManager.load_controller_resource("grass", "mesh_3d_single.res")
			controller.name = "GrassSingle3D"
		
		1:
			controller.mesh = AssetsManager.load_controller_resource("grass", "mesh_3d_foxtail.res")
			controller.name = "GrassFoxtail3D"
		
		2:
			controller.mesh = AssetsManager.load_controller_resource("grass", "mesh_textured_quad.tres")
			controller.texture_instance = AssetsManager.load_controller_resource("grass", "texture_quad.svg")
			controller.name = "GrassSingleTextured"
		
		3:
			controller.mesh = AssetsManager.load_controller_resource("grass", "mesh_textured_polyquad.res")
			controller.texture_instance = AssetsManager.load_controller_resource("grass", "texture_polyquad.svg")
			controller.name = "GrassPolyquadTextured"
	
