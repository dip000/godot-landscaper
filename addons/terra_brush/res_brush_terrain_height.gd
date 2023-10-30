@tool
extends TBrush
class_name TBrushTerrainHeight
# Brush that creates mountains or valleys when you paint over the terrain
# Paints shades of gray colors over the "texture" depending on the height


## How quickly you want the terrain to create mountains ot valleys when you paint over the terrain
@export_range(8.0, 100.0, 1.0, "suffix:%") var strength:float = 20:
	set(v):
		strength = v
		set_active( true )

## Current terrain height will be recalculated accodringly
@export var max_height:float = 2:
	set(v):
		max_height = max( 0.1, v )
		set_active( true )
		update_terrain_collider()
		_update_grass_height()
		_update_terrain_shader("max_height", max_height)


func setup():
	resource_name = "terrain_height"

func template(size:Vector2i):
	set_texture_resolution( 6 )
	set_texture( _create_texture(Color.BLACK, size*texture_resolution) )


func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active:
		return
	
	# Mountains with primary key, ridges with secondary (small alpha to blend the heightmap colors smoothly)
	out_color = Color(1,1,1,strength*0.001) if primary_action else Color(0,0,0,strength*0.001)
	_bake_brush_into_surface(scale, pos)
	on_texture_update()


func on_texture_update():
	#[WARNING] Always update colliders first since grass placement is based of them
	_update_terrain_shader("terrain_height", texture)
	update_terrain_collider()
	_update_grass_height()


func update_terrain_collider():
	if not texture:
		return
	
	# Caches
	var height_image:Image = texture.get_image()
	var terrain_size_m:Vector2i = tb.map_size
	var terrain_size_px:Vector2i = height_image.get_size() - Vector2i.ONE
	var height_shape:HeightMapShape3D = tb.height_shape
	
	# Update _terrain collider
	for w in height_shape.map_width:
		for d in height_shape.map_depth:
			# Convert to range [0,1] then to pixel size
			var x_px:int = (w as float / terrain_size_m.x) * terrain_size_px.x
			var z_px:int = (d as float / terrain_size_m.y) * terrain_size_px.y
			
			# Update the new height with that texture pixel
			var y_m:float = height_image.get_pixel(x_px, z_px).r * max_height
			var i:int = d*(terrain_size_m.x+1) + w
			height_shape.map_data[i] = y_m


func _update_grass_height():
	if not tb:
		return
	
	# Caches
	var space := tb.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = 1<<(MainPlugin.COLLISION_LAYER-1)
	
	# Now that we have the collider aligned, raycast each grass for the exact ground position (as opposed by relaying on the heightmap)
	for multimesh_inst in tb.grass_holder.get_children():
		var multimesh:MultiMesh = multimesh_inst.multimesh
		for instance_index in multimesh.instance_count:
			var transform:Transform3D = multimesh.get_instance_transform(instance_index)
			
			ray.from = transform.origin + Vector3.UP * max_height
			ray.to = transform.origin + Vector3.DOWN * max_height
			var result = space.intersect_ray(ray)
			
			# Update the new height with that collision point
			transform.origin.y = result.position.y
			multimesh.set_instance_transform(instance_index , transform)
		
