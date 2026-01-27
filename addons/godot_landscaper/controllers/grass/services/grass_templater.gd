extends Resource
class_name GLGrassTemplater

# Deck for card shuffling
static var _deck:Array[int]


static func _card_shuffle_next() -> int:
	if not _deck:
		_deck = [3, 2, 1, 0]
	var hand:int = _deck.pop_back()
	_deck.push_front( hand )
	return hand


static func load_random_template(controller:GLControllerGrass):
	var random_index:int = _card_shuffle_next()
	load_template( controller, random_index )


static func load_template(controller:GLControllerGrass, template_index:int):
	var source:GLBuildDataGrass = controller.source
	match template_index:
		0:
			source.mesh = AssetsManager.load_controller_resource("grass", "mesh_3d_single.res")
			controller.name = "GrassSingle3D"
			GLDebug.state("Loaded a basic grass template. Set another mesh under 'GLController > Source > Resources > Mesh'")
		
		1:
			source.mesh = AssetsManager.load_controller_resource("grass", "mesh_3d_foxtail.res")
			controller.name = "GrassFoxtail3D"
			GLDebug.state("Loaded a basic grass template. Set another mesh under 'GLController > Source > Resources > Mesh'")
		
		2:
			source.mesh = AssetsManager.load_controller_resource("grass", "mesh_textured_quad.tres")
			controller.texture_texture = AssetsManager.load_controller_resource("grass", "texture_quad.svg")
			controller.name = "GrassSingleTextured"
			GLDebug.state("Loaded a textured grass template. To visualize it, select a texture layer and press 'Brushes > Texture Layers > Save layer Into Array'")
		
		3:
			source.mesh = AssetsManager.load_controller_resource("grass", "mesh_textured_polyquad.res")
			controller.texture_texture = AssetsManager.load_controller_resource("grass", "texture_polyquad.svg")
			controller.name = "GrassPolyquadTextured"
			GLDebug.state("Loaded a textured grass template. To visualize it, select a texture layer and press 'Brushes > Texture Layers > Save layer Into Array'")
