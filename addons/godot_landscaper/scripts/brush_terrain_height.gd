@tool
extends Brush
class_name TerrainHeight
## Brush that creates mountains or valleys when you paint_brushing over the terrain
## Paints shades of gray colors over the "texture" depending on the height

const DESCRIPTION := "Create mountains with left click, valleys with right click"
@onready var strength:CustomSliderUI = $Strenght
@onready var max_height:CustomNumberInput = $MaxHeight
@onready var aplly_all_height:CustomDoubleButtons = $ApplyAll


func _ready():
	max_height.on_change.connect( _on_max_height )
	aplly_all_height.on_change.connect( _on_apply_all_changed )

func _on_max_height(height:float):
	rebuild()
	ui.instancer.rebuild()
	update_collider()
	_update_grass()

func _on_apply_all_changed(heighten:bool):
	var src_size:Vector2i = img.get_size()
	var full_rect := Rect2i(Vector2i.ZERO, src_size)
	var color := Color(1, 1, 1, 0.05) if heighten else Color(0, 0, 0, 0.05)
	var src:Image = _create_img( color, src_size, img.get_format() )
	img.blend_rect( src, full_rect, Vector2i.ZERO )
	texture.update( img )
	rebuild()
	ui.instancer.rebuild()
	update_collider()
	_update_grass()

func selected_brush():
	_update_overlay_shader("brush_color", Color.GRAY)

func _on_save_ui():
	_project.th_texture = texture
	_project.th_resolution = _resolution
	_project.th_strength = strength.value
	_project.th_max_height = max_height.value

func _on_load_ui(scene:SceneLandscaper):
	_input_texture( _project.th_texture )
	_resolution = _project.th_resolution
	strength.value = _project.th_strength
	max_height.value = _project.th_max_height


func paint_primary(pos:Vector3):
	var color:Color = Color(1,1,1,strength.value)
	var world_offset:Vector2 = Vector2(_project.world.position) - Vector2(0.5, 0.5)
	_update_overlay_shader("brush_color", color)
	_bake_color_into_texture( color, pos, true, world_offset )
	rebuild()

func paint_secondary(pos:Vector3):
	var color:Color = Color(0,0,0,strength.value)
	var world_offset:Vector2 = Vector2(_project.world.position) - Vector2(0.5, 0.5)
	_update_overlay_shader("brush_color", color)
	_bake_color_into_texture( color, pos, true, world_offset )
	rebuild()

func paint_end():
	ui.instancer.rebuild()
	update_collider()
	_update_grass()

func _on_rebuild():
	ui.terrain_builder.rebuild()


func update_collider():
	# Caches
	var height_collider:CollisionShape3D = _scene.collider
	var height_shape:HeightMapShape3D = height_collider.shape
	var world:Rect2i = _project.world
	var node:Vector3 = _scene.terrain.global_position
	var position_offset:Vector2 = Vector2(world.position) + (world.size * 0.5) + Vector2(node.x, node.z)
	
	height_shape.map_width = world.size.x + 1
	height_shape.map_depth = world.size.y + 1
	height_collider.global_position.x = position_offset.x
	height_collider.global_position.z = position_offset.y
	
	
	# Update _terrain collider
	for x in height_shape.map_width:
		for z in height_shape.map_depth:
			
			# Update height with that pixel's value
			var y:float = img.get_pixel(x, z).r * max_height.value
			var coordinate:int = z * (height_shape.map_width) + x
			height_shape.map_data[coordinate] = y
	

func _update_grass():
	# Caches
	var terrain_pos:Vector3 = _scene.terrain.global_position
	var space := _scene.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = 1<<(PluginLandscaper.COLLISION_LAYER_TERRAIN-1)
	
	# Raycast collider for the exact ground level position
	for multimesh_inst in _scene.grass_holder.get_children():
		var multimesh:MultiMesh = multimesh_inst.multimesh
		for instance_index in multimesh.instance_count:
			var transform:Transform3D = multimesh.get_instance_transform(instance_index)
			var pos:Vector3 = transform.origin + terrain_pos
			
			ray.from = pos + Vector3.UP * max_height.value
			ray.to = pos + Vector3.DOWN * max_height.value
			var result:Dictionary = space.intersect_ray(ray)
			if not result:
				continue
			
			# Update the new height with that collision point
			transform.origin.y = result.position.y - terrain_pos.y
			multimesh.set_instance_transform(instance_index , transform)
	

# Compenzate one pixel for the extra vertex
func resize_texture(rect:Rect2i, fill_color:Color):
	rect.size += Vector2i.ONE
	super(rect, fill_color)
