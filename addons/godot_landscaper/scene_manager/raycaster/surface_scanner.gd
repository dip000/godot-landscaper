## Utility for scanning scene resources.
##
## Raycast to a surface and finds its mesh instance, mesh, material and color source.
## Caches all results so it doesn't have to rescan every time.

extends RefCounted
class_name GLSurfaceScanner

const GROUP_CACHE_COLLIDERS:String = "landscaper_cache_colliders"
const GROUP_COLLIDERS:String = "landscaper_colliders"

var _cached_refs:Dictionary[CollisionObject3D, GLScanData]
var _controller:GLController


func set_configs_from_controller(controller:GLControllerGrass) -> GLSurfaceScanner:
	_controller = controller
	return self


## Raycasts to the given world positions and scans for mesh, materials, etc..
## Caches the cache_scan_all results so they can be reused multiple times per frame
func cache_scan_all(from:Vector3, to:Vector3) -> GLScanData:
	var hit_info:Dictionary = Landscaper.scene.raycaster.point_to_point( from, to )
	if not hit_info:
		return null
	
	# Return saved chache if scan_data happened in a previous surface.
	# Just update the current scan_data
	var cache:GLScanData = _cached_refs.get( hit_info.collider )
	if cache:
		cache.set_hit_info( hit_info )
		return cache
	
	cache = GLScanData.new().set_hit_info( hit_info )
	scan_mesh_instace( cache )
	
	if not cache.mesh_instance:
		GLDebug.error("Couldn't cache_scan_all a valid mesh from settings. Auto-coloring and perfect surface placement cannot be made")
		return cache
	
	create_perfect_collider( cache )
	create_shapes( cache )
	scan_color_sources( cache )
	
	# Engine requires a frame rest to detect the created collider and shapes
	# Then raycast again to update scan_data with the new nodes
	await Engine.get_main_loop().process_frame
	hit_info = Landscaper.scene.raycaster.point_to_point( from, to )
	cache.set_hit_info( hit_info )
	
	# The first detected collider is user-made, the following hits will always be cached_collider
	_cached_refs[cache.cached_collider] = cache
	GLDebug.internal("New scanned surface '%s'" %cache.mesh_instance.name)
	return cache


# Hard resets scanned references
func clear_cache():
	var cached_colliders:Array[Node] = Landscaper.scene.get_tree().get_nodes_in_group( GROUP_CACHE_COLLIDERS )
	var colliders:Array[Node] = Landscaper.scene.get_tree().get_nodes_in_group( GROUP_COLLIDERS )
	for cached_collider in cached_colliders:
		if is_instance_valid(cached_collider): cached_collider.queue_free()
	for collider in colliders:
		if is_instance_valid(collider):
			collider.process_mode = Node.PROCESS_MODE_INHERIT
			collider.remove_from_group( GROUP_COLLIDERS )
		
	GLDebug.internal("GLScanData cleared of '%s' references" %colliders.size())
	_cached_refs.clear()


func scan_mesh_instace(data:GLScanData):
	if not data.collider:
		return null
	
	if _controller.relative_path_from_physics_body.is_relative_path():
		var node:Node = data.collider.get_node_or_null( _controller.relative_path_from_physics_body )
		if node is MeshInstance3D and node.mesh:
			data.mesh_instance = node
	
	if _controller.parent_of_physics_body:
		var node:Node = data.collider.get_parent()
		if node is MeshInstance3D and node.mesh:
			data.mesh_instance = node


func scan_color_sources(data:GLScanData):
	var material_count:int = data.mesh_instance.get_surface_override_material_count()
	data.images.resize( material_count )
	data.colors.resize( material_count )
	
	for i in material_count:
		var material:Material = data.mesh_instance.get_active_material( i )
		var is_shader:bool = material is ShaderMaterial
		var paths = _controller.paths_in_shader_materials if is_shader else _controller.paths_in_standar_materials
		
		for path in paths:
			path = "shader_parameter".path_join(path) if is_shader else path
			var source:Variant = material.get( path )
			if source is Texture2D:
				var img:Image = source.get_image()
				if img.is_compressed():
					img.decompress()
				if img.has_mipmaps():
					img.clear_mipmaps()
				data.images[i] = img
				break
			elif source is Color:
				data.colors[i] = source
				break
		

func create_perfect_collider(data:GLScanData):
	var collider:CollisionObject3D = data.collider
	var collider_parent:Node = collider.get_parent()
	var cached_collider:CollisionObject3D = SceneManager.find_or_create_node( StaticBody3D, collider_parent, "CachedBody", not GLDebug.debugging_internal() )
	cached_collider.collision_layer = _controller.scan_layer
	cached_collider.collision_mask = 0
	cached_collider.process_mode = Node.PROCESS_MODE_INHERIT
	# Hard save them to hard clear them in case of errors
	cached_collider.add_to_group(GROUP_CACHE_COLLIDERS, true)
	collider.add_to_group(GROUP_COLLIDERS, true)
	# Clear original collider's collision layer so it doesn't get detected anymore. Resets on rest/clear_cache()
	collider.process_mode = Node.PROCESS_MODE_DISABLED
	data.cached_collider = cached_collider


func create_shapes(data:GLScanData):
	var surfaces:int = data.mesh_instance.get_surface_override_material_count()
	data.mdts.resize( surfaces )
	
	for surface in surfaces:
		var material:Material = data.mesh_instance.get_active_material( surface )
		var arrays:Array = data.mesh_instance.mesh.surface_get_arrays( surface )
		var arary_mesh:ArrayMesh = ArrayMesh.new()
		arary_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, arrays )
		
		var shape:CollisionShape3D = SceneManager.find_or_create_node( CollisionShape3D, data.cached_collider, "CachedShape%s"%surface, not GLDebug.debugging_internal() )
		shape.shape = arary_mesh.create_trimesh_shape()
		shape.debug_color = Color.PALE_VIOLET_RED
		
		# I *think* MeshDataTool cannot store more than one surface, and MeshDataTool.get_vertex() is absolutely needed.
		# So just store on the first surface but inside a surface-indexed array
		var mdt:MeshDataTool = MeshDataTool.new()
		mdt.create_from_surface(arary_mesh, 0)
		data.mdts[surface] = mdt
	


## Takes scan_data from PhysicsDirectSpaceState3D.intersect_ray(), and cached data from cache_scan()
## to find the color of cache.images with the texture's barycentric coordinates
func scan_color(data:GLScanData) -> Color:
	var surface:int = data.shape
	if surface >= data.colors.size():
		return _controller.fallback_color
	
	var color:Color = data.colors[surface]
	if color:
		GLDebug.spam("Scanned color: [color=%s]#%s[/color] on surface: %s" %[color.to_html(), color.to_html(), surface])
		return color
	
	var image:Image = data.images[surface]
	if not image:
		GLDebug.error("Color source '%s' is invalid. Using fallback color: %s" %[image, _controller.fallback_color])
		return _controller.fallback_color
	
	var mdt:MeshDataTool = data.mdts[surface]
	var face_index:int = data.face_index
	
	# Get vertex coordinates of raycasted trangled-face using MeshDataTool magic
	var xy:Array[Vector3] # World-space
	var uv:Array[Vector2] # Texture-space
	for i in range(3):
		var idx:int = mdt.get_face_vertex( face_index, i )
		xy.append( mdt.get_vertex(idx) )
		uv.append( mdt.get_vertex_uv(idx) )
	
	# Considers scale, rotation, and translation of hit surface
	var mouse_local_position:Vector3 = data.collider.to_local( data.position )
	
	# Find the cursor point coordinates of the texture-space using the triangle points
	var relative:Vector3 = Geometry3D.get_triangle_barycentric_coords( mouse_local_position, xy[0], xy[1], xy[2] )
	var cursor_texture:Vector2 = relative.x*uv[0] + relative.y*uv[1] + relative.z*uv[2]
	
	var size:Vector2 = image.get_size()-Vector2i.ONE
	var pixel_position:Vector2i = cursor_texture*size
	pixel_position.x = clampi( pixel_position.x, 0, size.x )
	pixel_position.y = clampi( pixel_position.y, 0, size.y )
	
	# Find color from that coordinate
	var px:Color = image.get_pixelv( pixel_position )
	GLDebug.spam("Scanned color: [color=%s]#%s[/color] on surface: %s" %[px.to_html(), px.to_html(), surface])
	return px
