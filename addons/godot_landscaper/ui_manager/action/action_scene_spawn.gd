@tool
extends Action
class_name ActionSceneSpawn


func start(stroke:Stroke):
	stroke.parent_node = SceneManager.find_or_create_node( Node3D, stroke.root_node, stroke.instance.name )

func primary(stroke:Stroke):
	_add_radial( stroke )

func secondary(stroke:Stroke):
	_get_remove_radial( stroke )

func end():
	pass


func _add_radial(stroke:Stroke):
	for i in range(stroke.add_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_surface1:Vector3 = _get_surface_point(stroke.radius) + stroke.cursor_position
		var sphere_surface2:Vector3 = _get_surface_point(stroke.radius) + stroke.cursor_position
		
		# Add transforms for every surface found
		var result:Dictionary = Landscaper.scene.raycaster.point_to_point(sphere_surface1, sphere_surface2)
		if result:
			var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
			var transf := Transform3D( basis, result.position - stroke.surface_position )
			transf = transf.rotated_local( Vector3.FORWARD, randf()*PI )
			transf = transf.scaled_local( stroke.instance.size_base + randf_range(-1,1)*stroke.instance.size_randomize)
			
			var scene:Node3D = stroke.instance.packed_scene.instantiate()
			stroke.parent_node.add_child( scene )
			scene.owner = stroke.parent_node.owner
			scene.transform = transf


func _get_remove_radial(stroke:Stroke):
	var scene:Node3D = stroke.instance.packed_scene.instantiate()
	
	for child in stroke.parent_node.get_children():
		var instance_pos:Vector3 = child.global_position
		var dist:float = instance_pos.distance_to( stroke.cursor_position )
		if dist < stroke.radius:
			child.queue_free()
