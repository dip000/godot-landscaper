@tool
extends Action
class_name ActionSceneSpawn

var holder:Node3D


func start(instance:Instancer):
	holder = SceneManager.find_or_create_node( Node3D, instance.root_node, instance.resource_name )
	holder.global_position = instance.surface_position

func primary(instance:Instancer):
	_add_radial( instance )

func secondary(instance:Instancer):
	_get_remove_radial( instance )

func end(instance:Instancer):
	for child in holder.get_children():
		instance.transforms.append( child.transform )

func redo(instance:Instancer):
	for child in holder.get_children():
		child.queue_free()
	
	for transform in instance.transforms:
		var scene:Node3D = instance.scene.instantiate()
		holder.add_child( scene )
		scene.owner = holder.owner
		scene.transform = transform

func _add_radial(instance:Instancer):
	for i in range(instance.add_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_surface1:Vector3 = _get_surface_point(instance.radius) + instance.cursor_position
		var sphere_surface2:Vector3 = _get_surface_point(instance.radius) + instance.cursor_position
		
		# Add transforms for every surface found
		var result:Dictionary = Landscaper.scene.raycaster.point_to_point(sphere_surface1, sphere_surface2)
		if result:
			var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
			var transf := Transform3D( basis, result.position - instance.surface_position )
			transf = transf.rotated_local( Vector3.FORWARD, randf()*PI )
			transf = transf.scaled_local( instance.size_base + randf_range(-1,1)*instance.size_randomize)
			
			var scene:Node3D = instance.scene.instantiate()
			holder.add_child( scene )
			scene.owner = holder.owner
			scene.transform = transf


func _get_remove_radial(instance:Instancer):
	for child in holder.get_children():
		var instance_pos:Vector3 = child.global_position
		var dist:float = instance_pos.distance_to( instance.cursor_position )
		if dist < instance.radius:
			child.queue_free()
