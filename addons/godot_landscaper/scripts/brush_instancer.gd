@tool
extends Brush
class_name Instancer
## Brush that spawns instances of a scene when you paint_brushing over the terrain
## Paints different shades of gray over the "texture" depending on the instance index, black for erase

const DESCRIPTION := "Spawn your custom scenes like a rock or a tree with left click, erase with right click"
const INSTANCE_TOTAL:int = 8
@onready var instances:CustomTabs = $Instances

# To re-create the same series of spawn positions
var _rng := RandomNumberGenerator.new()
var _rng_state:int


func _ready():
	for instance in instances.tabs:
		instance.on_change.connect( rebuild )
	
	# Setup RNG as documentation suggests
	_rng.set_seed( hash("GodotLandscaper") )
	_rng_state = _rng.get_state()


func selected_brush():
	_update_overlay_shader("brush_color",  Color.GRAY)

func _on_save_ui():
	_project.i_texture = texture
	_project.i_resolution = _resolution
	_project.i_selected_instance = instances.selected_tab
	
	# Idk who's clearing '_project.i_etc' in some other place or what in tarnation is happening
	# but when assigned directly to project throws "index out of range"
	var tabs:Array[Node] = instances.tabs
	var randomnesses := _project.i_randomnesses.duplicate()
	var scenes:Array[PackedScene]
	for i in tabs.size():
		scenes.append( _project.i_scenes[i] )
	for i in tabs.size():
		scenes[i] = tabs[i].scene
		randomnesses[i] = tabs[i].randomness.value
	_project.i_randomnesses = randomnesses
	_project.i_scenes = scenes
	
func _on_load_ui(scene:SceneLandscaper):
	_input_texture( _project.i_texture )
	_resolution = _project.i_resolution
	
	var tabs:Array[Node] = instances.tabs
	for i in tabs.size():
		tabs[i].scene = _project.i_scenes[i]
		tabs[i].randomness.value = _project.i_randomnesses[i]
		instances.selected_tab = i
	instances.selected_tab = _project.i_selected_instance

func paint_primary(pos:Vector3):
	var v:float = float(instances.selected_tab)/INSTANCE_TOTAL + 0.5/INSTANCE_TOTAL
	var color:Color = Color(v,v,v, 1.0)
	_update_overlay_shader("brush_color",  Color.WHITE)
	_bake_color_into_texture( color, pos )
	rebuild()

func paint_secondary(pos:Vector3):
	_update_overlay_shader("brush_color",  Color.BLACK)
	_bake_color_into_texture( Color.BLACK, pos )
	rebuild()

func _on_rebuild():
	if not _project:
		return
	
	# Caches
	var tabs:Array[Node] = instances.tabs
	var world_size:Vector2 = _project.world.size
	var world_position:Vector2 = _project.world.position
	var size_px:Vector2 = img.get_size()
	var max_index:int = INSTANCE_TOTAL - 1
	var max_height:float = ui.terrain_height.max_height.value
	var terrain_pos:Vector3 = _scene.terrain.global_position
	var terrain_pos_2d := Vector2(terrain_pos.x, terrain_pos.z)
	
	var space := _scene.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = 1<<(PluginLandscaper.COLLISION_LAYER_TERRAIN-1)
	_rng.set_state( _rng_state )
	
	for instance in _scene.instance_holder.get_children():
		instance.queue_free()
	
	for x in img.get_width():
		for y in img.get_height():
			var rand_rotation := Vector3( _rng.randf_range(-PI,PI), _rng.randf_range(-PI,PI), _rng.randf_range(-PI,PI) )
			var rand_scale := Vector3( _rng.randf_range(0,2), _rng.randf_range(0,2), _rng.randf_range(0,2) )
			
			# Skip black pixels (empty slots)
			var position_px := Vector2( x, y )
			var value_px:float = img.get_pixelv( position_px ).r
			if is_zero_approx( value_px ):
				continue
			
			# Skip invalid scenes (in case a scene was seted previously and then deleted)
			var scene_index:int = roundi( value_px*max_index )
			var scene:PackedScene = tabs[scene_index].scene
			if not scene:
				continue
			
			var randomness:float = tabs[scene_index].randomness.value
			var pos_2d:Vector2 = position_px/size_px * world_size + world_position + terrain_pos_2d
			
			# Raycast to the HeightMapShape3D to find the actual ground level
			ray.from = Vector3( pos_2d.x, terrain_pos.y+max_height, pos_2d.y )
			ray.to = Vector3( pos_2d.x, terrain_pos.y-max_height, pos_2d.y )
			var result:Dictionary = space.intersect_ray( ray )
			if not result:
				continue
			
			var instance:Node3D = scene.instantiate()
			_scene.instance_holder.add_child( instance )
			instance.owner = _scene.owner
			instance.global_position = Vector3( pos_2d.x, result.position.y, pos_2d.y )
			instance.global_rotation = rand_rotation * randomness
			instance.scale = (rand_scale - Vector3.ONE) * randomness + Vector3.ONE
