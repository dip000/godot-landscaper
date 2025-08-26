## Utility for scanning resources
## Ultimately finds a color given a hit_info, image, and mesh
extends Object
class_name Scanner

# Otherwise found and calculated many times per frame
static var _cached_refs:Dictionary[CollisionObject3D, Cache]
class Cache:
	var instance:MeshInstance3D
	var color_source:Variant
	var img:Image
	var collider:CollisionObject3D
	var surface_collider:CollisionObject3D
	var material:Material
	var mdt:MeshDataTool
	func _init(hit_info:Dictionary, tool:QuadGrassTool):
		collider = hit_info.collider
		instance = Scanner.scan_mesh( collider, tool.parent_of_physics_body, tool.children_of_physics_body, tool.relative_path_from_physics_body )
		material = Scanner.scan_material( instance, tool.active_material_indexes )
		color_source = Scanner.scan_color_source( material, tool.paths_in_standar_materials, tool.paths_in_shader_materials )
		mdt = Scanner.create_mesh_data( instance.mesh )
		if color_source is Texture2D:
			img = Scanner.format_image( color_source )



static func get_cached_color(hit_info:Dictionary, tool:QuadGrassTool) -> Color:
	if not tool:
		GLDebug.error("Tool was not assigned to Scanner")
		return Color.MAGENTA
	
	if not hit_info:
		return tool.fallback_color
	
	if tool.paint_with_sencondary_color:
		return tool.secondary_color
	
	# Run scans if hit_info happened in a new surface
	var cache:Cache = _cached_refs.get(hit_info.collider)
	if not cache:
		cache = Cache.new( hit_info, tool )
		_cached_refs[hit_info.collider] = cache
		GLDebug.internal("New scanned surface '%s'" %cache.instance.name)
	
	# Scan pixel if source was a texture
	if cache.color_source is Texture2D:
		return Scanner.scan_pixel( hit_info, tool.fallback_color, cache )
	
	# Return scanned color if source was Color
	elif cache.color_source is Color:
		return cache.color_source
	
	return tool.fallback_color


# Clears stored references in case they were updated from the user's inspector
static func clear_cache():
	#for cache in _cached_refs.values():
		#if is_instance_valid( cache.surface_collider ):
			#cache.surface_collider.queue_free()
	_cached_refs.clear()
	#SceneRaycaster.set_collision_mask( Landscaper.tool.scan_layer )


static func create_shapes(hit_info:Dictionary, tool:QuadGrassTool):
	var cache:Cache = Cache.new( hit_info, tool )
	var instance:MeshInstance3D = cache.instance
	cache.surface_collider = SceneManager.find_or_create_node( StaticBody3D, cache.collider.get_parent(), "GhostBody" )
	cache.surface_collider.collision_layer = 1<<31
	
	for surface in instance.get_surface_override_material_count():
		var material:Material = instance.get_active_material( surface )
		var arrays:Array = instance.mesh.surface_get_arrays( surface )
		var arary_mesh:ArrayMesh = ArrayMesh.new()
		arary_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, arrays )
		
		var shape:CollisionShape3D = SceneManager.find_or_create_node( CollisionShape3D, cache.surface_collider, "GhostShape%s"%surface )
		shape.shape = arary_mesh.create_trimesh_shape()
		_cached_refs[cache.collider] = cache
	
	SceneRaycaster.set_collision_mask(1<<31)


static func scan_mesh_from_hit_info(scan_parent:bool, scan_children:bool, ref_path:String) -> MeshInstance3D:
	if SceneRaycaster.hit_info:
		var collider:CollisionObject3D = SceneRaycaster.hit_info.collider
		return scan_mesh( collider, scan_parent, scan_children, ref_path )
	return null


static func scan_mesh(collider:CollisionObject3D, scan_parent:bool, scan_children:bool, ref_path:String) -> MeshInstance3D:
	if not collider:
		return null
	
	if scan_parent:
		var parent:Node = collider.get_parent()
		return parent if parent is MeshInstance3D else null
	
	if scan_children:
		for node in collider.get_children():
			if node is MeshInstance3D:
				return node
	
	if ref_path.is_relative_path():
		var node:Node = collider.get_node_or_null( ref_path )
		return node if node is MeshInstance3D else null
	
	return null


static func scan_material(instance:MeshInstance3D, active_material_indexes:Array[int]) -> Material:
	if not instance:
		return null
	
	for index in active_material_indexes:
		if index >= instance.get_surface_override_material_count():
			break
		var material:Material = instance.get_active_material(index)
		if material:
			return material
	return null


static func scan_color_source(material:Material, standar_material_paths:Array[String], shader_material_paths:Array[String]) -> Variant:
	if not material:
		return null
	
	if material is StandardMaterial3D:
		for path in standar_material_paths:
			if path in material:
				return material[path]
	
	if material is ShaderMaterial:
		for path in standar_material_paths:
			if "shader_parameters/"+path in material:
				return material.get_shader_parameter(path)
	
	return null



static func format_image(texture:Texture2D) -> Image:
	if not texture:
		return null
	var img:Image = texture.get_image()
	if not img:
		return null
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	return img


static func scan_pixel(hit_info:Dictionary, default:Color, cache:Cache) -> Color:
	var mouse_local_position:Vector3 = hit_info.collider.to_local( hit_info.position )
	var face_index:int = hit_info.face_index
	var mdt:MeshDataTool = cache.mdt
	var img:Image = cache.img
	
	# Triggers when the ray does not hit the correct mesh surface
	if face_index >= mdt.get_face_count():
		return default
	
	# Get vertex coordinates of raycasted trangled-face using MeshDataTool magic
	var xy:Array[Vector3] #World-space
	var uv:Array[Vector2] #Texture-space
	for i in range(3):
		var idx:int = mdt.get_face_vertex( face_index, i )
		xy.append( mdt.get_vertex(idx) )
		uv.append( mdt.get_vertex_uv(idx) )
	
	# Find the cursor point coordinates of the texture-space using the triangle points
	var relative:Vector3 = Geometry3D.get_triangle_barycentric_coords(mouse_local_position, xy[0], xy[1], xy[2])
	var cursor_texture:Vector2 = relative.x*uv[0] + relative.y*uv[1] + relative.z*uv[2]
	
	var size:Vector2 = img.get_size()-Vector2i.ONE
	var pixel_position:Vector2i = cursor_texture*size
	pixel_position.x = clampi(pixel_position.x, 0, size.x)
	pixel_position.y = clampi(pixel_position.y, 0, size.y)
	
	# Find color from that coordinate
	var px:Color = img.get_pixelv( pixel_position )
	GLDebug.spam("Scanned color: [color=%s]#%s[/color]" %[px.to_html(), px.to_html()])
	return px


static func create_mesh_data(mesh:Mesh) -> MeshDataTool:
	var mesh_arrays:Array = mesh.surface_get_arrays(0)
	var arr_mesh := ArrayMesh.new()
	var mdt:MeshDataTool = MeshDataTool.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	mdt.create_from_surface(arr_mesh, 0)
	return mdt
