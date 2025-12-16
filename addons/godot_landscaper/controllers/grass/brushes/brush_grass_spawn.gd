@tool
extends GLBrush
class_name GLBrushGrassSpawn


func start(hit_info:Dictionary, stroke_data:GLBuildData, controller:GLController) -> void:
	GLScanner.clear_cache()

func primary(hit_info:Dictionary, stroke_data:GLBuildData, controller:GLController):
	_add_radial( hit_info, stroke_data, controller )

func secondary(hit_info:Dictionary, stroke_data:GLBuildData, controller:GLController):
	_get_remove_radial( hit_info, stroke_data, controller )

func end():
	GLScanner.clear_cache()


# Gets every MultiMesh transform except the ones inside the brush
func _get_remove_radial(hit_info:Dictionary, stroke_data:GLBuildDataGrass, controller:GLControllerGrass):
	var settings:GLSettingsGrass = controller.settings
	var mmi:MultiMeshInstance3D = controller.mmi
	var mm:MultiMesh = mmi.multimesh
	
	var brush_radius_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	stroke_data.transforms.clear()
	stroke_data.bottom_colors.clear()
	stroke_data.top_colors.clear()
	
	for i in mm.instance_count:
		var instance_transform:Transform3D = mm.get_instance_transform(i)
		var instance_world_pos:Vector3 = mmi.to_global( instance_transform.origin )
		var dist_sqr:float = instance_world_pos.distance_squared_to( mouse_world_pos )
		
		if dist_sqr > brush_radius_sqr or settings.erase_ratio < randf():
			stroke_data.transforms.append( instance_transform )
			stroke_data.bottom_colors.append(  mm.get_instance_color(i) )
			stroke_data.top_colors.append(  mm.get_instance_custom_data(i) )


func _add_radial(hit_info:Dictionary, stroke_data:GLBuildDataGrass, controller:GLControllerGrass):
	var settings:GLSettingsGrass = controller.settings
	var mmi:MultiMeshInstance3D = controller.mmi
	var mm:MultiMesh = mmi.multimesh
	
	var brush_radius:float = Landscaper.scene.brush.get_scale_ratio()*0.5
	var mouse_world_pos:Vector3 = hit_info.position
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	
	for i in range(settings.spawn_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_global_point1:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		var sphere_global_point2:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		
		var result:Dictionary = raycaster.point_to_point(sphere_global_point1, sphere_global_point2)
		if not result:
			continue
		
		# Await a frame if the cache was newly created so it can be re-scanned
		var cache:GLScanner.Cache = GLScanner.cache_scan( result.collider, controller, true )
		if cache.new:
			await Engine.get_main_loop().process_frame
			result = raycaster.point_to_point(sphere_global_point1, sphere_global_point2)
			if not result:
				continue
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		# This will actually make the grass "look" up at the sky instead of standing at 90°
		var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
		
		# Compose rotation using quaternion magic
		basis *= Basis(
			# PI*0.5 on X axis compenzates for looking at the sky as mentioned before
			Quaternion(Vector3.RIGHT, settings.rotation_base.x - PI * 0.5) *
			Quaternion(Vector3.UP, settings.rotation_base.y) *
			Quaternion(Vector3.FORWARD, settings.rotation_base.z) *
			Quaternion(Vector3.RIGHT, randf()*settings.rotation_randomize.x) *
			Quaternion(Vector3.UP, randf()*settings.rotation_randomize.y) *
			Quaternion(Vector3.FORWARD, randf()*settings.rotation_randomize.z)
		)
		
		# to_local() takes rotation and scale in consideration
		var local_pos:Vector3 = mmi.to_local( result.position )
		
		# Save base and random values
		var local_transf := Transform3D( basis, local_pos )
		var size_offset:Vector3 = settings.size_randomize * _randv(0, 1)
		
		local_transf = local_transf.scaled_local( settings.size_base + size_offset )
		stroke_data.transforms.append( local_transf )
		
		# Save colors. Use cached colors for performance
		var color:Color = GLScanner.scan_color( result, cache )
		stroke_data.bottom_colors.append( color )
		stroke_data.top_colors.append( settings.primary_color )


func _get_surface_point(radius:float) -> Vector3:
	var point:Vector3 = _randv(-1, +1).normalized()
	return point * radius

func _randv(min:float, max:float) -> Vector3:
	return Vector3( randf_range(min,max), randf_range(min,max), randf_range(min,max) )
