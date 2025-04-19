@tool
extends Node
class_name EcoInstancer

@export_category("Options")
@export_range(0.1, 10, 0.1, "or_greater") var brush_size:float = 1.0:
	set(v):
		brush_size = v
		Landscaper.scene.brush.scale = v * Vector3.ONE

@export_category("Actions")
@export var primary_color:Color = Color.SEA_GREEN
@export var secondary_color:Color = Color.PALE_GREEN
@export_range(0.0, 1.0, 0.01) var ground_gradient:float = 0.5

@export_range(0.0, 10.0, 0.1, "or_greater") var add_ratio:float = 2.0
@export_range(0.0, 1.0, 0.1) var remove_ratio:float = 0.7

@export_category("Instances")
@export_storage var _instances:Array[InstanceData]


func _get(property:StringName):
	if property.left(-1) == "instance_":
		var index:int = property.right(-1).to_int()
		return _instances[index]

func _set(property:StringName, value:Variant):
	if property.left(-1) == "instance_":
		#if not value or value is MultiMeshInstanceData or value is SceneInstanceData:
			var index:int = property.right(-1).to_int()
			_instances[index] = value
			notify_property_list_changed()
			return true
	return false

func _get_property_list():
	var props:Array = []
	_instances = _instances.filter(func(v): return v)
	_instances.resize( _instances.size()+1 )
	
	for i in _instances.size():
		props.append({
			"name": "instance_%d" % i,
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "InstanceData",
		})
	return props

func _for_each_instance(method:Callable):
	var i:int = 0
	for instance in _instances:
		if instance and instance.enable:
			method.call( i, instance )
		i += 1



func action_start(hit_info:Dictionary):
	_for_each_instance(func(i:int, instance:InstanceData):
		instance.transforms.clear()
		instance.top_colors.clear()
		instance.bottom_colors.clear()
		instance.root_node = self
		instance.surface_position = hit_info.collider.global_position
		instance.instance_index = i
		instance.radius = brush_size * 0.5
		instance.cursor_position = hit_info.position
		instance.face_index = hit_info.face_index
		instance.add_ratio = add_ratio
		instance.remove_ratio = remove_ratio
		instance.primary_color = primary_color
		instance.secondary_color = secondary_color
		instance.face_index = hit_info.face_index
		instance.cursor_position = hit_info.position
		if UIManager.action == "Spawn":
			instance.spawn.start( instance )
		if UIManager.action == "Color":
			instance.color.start( instance )
	)
	

func action_primary(hit_info:Dictionary):
	_for_each_instance(func(_i:int, instance:InstanceData):
		instance.face_index = hit_info.face_index
		instance.cursor_position = hit_info.position
		if UIManager.action == "Spawn":
			instance.spawn.primary( instance )
		if UIManager.action == "Color":
			instance.color.primary( instance )
	)

func action_secondary(hit_info:Dictionary):
	_for_each_instance(func(_i:int, instance:InstanceData):
		instance.face_index = hit_info.face_index
		instance.cursor_position = hit_info.position
		if UIManager.action == "Spawn":
			instance.spawn.secondary( instance )
		if UIManager.action == "Color":
			instance.color.secondary( instance )
	)

func action_end():
	_for_each_instance(func(_i:int, instance:InstanceData):
		if UIManager.action == "Spawn":
			instance.spawn.end( instance )
		if UIManager.action == "Color":
			instance.color.end( instance )
	)

func scale_by(value:float):
	brush_size = clamp( brush_size+value, 0.01, 10 )
