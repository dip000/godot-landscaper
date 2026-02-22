@tool
extends GLBuilder
class_name GLBuilderPackedScene

const META_CONTROLLER:String = "gl_controller_name"
const META_INDEX:String = "gl_index"


func quick_start(from_data:GLBuildData) -> bool:
	return false

func quick_build(from_data:GLBuildData) -> bool:
	_controller = _controller as GLControllerPackedScene
	var source:GLBuildDataPackedScene = _controller.source
	_dirty_instance( source, _controller.holder )
	_dirty_erase( source, _controller.holder )
	_update_data_from_scene( source, _controller.holder )
	return true

func quick_end(from_data:GLBuildData) -> bool:
	return false


func build(from_data:GLBuildData) -> bool:
	_rebuild( from_data, _controller.holder )
	return true


func build_from_processed() -> bool:
	_controller = _controller as GLControllerPackedScene
	var processed:GLBuildDataPackedScene = _controller.processed
	_rebuild( processed, _controller.holder )
	return true



func _rebuild(data:GLBuildDataPackedScene, holder:Node):
	var root:Node = EditorInterface.get_edited_scene_root()
	var scene:PackedScene = data.scene
	var transforms:Array[Transform3D] = data.transforms
	
	# Destroy all children
	for instance in holder.get_children():
		var meta_controller:String = instance.get_meta( META_CONTROLLER, "" )
		var meta_index:int = instance.get_meta( META_INDEX, -1 )
		if meta_controller == _controller.name and meta_index >= 0:
			instance.free()
	
	# Re-instance
	# Instance stores safe metadata for later identification
	for i in transforms.size():
		var instance:Node3D = scene.instantiate()
		var original_name:String = instance.name
		holder.add_child( instance )
		instance.name = original_name
		instance.owner = root
		instance.global_transform = transforms[i]
		instance.set_meta( META_CONTROLLER, _controller.name )
		instance.set_meta( META_INDEX, i)
	


func _dirty_instance(data:GLBuildDataPackedScene, holder:Node):
	if not data.dirty_instances:
		return
	
	var root:Node = EditorInterface.get_edited_scene_root()
	var scene:PackedScene = data.scene
	var transforms:Array[Transform3D] = data.transforms
	var dirty_instances:PackedInt32Array = data.dirty_instances
	
	# Instance from scene:PackedScene
	# They store safe metadata for later identification
	for dirty_transform_index in dirty_instances:
		var transform:Transform3D = transforms[dirty_transform_index]
		var instance:Node3D = scene.instantiate()
		var original_name:String = instance.name
		holder.add_child( instance )
		instance.name = original_name
		instance.owner = root
		instance.global_transform = transform
		instance.set_meta( META_CONTROLLER, _controller.name )
		instance.set_meta( META_INDEX, dirty_transform_index)
	
	dirty_instances.clear()


# Destroy nodes with given metadata indices as identifications
func _dirty_erase(data:GLBuildDataPackedScene, holder:Node):
	var dirty_erases:PackedInt32Array = data.dirty_erases
	if dirty_erases.is_empty():
		return
	
	for instance in holder.get_children():
		var meta_controller:String = instance.get_meta( META_CONTROLLER, "" )
		var meta_index:int = instance.get_meta( META_INDEX, -1 )
		if meta_controller != _controller.name or meta_index < 0:
			continue
		
		if dirty_erases.has( meta_index ):
			instance.free()
	
	dirty_erases.clear()


# Instance metadata indices will no longer match the source transforms indices.
# The user may alse have changed the transforms as well.
# Update both.
func _update_data_from_scene(data:GLBuildDataPackedScene, holder:Node):
	var transforms:Array[Transform3D] = data.transforms
	transforms.clear()
	for i in holder.get_child_count():
		var instance:Node = holder.get_child( i )
		var meta_controller:String = instance.get_meta( META_CONTROLLER, "" )
		if meta_controller == _controller.name:
			instance.set_meta( META_INDEX, i )
			transforms.append( instance.global_transform )
	

func _update_scene_from_data(data:GLBuildDataPackedScene, holder:Node):
	var transforms:Array[Transform3D] = data.transforms
	for i in holder.get_child_count():
		var instance:Node = holder.get_child( i )
		if instance.get_meta( META_CONTROLLER, "" ) == _controller.name:
			var index:int = instance.get_meta( META_INDEX )
			if index <= transforms.size():
				transforms.resize( index+1 )
			instance.global_transform = transforms[index]
	












	
