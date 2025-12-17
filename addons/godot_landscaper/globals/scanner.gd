## Utility for scanning resources
## Ultimately finds a color given a hit_info, image, and mesh data
extends Object
class_name GLScanner

const GROUP_CACHE_COLLIDERS:String = "landscaper_cache_colliders"
const GROUP_COLLIDERS:String = "landscaper_colliders"
static var CACHE_DEFAULT:Cache


# Otherwise found and calculated many times per frame
static var _cached_refs:Dictionary[CollisionObject3D, Cache]
class Cache:
	var new:bool
	var collider:CollisionObject3D
	var instance:MeshInstance3D
	var cached_collider:CollisionObject3D
	var mdts:Array[MeshDataTool]
	var sources:Array[Variant]
	var default_color:Color = Color.MAGENTA


## Takes collider and scans its mesh, materials, etc..
## Caches the scan results so they can be reused multiple times per frame
static func cache_scan(collider:CollisionObject3D, controller:GLControllerGrass, cache_color_sources:bool) -> Cache:
	if not CACHE_DEFAULT:
		CACHE_DEFAULT = Cache.new()
	
	if not collider or not controller:
		return CACHE_DEFAULT
	
	var settings:GLSettingsGrass = controller.settings
	
	if controller.paint_bottom_with_sencondary_color:
		CACHE_DEFAULT.default_color = controller.secondary_color if controller.paint_bottom_with_sencondary_color else settings.fallback_color
		return CACHE_DEFAULT
	
	# Run scans if hit_info happened in a new surface
	var cache:Cache = _cached_refs.get(collider)
	if cache:
		cache.new = false
		return cache
	
	cache = Cache.new()
	cache.default_color = controller.secondary_color if controller.paint_bottom_with_sencondary_color else settings.fallback_color
	cache.collider = collider
	cache.instance = GLScanner.scan_mesh( cache.collider, settings )
	
	if not cache.instance:
		GLDebug.error("Couldn't scan a valid mesh from settings. Auto-coloring and perfect surface placement cannot be made")
		return cache
	
	cache.cached_collider = GLScanner.create_cached_collider( cache.collider, settings.scan_layer_internal )
	cache.mdts = GLScanner.create_shapes( cache.collider, cache.cached_collider, cache.instance )
	
	if cache_color_sources:
		cache.sources = GLScanner.scan_color_sources( cache.instance, settings.paths_in_standar_materials, settings.paths_in_shader_materials )

	# The first detected collider is user-made, the following hits will always be cached_collider
	_cached_refs[cache.cached_collider] = cache
	GLDebug.internal("New scanned surface '%s'" %cache.instance.name)
	cache.new = true
	return cache


# Hard resets scanned references
static func clear_cache():
	var cached_colliders:Array[Node] = Landscaper.scene.get_tree().get_nodes_in_group( GROUP_CACHE_COLLIDERS )
	var colliders:Array[Node] = Landscaper.scene.get_tree().get_nodes_in_group( GROUP_COLLIDERS )
	for cached_collider in cached_colliders:
		if is_instance_valid(cached_collider): cached_collider.queue_free()
	for collider in colliders:
		if is_instance_valid(collider):
			collider.process_mode = Node.PROCESS_MODE_INHERIT
			collider.remove_from_group( GROUP_COLLIDERS )
		
	GLDebug.internal("Cache cleared of '%s' references" %colliders.size())
	_cached_refs.clear()


static func scan_mesh(collider:CollisionObject3D, settings:GLSettings) -> MeshInstance3D:
	if not collider:
		return null
	
	if settings.relative_path_from_physics_body.is_relative_path():
		var node:Node = collider.get_node_or_null( NodePath(settings.relative_path_from_physics_body) )
		if node is MeshInstance3D and node.mesh:
			return node
	
	if settings.parent_of_physics_body:
		var node:Node = collider.get_parent()
		if node is MeshInstance3D and node.mesh:
			return node
	return null


static func scan_color_sources(instance:MeshInstance3D, standar_material_paths:Array[String], shader_material_paths:Array[String]) -> Variant:
	var color_sources:Array[Variant]
	var material_count:int = instance.get_surface_override_material_count()
	color_sources.resize( material_count )
	
	for i in material_count:
		var material:Material = instance.get_active_material(i)
		
		if material is StandardMaterial3D:
			for path in standar_material_paths:
				var source:Variant = material.get(path)
				color_sources[i] = format_source( source )
				if color_sources[i]: break
		
		elif material is ShaderMaterial:
			for path in standar_material_paths:
				var source:Variant = material.get( "shader_parameters".path_join(path) )
				color_sources[i] = format_source( source )
				if color_sources[i]: break
	
	return color_sources


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


static func create_cached_collider(collider:CollisionObject3D, layer:int) -> CollisionObject3D:
	var cached_collider:CollisionObject3D = SceneManager.find_or_create_node( StaticBody3D, collider.get_parent(), "CachedBody", not GLDebug.debugging_internal() )
	cached_collider.collision_layer = layer
	cached_collider.collision_mask = 0
	cached_collider.process_mode = Node.PROCESS_MODE_INHERIT
	# Hard save them to hard clear them in case of errors
	cached_collider.add_to_group(GROUP_CACHE_COLLIDERS, true)
	collider.add_to_group(GROUP_COLLIDERS, true)
	# Clear original collider's collision layer so it doesn't get detected anymore. Resets on rest/clear_cache()
	collider.process_mode = Node.PROCESS_MODE_DISABLED
	return cached_collider


static func create_shapes(collider:CollisionObject3D, cached_collider:CollisionObject3D, instance:MeshInstance3D) -> Array[MeshDataTool]:
	var surfaces:int = instance.get_surface_override_material_count()
	var mdts:Array[MeshDataTool]
	mdts.resize( surfaces )
	
	for surface in surfaces:
		var material:Material = instance.get_active_material( surface )
		var arrays:Array = instance.mesh.surface_get_arrays( surface )
		var arary_mesh:ArrayMesh = ArrayMesh.new()
		arary_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, arrays )
		
		var shape:CollisionShape3D = SceneManager.find_or_create_node( CollisionShape3D, cached_collider, "CachedShape%s"%surface, not GLDebug.debugging_internal() )
		shape.shape = arary_mesh.create_trimesh_shape()
		shape.debug_color = Color(Landscaper.scene.brush.get_color(), 1.0)
		
		# I *think* MeshDataTool cannot store more than one surface, and MeshDataTool.get_vertex() is absolutely needed.
		# So just store on the first surface but inside a surface-indexed array
		var mdt:MeshDataTool = MeshDataTool.new()
		mdt.create_from_surface(arary_mesh, 0)
		mdts[surface] = mdt
	
	return mdts


## Takes hit_info from PhysicsDirectSpaceState3D.intersect_ray(), and cached data from cache_scan()
## to find the color of cache.sources (either a solid color or the texture's barycentric coordinates)
static func scan_color(hit_info:Dictionary, cache:Cache) -> Color:
	if not hit_info or not cache:
		return cache.default_color
	
	var face_index:int = hit_info.face_index
	var surface:int = hit_info.shape
	
	if surface >= cache.mdts.size():
		return cache.default_color
	
	var mdt:MeshDataTool = cache.mdts[surface]
	var source:Variant = cache.sources[surface]
	
	if source is Color:
		GLDebug.spam("Scanned color: [color=%s]#%s[/color] on surface: %s" %[source.to_html(), source.to_html(), surface])
		return source
	elif source is Image:
		pass
	else:
		GLDebug.error("Source '%s' is invalid" %source)
		return cache.default_color
	
	# Considers scale, rotation, and translation of hit surface
	var mouse_local_position:Vector3 = hit_info.collider.to_local( hit_info.position )
	
	# Triggers when the ray does not hit the correct mesh surface
	if face_index >= mdt.get_face_count():
		return cache.default_color
	
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
