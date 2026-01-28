## ImageTexture To CompressedTexture2D with formating options.
## 
## By default, the landscaper will use a ImageTexture to process images,
## but only Godot's native importer has the ability to compress textures.

@tool
extends GLEffect
class_name GLTerrainHeightmapCollider

@export_node_path("CollisionShape3D") var collider_path:NodePath


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Heightmap Collider Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	if not controller.has_node( collider_path ):
		GLDebug.error("Terrain Heightmap Collider Failed: 'collider_path=%s' was not found" %collider_path)
		return false
	
	controller = controller as GLControllerTerrain
	var terrain:MeshInstance3D = controller.terrain
	var processed:GLBuildDataTerrain = controller.processed
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = processed.vertices_map
	var bounds:Rect2i = GLBrushTerrainBuider.get_bounding_box_from_mesh( terrain )
	var heightmap:HeightMapShape3D = HeightMapShape3D.new()
	
	heightmap.map_width = bounds.size.x+1
	heightmap.map_depth = bounds.size.y+1
	
	var map_data:PackedFloat32Array
	map_data.resize( heightmap.map_width * heightmap.map_depth )
	for global in Rect2iter.new(bounds):
		var height:float = GLBrushTerrainBuider.get_corner_height( GLBrushTerrainBuider.TOP_LEFT, vertices_map, global )
		var local:Vector2i = global - bounds.position
		var index:int = local.x + local.y * heightmap.map_width
		GLDebug.spam("Global: %s, Local: %s, Index: %s, Height: %s" %[global, local, index, height])
		map_data[index] = height
	
	var collider:CollisionShape3D = controller.get_node( collider_path )
	var body:Node = collider.get_parent()
	heightmap.set_map_data( map_data )
	body.process_mode = Node.PROCESS_MODE_DISABLED
	collider.shape = heightmap
	body.process_mode = Node.PROCESS_MODE_INHERIT
	collider.global_position = terrain.get_aabb().get_center()
	collider.position.y = 0
	
	GLDebug.state("Effect Terrain Heightmap Applied to Terrain '%s'" %terrain.name)
	return true
	

func _clear(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Texture Formater Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	return true
	
	
