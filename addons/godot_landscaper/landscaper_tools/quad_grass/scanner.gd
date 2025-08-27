## Utility for scanning resources
## Ultimately finds a color given a hit_info, image, and mesh
extends Object
class_name Scanner

# Otherwise found and calculated many times per frame
static var _cached_refs:Dictionary[CollisionObject3D, Cache]
class Cache:
	var collider:CollisionObject3D
	var instance:MeshInstance3D
	var ghost_collider:CollisionObject3D
	var mdts:Array[MeshDataTool]
	var sources:Array[Variant]


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
		cache = Cache.new()
		cache.collider = hit_info.collider
		cache.instance = Scanner.scan_mesh( cache.collider, tool.parent_of_physics_body, tool.children_of_physics_body, tool.relative_path_from_physics_body )
		var materials:Array[Material] = Scanner.scan_materials( cache.instance )
		cache.sources = Scanner.scan_color_sources( materials, tool.paths_in_standar_materials, tool.paths_in_shader_materials )
		cache.ghost_collider = Scanner.create_ghost_collider( cache.collider, tool.scan_layer_internal )
		cache.mdts = Scanner.create_shapes( hit_info, tool, cache.collider, cache.ghost_collider, cache.instance )
		_cached_refs[cache.ghost_collider] = cache
		GLDebug.internal("New scanned surface '%s'" %cache.instance.name)
	
	# Scan texture's pixel or solid color
	return Scanner.scan_color( hit_info, cache, tool.fallback_color )


static func cache_colliders(hit_info:Dictionary, tool:QuadGrassTool) -> bool:
	if not tool:
		GLDebug.error("Tool was not assigned to Scanner")
		return false
	
	if not hit_info:
		return false
	
	if tool.paint_with_sencondary_color:
		return false
	
	var cache:Cache = _cached_refs.get(hit_info.collider)
	if not cache:
		cache = Cache.new()
		cache.collider = hit_info.collider
		cache.instance = Scanner.scan_mesh( cache.collider, tool.parent_of_physics_body, tool.children_of_physics_body, tool.relative_path_from_physics_body )
		cache.ghost_collider = Scanner.create_ghost_collider( cache.collider, tool.scan_layer_internal )
		cache.mdts = Scanner.create_shapes( hit_info, tool, cache.collider, cache.ghost_collider, cache.instance )
		_cached_refs[cache.ghost_collider] = cache
		GLDebug.internal("New scanned surface '%s'" %cache.instance.name)
		return true
	return false

# Clears stored references in case they were updated from the user's inspector
static func clear_cache():
	for cache in _cached_refs.values():
		if is_instance_valid(cache.collider):
			cache.collider.process_mode = Node.PROCESS_MODE_INHERIT
		if is_instance_valid(cache.ghost_collider):
			cache.ghost_collider.queue_free()
	print("Scanner.clear_cache")
	GLDebug.internal("Cache cleared of '%s' references" %_cached_refs.size())
	_cached_refs.clear()


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


static func scan_materials(instance:MeshInstance3D) -> Array[Material]:
	var materials:Array[Material]
	
	if not instance:
		return materials
	
	for index in instance.get_surface_override_material_count():
		var material:Material = instance.get_active_material(index)
		materials.append( material )
	return materials


static func scan_color_sources(materials:Array[Material], standar_material_paths:Array[String], shader_material_paths:Array[String]) -> Variant:
	var color_sources:Array[Variant]
	color_sources.resize(materials.size())
	
	for i in materials.size():
		var material:Material = materials[i]
		if material is StandardMaterial3D:
			for path in standar_material_paths:
				var source:Variant = material.get(path)
				color_sources[i] = format_source( source )
				if color_sources[i]:
					break
		
		elif material is ShaderMaterial:
			for path in standar_material_paths:
				var source:Variant = material.get("shader_parameters/"+path)
				color_sources[i] = format_source( source )
				if color_sources[i]:
					break
	
	return color_sources


static func create_ghost_collider(collider:CollisionObject3D, layer:int) -> CollisionObject3D:
	var ghost_collider:CollisionObject3D = SceneManager.find_or_create_node( StaticBody3D, collider.get_parent(), "GhostBody" )
	ghost_collider.collision_layer = layer
	ghost_collider.collision_mask = 0
	# Clear original collider's collision layer so it doesn't get detected anymore. Resets on clear_cache()
	collider.process_mode = Node.PROCESS_MODE_DISABLED
	return ghost_collider


static func create_shapes(hit_info:Dictionary, tool:QuadGrassTool, collider:CollisionObject3D, ghost_collider:CollisionObject3D, instance:MeshInstance3D) -> Array[MeshDataTool]:
	var surfaces:int = instance.get_surface_override_material_count()
	var mdts:Array[MeshDataTool]
	mdts.resize( surfaces )
	
	for surface in surfaces:
		var material:Material = instance.get_active_material( surface )
		var arrays:Array = instance.mesh.surface_get_arrays( surface )
		var arary_mesh:ArrayMesh = ArrayMesh.new()
		arary_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, arrays )
		
		var shape:CollisionShape3D = SceneManager.find_or_create_node( CollisionShape3D, ghost_collider, "GhostShape%s"%surface )
		shape.shape = arary_mesh.create_trimesh_shape()
		
		# I *think* MeshDataTool cannot store more than one surface, and MeshDataTool.get_vertex() is absolutely needed.
		# So just store the first surface but inside a surface-indexed array
		var mdt:MeshDataTool = MeshDataTool.new()
		mdt.create_from_surface(arary_mesh, 0)
		mdts[surface] = mdt
	
	return mdts


static func format_source(source:Variant) -> Variant:
	if not source:
		return null
	
	if source is Color:
		return source
	
	if not source is Texture2D:
		return null
	
	var img:Image = source.get_image()
	
	if not img:
		return null
	
	if img.is_compressed():
		img.decompress()
	
	if img.has_mipmaps():
		img.clear_mipmaps()
	
	return img


static func scan_color(hit_info:Dictionary, cache:Cache, default:Color,) -> Color:
	var face_index:int = hit_info.face_index
	var surface:int = hit_info.shape
	
	var mdt:MeshDataTool = cache.mdts[surface]
	var source:Variant = cache.sources[surface]
	
	if source is Color:
		return source
	elif source is Image:
		pass
	else:
		return default
	
	# Considers scale, rotation, and translation of hit surface
	var mouse_local_position:Vector3 = hit_info.collider.to_local( hit_info.position )
	
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
	
	var size:Vector2 = source.get_size()-Vector2i.ONE
	var pixel_position:Vector2i = cursor_texture*size
	pixel_position.x = clampi(pixel_position.x, 0, size.x)
	pixel_position.y = clampi(pixel_position.y, 0, size.y)
	
	# Find color from that coordinate
	var px:Color = source.get_pixelv( pixel_position )
	GLDebug.spam("Scanned color: [color=%s]#%s[/color] on surface: %s" %[px.to_html(), px.to_html(), surface])
	return px
