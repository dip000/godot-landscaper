@tool
extends GLEffect
class_name GLSceneChunkify

## The size squared to split the terrain
@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)

## The chunks holder.
@export var root_node:NodePath = "."

## Creates all [Node3D] in path if they don't exists.
## This let's you organize the scene as you like.[br]
## - [code]{x}[/code] Will be replaced for the X coordinate of the world chunk.[br]
## - [code]{y}[/code] Will be replaced for the Y coordinate of the world chunk.
@export var root_to_instance:String = "Chunk_{x}_{y}/Scenes"

@export_group("Visibility Range LoD")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "Visibility Range LoD", PROPERTY_USAGE_EDITOR) var enable_lod:bool = false
@export var end_margin:float = 2.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerPackedScene:
		GLDebug.error("Scene Chunkify Failed: This effect is only valid for GLControllerPackedScene controller types")
		return false
	
	if not _clear( controller ):
		return false
	
	controller = controller as GLControllerPackedScene
	var root_parent:Node = controller.get_node_or_null( root_node )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	var processed:GLBuildDataPackedScene = controller.processed
	var transforms:Array[Transform3D] = processed.transforms
	var scene:PackedScene = processed.scene
	var holder:Node = controller.holder
	var root:Node = EditorInterface.get_edited_scene_root()
	
	for i in transforms.size():
		var transform:Transform3D = transforms[i]
		var instance:Node = scene.instantiate()
		var original_name:String = instance.name
		var h_pos:Vector2 = Vector2( transform.origin.x, transform.origin.z )
		var chunk:Vector2i = ( h_pos/float(chunk_size) ).floor()
		
		# Find or create all folder nodes. The MMI is not part of root_to_instance
		var last_parent:Node = root_parent
		var root_to_instance_formated:String = root_to_instance.format( {x=chunk.x, y=chunk.y} )
		for node_name in root_to_instance_formated.split( "/" ):
			last_parent = GLSceneManager.find_or_create_node( Node3D, last_parent, node_name )
		
		last_parent.add_child( instance )
		instance.name = original_name
		instance.global_transform = transform
		instance.owner = root
		instance.set_meta( GLBuilderPackedScene.META_CONTROLLER, controller.name )
		
		if enable_lod:
			var lod_ables:Array[Node] = instance.find_children( "*", "GeometryInstance3D", true, true )
			last_parent.set_editable_instance( instance, true )
			instance.set_display_folded( true )
			for lod_able in lod_ables:
				lod_able = lod_able as GeometryInstance3D
				lod_able.visibility_range_end = custom_lod_meters
				lod_able.visibility_range_end_margin = end_margin
		
		last_parent.set_display_folded( true )
		await _100_index(i)
	
	for instance in holder.get_children():
		var meta_controller:String = instance.get_meta(GLBuilderPackedScene.META_CONTROLLER, "")
		var meta_index:int = instance.get_meta(GLBuilderPackedScene.META_INDEX, -1)
		if meta_controller == controller.name and meta_index >= 0:
			instance.free()
	
	transforms.clear()
	GLDebug.state("Scenes chunkifyied")
	return true


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerPackedScene:
		GLDebug.error("Scene Chunkify Failed: This effect is only valid for GLControllerPackedScene controller types")
		return false

	controller = controller as GLControllerPackedScene
	var root_parent:Node = controller.get_node_or_null( root_node )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	delete_children( root_parent, controller.holder )
	return true


func delete_children(parent:Node, source_holder:Node):
	if parent == source_holder:
		return
	for node in parent.get_children():
		if node.get_meta( GLBuilderPackedScene.META_CONTROLLER, "" ) == source_holder.name:
			node.queue_free()
		else:
			delete_children( node, source_holder )







	
