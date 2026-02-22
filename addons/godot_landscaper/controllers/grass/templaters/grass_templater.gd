@static_unload
extends Resource
class_name GLTemplaterGrass

static var _shuffler:GLDeckShuffle


static func load_random_template(controller:GLController):
	if not _shuffler:
		_shuffler = GLDeckShuffle.from_args( 0, 1, 2, 3 )
	var random_index:int = _shuffler.next()
	load_template( controller, random_index )


static func load_template(controller:GLControllerGrass, template_index:int):
	var source:GLBuildDataGrass = controller.source
	match template_index:
		0:
			source.mesh = GLAssetsManager.load_controller_resource("grass", "mesh_3d_single.res")
			controller.name = "GrassSingle3D"
			GLDebug.state("Loaded a basic grass template. Set another mesh under 'GLController > Source > Resources > Mesh'")
		
		1:
			source.mesh = GLAssetsManager.load_controller_resource("grass", "mesh_3d_foxtail.res")
			controller.name = "GrassFoxtail3D"
			GLDebug.state("Loaded a basic grass template. Set another mesh under 'GLController > Source > Resources > Mesh'")
		
		2:
			source.mesh = GLAssetsManager.load_controller_resource("grass", "mesh_textured_quad.tres")
			controller.texture_texture = GLAssetsManager.load_controller_resource("grass", "texture_quad.svg")
			controller.name = "GrassSingleTextured"
			GLDebug.state("Loaded a textured grass template. To visualize it, select a texture layer and press 'Brushes > Texture Layers > Save layer Into Array'")
		
		3:
			source.mesh = GLAssetsManager.load_controller_resource("grass", "mesh_textured_polyquad.res")
			controller.texture_texture = GLAssetsManager.load_controller_resource("grass", "texture_polyquad.svg")
			controller.name = "GrassPolyquadTextured"
			GLDebug.state("Loaded a textured grass template. To visualize it, select a texture layer and press 'Brushes > Texture Layers > Save layer Into Array'")




	
