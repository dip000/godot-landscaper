@tool
extends Brush
class_name Instancer
# Brush that spawns instances of a scene when you paint over the terrain
# Paints different shades of gray over the "texture" depending on the instance index, black for erase

const INSTANCE_TOTAL:int = 8
@onready var instances:CustomTabs = $Instances

# To re-create the same series of spawn positions
var _rng := RandomNumberGenerator.new()
var _rng_state:int


func _ready():
	for instance in instances.tabs:
		instance.on_change.connect( rebuild_terrain )
	
	# Setup RNG as documentation suggests
	_rng.set_seed( hash("GodotLandscaper") )
	_rng_state = _rng.get_state()


func save_ui():
	_raw.i_texture = _texture
	_raw.i_resolution = _resolution
	_raw.i_selected_instance = instances.selected_tab
	for i in instances.tabs.size():
		var instance:CustomInstance = instances.tabs[i]
		_raw.i_scenes[i] = instance.scene
		_raw.i_densities[i] = instance.density.value as int
		_raw.i_randomnesses[i] = instance.randomness.value
	
func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	_texture = raw.i_texture
	super(ui, scene, raw)
	_resolution = _raw.i_resolution
	instances.selected_tab = _raw.i_selected_instance
	for i in instances.tabs.size():
		var instance:CustomInstance = instances.tabs[i]
		instance.scene = _raw.i_scenes[i]
		instance.density.value = _raw.i_densities[i]
		instance.randomness.value = _raw.i_randomnesses[i]
	

func paint(pos:Vector3, primary_action:bool):
	# Spawn with primary key, erase with secondary
	if primary_action:
		var v:float = float(instances.selected_tab)/INSTANCE_TOTAL + 0.5/INSTANCE_TOTAL
		out_color = Color(v,v,v, 1.0)
	else:
		out_color = Color.BLACK
	
	# Update textures and grass positions
	_bake_out_color_into_texture( pos )
	rebuild_terrain()


func rebuild_terrain():
	save_ui()
	
	# Caches
	var world_size:Vector2 = _raw.world.size
	var world_position:Vector2 = _raw.world.position
	var world_position_inv:Vector2 = _raw.MAX_BUILD_REACH*0.5 + world_position
	var spawn_size_px:Vector2 = img.get_size()
	var builder_img = _ui.terrain_builder.img
	var max_index:int = INSTANCE_TOTAL - 1
	var max_height:float = _ui.terrain_height.max_height.value
	var scenes:Array[PackedScene] = _raw.i_scenes
	var densities:Array[int] = _raw.i_densities
	var randomnesses:Array[float] = _raw.i_randomnesses
	
	var space := _scene.terrain.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = 1<<(PluginLandscaper.COLLISION_LAYER_TERRAIN-1)
	_rng.set_state( _rng_state )
	
	for instance in _scene.instance_holder.get_children():
		instance.queue_free()
	
	for scene_index in scenes.size():
		var scene:PackedScene = scenes[scene_index]
		if not scene:
			continue
		
		var density:int = densities[scene_index] * world_size.x * world_size.y
		var randomness:float = randomnesses[scene_index]
		for i in density:
			var rand := Vector2( _rng.randf(), _rng.randf() )
			var transf := Vector3( _rng.randf(), _rng.randf(), _rng.randf() )
			
			var spawn_value:float = img.get_pixelv( rand*spawn_size_px ).r
			var valid_ground:float = builder_img.get_pixelv( rand*world_size + world_position_inv ).r
			
			# Ignore non-spawns
			var spawn_variant:int = roundi( spawn_value*max_index )
			if is_zero_approx( spawn_value * valid_ground ):
				continue
			
			# Random position in XZ worldspace
			var pos_2d:Vector2 = rand * world_size + world_position
			var instance:Node3D = scene.instantiate()
			
			# Raycast to the HeightMapShape3D to find the actual ground level
			ray.from = Vector3( pos_2d.x, max_height+1, pos_2d.y )
			ray.to = Vector3( pos_2d.x, -max_height-1, pos_2d.y )
			var result:Dictionary = space.intersect_ray( ray )
			if not result:
				continue
			
			_scene.instance_holder.add_child( instance )
			instance.owner = _scene.owner
			instance.global_position = Vector3( pos_2d.x, result.position.y, pos_2d.y )
			instance.global_rotation = transf * randomness
			instance.scale = (transf*2 - Vector3.ONE) * randomness + Vector3.ONE

