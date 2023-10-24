@tool
extends TBrush
class_name TBrushTerrainHeight
# Brush that creates mountains or valleys when you paint over the terrain
# Paints shades of gray colors over the "surface_texture" depending on the height


# Grass in slopes might look like they're floating at full strenght
const HEIGHT_STRENGTH:float = 0.95

## How quickly you want the terrain to create mountains ot valleys when you paint over the terrain
@export_range(8.0, 100.0, 1.0, "suffix:%") var strength:float = 20:
	set(v):
		strength = v
		on_active.emit()
		active = true


func setup():
	resource_name = "terrain_height"
	surface_texture = ImageTexture.create_from_image( _create_empty_img(Color.BLACK) )


func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active:
		return
	
	# Mountains with primary key, ridges with secondary (small alpha to blend the heightmap colors smoothly)
	t_color = Color(1,1,1,strength*0.001) if primary_action else Color(0,0,0,strength*0.001)
	_bake_brush_into_surface(scale, pos)
	update()


func update():
	if not terrain or not surface_texture:
		return
	
	#[WARNING] Always update colliders first since grass placement is based of them
	terrain.terrain_mesh.material.set_shader_parameter("terrain_height", surface_texture)
	update_terrain_collider()
	_update_grass_height()
	
	
func update_terrain_collider():
	if not terrain or not surface_texture:
		return
	
	# Caches
	var height_image:Image = surface_texture.get_image()
	var terrain_size_m:Vector2 = terrain.terrain_mesh.size
	var terrain_size_px:Vector2i = height_image.get_size() - Vector2i.ONE
	var height_shape:HeightMapShape3D = terrain.height_shape
	
	# Update _terrain collider
	for w in height_shape.map_width:
		for d in height_shape.map_depth:
			# Convert to range [0,1] then to pixel size
			var x_px:int = (w / terrain_size_m.x) * terrain_size_px.x
			var z_px:int = (d / terrain_size_m.y) * terrain_size_px.y
			
			# Update the new height with that texture pixel
			var y_m:float = height_image.get_pixel(x_px, z_px).r * TBrushTerrainHeight.HEIGHT_STRENGTH
			var i:int = d*(terrain_size_m.x+1) + w
			height_shape.map_data[i] = y_m


func _update_grass_height():
	if not surface_texture or not terrain:
		return
	
	# Caches
	var space := terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	
	# Now that we have the collider aligned, raycast each grass for the exact ground position (as opposed by relaying on the heightmap)
	for child in terrain.get_children():
		if not child is MultiMeshInstance3D:
			continue
		
		var multimesh:MultiMesh = child.multimesh
		for instance_index in multimesh.instance_count:
			var transform:Transform3D = multimesh.get_instance_transform(instance_index)
			
			ray.from = transform.origin + Vector3.UP
			ray.to = transform.origin + Vector3.DOWN
			var result = space.intersect_ray(ray)
			
			# Update the new height with that collision point
			transform.origin.y = result.position.y
			multimesh.set_instance_transform(instance_index , transform)
		
