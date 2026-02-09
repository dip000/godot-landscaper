## Utility for scanning scene resources.
##
## Raycast to a surface and finds its mesh instance, mesh, material and color source.
## Caches all results so it doesn't have to rescan every time.

@tool
extends Resource
class_name GLSurfaceScanner

const GROUP_SURFACE_COLLIDERS:String = "landscaper_surface_colliders"
const GROUP_USER_COLLIDERS:String = "landscaper_user_collider"

static var _cached_refs:Dictionary[int, GLScanData]
var _controller:GLController
var _raycaster:GLSceneRaycaster


func _init(controller:GLController):
	_controller = controller
	_raycaster = GLandscaper.scene.raycaster


## Raycasts from one world point to another and returns a GLScanData with scanning capabilities
func scan_point_to_point(from:Vector3, to:Vector3, include_colors:bool=true) -> GLScanData:
	var hit_info:Dictionary = _raycaster.point_to_point( from, to )
	if not hit_info:
		return null
	
	var cache:GLScanData
	var id:int = hit_info.collider_id
	
	if _cached_refs.has( id ):
		_cached_refs[id].set_hit_info( hit_info )
		return _cached_refs[id]
	
	cache = GLScanData.new()
	cache.set_hit_info( hit_info )
	
	if not scan_mesh_instance( cache ): #sets mesh_instance from hit_info.collider
		GLDebug.error("Scanner coudn't scan the mesh from body '%s'. Check your controller scan configs" %hit_info.collider.name)
		return null
	
	if include_colors:
		scan_color_source( cache ) #fills color_sources[hit_info.shape]
	create_surfaces( cache ) #fills mdts[hit_info.shape]
	
	await Engine.get_main_loop().process_frame
	hit_info = _raycaster.point_to_point( from, to )
	if hit_info:
		cache.set_hit_info( hit_info )
		_cached_refs[hit_info.collider_id] = cache
		GLDebug.internal("Scanner has found a new Mesh '%s'" %[cache.mesh_instance.name])
		return cache
	return null



## Hard resets scanned references.
## GROUP_SURFACE_COLLIDERS is the interal created collider per surface to be deleted.
## GROUP_USER_COLLIDERS is the original user collider to be re-enabled.
static func clear_all_surfaces():
	var surface_colliders:Array[Node] = GLandscaper.scene.get_tree().get_nodes_in_group( GROUP_SURFACE_COLLIDERS )
	var user_colliders:Array[Node] = GLandscaper.scene.get_tree().get_nodes_in_group( GROUP_USER_COLLIDERS )
	
	for surface_collider in surface_colliders:
		if is_instance_valid( surface_collider ):
			surface_collider.queue_free()
	
	for user_collider in user_colliders:
		if user_collider is CollisionObject3D and is_instance_valid( user_collider ):
			user_collider.remove_from_group( GROUP_USER_COLLIDERS )
			user_collider.process_mode = Node.PROCESS_MODE_INHERIT
	
	if surface_colliders:
		GLDebug.internal("Scanner cleared '%s' surfaces" %surface_colliders.size())
	_cached_refs.clear()


## Finds a MeshInstance3D from 'data.body' with controller options
func scan_mesh_instance(data:GLScanData) -> bool:
	if _controller.relative_path_from_physics_body.is_relative_path():
		var node:Node = data.body.get_node_or_null( _controller.relative_path_from_physics_body )
		if node is MeshInstance3D and node.mesh:
			data.mesh_instance = node
			return true
	
	if _controller.parent_of_physics_body:
		var node:Node = data.body.get_parent()
		if node is MeshInstance3D and node.mesh:
			data.mesh_instance = node
			return true
	
	if _controller.child_of_physics_body:
		var node:Node = data.body.get_parent()
		for child in node.get_children():
			if node is MeshInstance3D and node.mesh:
				data.mesh_instance = node
				return true
	return false


func scan_color_source(data:GLScanData):
	var material_count:int = data.mesh_instance.get_surface_override_material_count()
	
	for shape in material_count:
		var material:Material = data.mesh_instance.get_active_material( shape )
		
		for path in _controller.paths_in_material:
			var source:Variant = material.get( path )
			if source is Texture2D:
				var img:Image = source.get_image()
				if img.is_compressed():
					img.decompress()
				if img.has_mipmaps():
					img.clear_mipmaps()
				data.color_sources[shape] = img
				break
			
			elif source is Color:
				data.color_sources[shape] = source
				break
		
		if not data.color_sources.has(shape):
			GLDebug.warning("Scanner couldn't find color source of surface '%s', of Mesh '%s'. Check your controller scan configs" %[shape, data.mesh_instance.name])



## Instantiates a CollisionShape3D on current surface
func create_surfaces(data:GLScanData):
	var surfaces:int = data.mesh_instance.get_surface_override_material_count()
	var surface_body:StaticBody3D = GLSceneManager.find_or_create_node( StaticBody3D, data.body.get_parent(), "GLBody", not GLDebug.debugging_internal() )
	
	surface_body.add_to_group( GROUP_SURFACE_COLLIDERS, true )
	data.body.add_to_group( GROUP_USER_COLLIDERS, true)
	data.body.process_mode = Node.PROCESS_MODE_DISABLED
	surface_body.process_mode = Node.PROCESS_MODE_DISABLED
	
	for surface in surfaces:
		var arrays:Array = data.mesh_instance.mesh.surface_get_arrays( surface )
		var arary_mesh:ArrayMesh = ArrayMesh.new()
		arary_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, arrays )
		
		var mdt:MeshDataTool = MeshDataTool.new()
		mdt.create_from_surface( arary_mesh, 0 )
		data.mdts[surface] = mdt
		
		var surface_collider:CollisionShape3D = GLSceneManager.find_or_create_node( CollisionShape3D, surface_body, "GLSurface%s"%surface, not GLDebug.debugging_internal() )
		surface_collider.shape = arary_mesh.create_trimesh_shape()
	
	surface_body.process_mode = Node.PROCESS_MODE_ALWAYS
	


## Returns the color of the 'color_source' from scan_color_source(), which can be an image or a color.
## Requires the mesh's data wrapped in a MeshDataTool from create_surface()
func scan_color(data:GLScanData) -> Color:
	if data.color_source is Color:
		GLDebug.spam("Scanner found color: [color=#%s]#%s" %[data.color_source.to_html(), data.color_source.to_html()])
		return data.color_source
	
	if not data.mdt or not data.body or not data.color_source is Image:
		GLDebug.error("Scanner coudn't find any color for surface '%s' of mesh '%s'" %[data.shape, data.mesh_instance.name])
		return _controller.fallback_color
	
	# Get vertex coordinates of raycasted trangled-face using MeshDataTool magic
	var xy:Array[Vector3] # World-space
	var uv:Array[Vector2] # Texture-space
	for i in range(3):
		var idx:int = data.mdt.get_face_vertex( data.face_index, i )
		xy.append( data.mdt.get_vertex(idx) )
		uv.append( data.mdt.get_vertex_uv(idx) )
	
	# Considers scale, rotation, and translation of hit surface
	var mouse_local_position:Vector3 = data.body.to_local( data.position )
	
	# Find the cursor point coordinates of the texture-space using the triangle points
	var relative:Vector3 = Geometry3D.get_triangle_barycentric_coords( mouse_local_position, xy[0], xy[1], xy[2] )
	var cursor_texture:Vector2 = relative.x*uv[0] + relative.y*uv[1] + relative.z*uv[2]
	
	var size:Vector2 = data.color_source.get_size()-Vector2i.ONE
	var pixel_position:Vector2i = cursor_texture*size
	pixel_position.x = clampi( pixel_position.x, 0, size.x )
	pixel_position.y = clampi( pixel_position.y, 0, size.y )
	
	# Find color from that coordinate
	var color:Color = data.color_source.get_pixelv( pixel_position )
	GLDebug.spam("Scanner found color '[color=#%s]#%s[/color]' at %s" %[color.to_html(), color.to_html(), data.position])
	return color
