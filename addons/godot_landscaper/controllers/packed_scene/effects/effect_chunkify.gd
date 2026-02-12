@tool
extends GLEffect
class_name GLSceneChunkify

## The size squared to split the terrain
@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)

## The chunks holder.
@export var root_parent_path:NodePath = "."

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
	var root_parent:Node = controller.get_node_or_null( root_parent_path )
	
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
		
		var chunk_holder:Node = GLSceneManager.find_or_create_node( Node3D, root_parent, _format_chunk(chunk) )
		var type_holder:Node = GLSceneManager.find_or_create_node( Node3D, chunk_holder, "Instances" )
		type_holder.add_child( instance )
		instance.name = original_name
		instance.global_transform = transform
		instance.owner = root
		instance.set_meta( GLBuilderPackedScene.META_CONTROLLER, controller.name )
		
		if enable_lod:
			var lod_ables:Array[Node] = instance.find_children( "*", "GeometryInstance3D", true, true )
			type_holder.set_editable_instance( instance, true )
			instance.set_display_folded( true )
			for lod_able in lod_ables:
				lod_able = lod_able as GeometryInstance3D
				lod_able.visibility_range_end = custom_lod_meters
				lod_able.visibility_range_end_margin = end_margin
		
		type_holder.set_display_folded( true )
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
	var root_parent:Node = controller.get_node_or_null( root_parent_path )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	for chunk in root_parent.get_children():
		var type_holder:Node = chunk.get_node_or_null("Instances")
		if not type_holder:
			continue
		
		for instance in type_holder.get_children():
			var meta_controller:String = instance.get_meta(GLBuilderPackedScene.META_CONTROLLER, "")
			if meta_controller == controller.name:
				instance.free()
		
		# Clean up empty Instances "folder" (all controllers store in the same folder)
		if type_holder.get_child_count() <= 0:
			type_holder.free()
	
	for node in root_parent.get_children():
		var is_chunk_parent:bool = node.name.begins_with( "Chunk" )
		var is_empty:bool = (node.get_child_count() <= 0)
		if is_chunk_parent and is_empty:
			node.queue_free()
	
	return true






	
