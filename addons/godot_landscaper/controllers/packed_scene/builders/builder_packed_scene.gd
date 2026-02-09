@tool
extends GLBuilder
class_name GLBuilderPackedScene

const META_CONTROLLER:String = "gl_controller_name"
const META_INDEX:String = "gl_index"

func build_from_source() -> bool:
	_build()
	return true


func build_from_processed() -> bool:
	return true


func _build():
	_controller = _controller as GLControllerPackedScene
	var holder:Node = _controller.holder
	var source:GLBuildDataPackedScene = _controller.source
	var scene:PackedScene = source.scene
	var transforms:Array[Transform3D] = source.transforms
	var root:Node = EditorInterface.get_edited_scene_root()
	
	# Instance from scene:PackedScene
	# They store safe metadata for later identification
	for dirty_transform_index in source.dirty_instances:
		var transform:Transform3D = transforms[dirty_transform_index]
		var instance:Node3D = scene.instantiate()
		holder.add_child( instance )
		instance.owner = root
		instance.global_transform = transform
		instance.set_meta( META_CONTROLLER, _controller.name )
		instance.set_meta( META_INDEX, dirty_transform_index)
	
	source.dirty_instances.clear()
	
	var dirty_erases:PackedInt32Array = source.dirty_erases
	if dirty_erases.is_empty():
		return
	
	# Destroy nodes with given metadata indices as identifications
	for instance in holder.get_children():
		if not instance.has_meta( META_CONTROLLER ) or not instance.has_meta( META_INDEX ):
			continue
		
		if instance.get_meta( META_CONTROLLER ) != _controller.name:
			continue
		
		var index:int = instance.get_meta( META_INDEX )
		if dirty_erases.has( index ):
			instance.free()
	
	dirty_erases.clear()

	# Instance metadata indices will no longer match the source transforms indices.
	# The user may may have changed the transforms as well.
	# Update both.
	transforms.clear()
	for i in holder.get_child_count():
		var instance:Node = holder.get_child( i )
		if instance.get_meta( META_CONTROLLER, "" ) == _controller.name:
			instance.set_meta( META_INDEX, i )
			transforms.append( instance.global_transform )
	











	
