@tool
extends UIBrush
class_name GrassScatter
## Brush that spawns grass when you paint over the terrain

@onready var density:CustomNumberInput = $Density
@onready var grass_size:CustomVector2Input = $Size
@onready var variants:CustomTabs = $Variants

var _mmis:Array[MultiMeshInstance3D]


func _ready():
	grass_size.on_change.connect( _on_grass_size_changed )


func _on_grass_size_changed():
	if _mmis:
		var mesh:Mesh = _mmis[0].multimesh.mesh
		mesh.size = grass_size.value
		mesh.center_offset.z = -mesh.size.y*0.5


func _paint_start(info:Dictionary):
	# Check scene references' health
	var surface:Node3D = info.collider
	var holder:Node3D = SceneManager.find_or_create_node( Node3D, surface, name )
	_mmis.clear()
	
	# Setup MultiMeshInstance3D's
	for tab in variants.enabled_tabs:
		var mmi:MultiMeshInstance3D = SceneManager.find_or_create_node( MultiMeshInstance3D, holder, tab.name )
		if not mmi.multimesh:
			mmi.multimesh = MultiMesh.new()
			mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			mmi.multimesh.mesh = AssetsManager.QUAD_GRASS
			mmi.multimesh.use_colors = true
			mmi.multimesh.use_custom_data = true
		mmi.multimesh.mesh.size = grass_size.value
		mmi.multimesh.mesh.center_offset.z = -grass_size.y*0.5
		mmi["instance_shader_parameters/variant_index"] = tab.get_index()
		_mmis.append( mmi )


# Spawns Grass
func _paint_primary(info:Dictionary):
	var radius:float = Landscaper.ui.brush_size.value * 0.5
	var world_position:Vector3 = info.collider.global_position
	var cursor:Vector3 = info.position
	for mmi in _mmis:
		var transforms:Array[Transform3D]
		var bottom_colors:Array[Color]
		var top_colors:Array[Color]
		_get_all( mmi.multimesh, transforms, bottom_colors, top_colors )
		_add_radial( transforms, bottom_colors, top_colors, world_position, cursor, radius, density.value )
		_spawn( mmi.multimesh, transforms, bottom_colors, top_colors )


# Despawns Grass
func _paint_secondary(info:Dictionary):
	var radius:float = Landscaper.ui.brush_size.value * 0.5
	var world_position:Vector3 = info.collider.global_position
	var cursor:Vector3 = info.position
	for mmi in _mmis:
		var transforms:Array[Transform3D]
		var bottom_colors:Array[Color]
		var top_colors:Array[Color]
		_get_remove_radial( mmi.multimesh, transforms, bottom_colors, top_colors, world_position, cursor, radius )
		_spawn( mmi.multimesh, transforms, bottom_colors, top_colors )


# Gets every MultiMesh transform except the ones inside the brush
func _get_remove_radial(mm:MultiMesh, transforms:Array[Transform3D], bottom_colors:Array[Color], top_colors:Array[Color], world_position:Vector3, cursor:Vector3, radius:float):
	for i in mm.instance_count:
		var transform:Transform3D = mm.get_instance_transform(i)
		var instance_pos:Vector3 = transform.origin + world_position
		var dist:float = instance_pos.distance_to( cursor )
		if dist > radius:
			transforms.append( transform )
			bottom_colors.append( mm.get_instance_color(i) )
			top_colors.append( mm.get_instance_custom_data(i) )


# Gets every MultiMesh transform and color
func _get_all(mm:MultiMesh, transforms:Array[Transform3D], bottom_colors:Array[Color], top_colors:Array[Color]):
	for i in mm.instance_count:
		transforms.append( mm.get_instance_transform(i) )
		bottom_colors.append( mm.get_instance_color(i) )
		top_colors.append( mm.get_instance_custom_data(i) )


func _add_radial(transforms:Array[Transform3D], bottom_colors:Array[Color], top_colors:Array[Color], world_position:Vector3, cursor:Vector3, radius:float, density:float):
	for i in range(density):
		# Two random points over the brush sphere to make a ray
		var sphere_surface1:Vector3 = _get_surface_point(radius) + cursor
		var sphere_surface2:Vector3 = _get_surface_point(radius) + cursor
		
		# Add transforms for every surface found
		var result:Dictionary = Landscaper.scene.raycaster.point_to_point(sphere_surface1, sphere_surface2)
		if result:
			var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
			var transf := Transform3D( basis, result.position - world_position )
			transf = transf.rotated_local( Vector3.FORWARD, randf()*PI )
			transforms.append( transf )
			
			var mesh:Mesh = result.collider.get_parent().mesh
			var color:Color = _scan_color( mesh, result.face_index, result.position, world_position )
			bottom_colors.append( color )
			top_colors.append( Color.WHITE )


# Re-Spawns the grass from the transforms given
func _spawn(mm:MultiMesh, transforms:Array[Transform3D], bottom_colors:Array[Color], top_colors:Array[Color]):
	mm.instance_count = transforms.size()
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, transforms[i] )
		mm.set_instance_color( i, bottom_colors[i] )
		mm.set_instance_custom_data( i, top_colors[i] )

# Not really evenly distributed but whatever
func _get_surface_point(radius:float) -> Vector3:
	var point := Vector3( randf_range(-1,1), randf_range(-1,1), randf_range(-1,1) )
	point = point.normalized()
	return point * radius


func _scan_color(mesh:Mesh, face_index:int, cursor:Vector3, surface_position:Vector3) -> Color:
	var mesh_arrays:Array = mesh.surface_get_arrays(0)
	var arr_mesh := ArrayMesh.new()
	var mdt := MeshDataTool.new()
	
	# Setup MeshDataTool from the current mesh
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	mdt.create_from_surface( arr_mesh, 0 )
	
	# Get vertex coordinates of raycasted trangled-face using MeshDataTool magic
	var xy:Array[Vector3] #World-space
	var uv:Array[Vector2] #Texture-space
	for i in range(3):
		var idx:int = mdt.get_face_vertex( face_index, i )
		xy.append( mdt.get_vertex(idx) )
		uv.append( mdt.get_vertex_uv(idx) )
	
	# Find the cursor point coordinates of the texture-space using the triangle points
	var cursor_world_local:Vector3 = cursor - surface_position
	var relative:Vector3 = Geometry3D.get_triangle_barycentric_coords(cursor_world_local, xy[0], xy[1], xy[2])
	var cursor_texture:Vector2 = relative.x*uv[0] + relative.y*uv[1] + relative.z*uv[2]
	
	# Find color from that coordinate
	var texture:Texture2D = mesh.surface_get_material(0).albedo_texture
	var size:Vector2 = texture.get_size()-Vector2.ONE
	var img:Image = texture.get_image()
	var px:Color = img.get_pixelv( cursor_texture*size )
	
	Debug.spam("[color=%s]#%s[/color]" %[px.to_html(), px.to_html()])
	return px
	
