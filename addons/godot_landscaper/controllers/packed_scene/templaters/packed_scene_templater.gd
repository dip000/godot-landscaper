@static_unload
extends Resource
class_name GLTemplaterPackedScene

static var _shuffler:GLDeckShuffle


static func load_random_template(controller:GLController):
	if not _shuffler:
		_shuffler = GLDeckShuffle.from_args( 0, 1 )
	var random_index:int = _shuffler.next()
	load_template( controller, random_index )


static func load_template(controller:GLController, template_index:int):
	var source:GLBuildDataPackedScene = controller.source
	match template_index:
		0:
			controller.source.scene = GLAssetsManager.load_controller_resource( "packed_scene", "tree.glb" )
			controller.name = "PackedSceneTree"
			GLDebug.state("Template scene 'Tree' was loaded. Use your own scenes under 'GLController > Source > Scene'")
		1:
			controller.source.scene = GLAssetsManager.load_controller_resource( "packed_scene", "stone.glb" )
			controller.name = "PackedSceneStone"
			GLDebug.state("Template scene 'Stone' was loaded. Use your own scenes under 'GLController > Source > Scene'")
		














	
