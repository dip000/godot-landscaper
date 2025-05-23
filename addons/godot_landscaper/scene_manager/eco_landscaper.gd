@tool
extends Node
class_name EcoInstancer

@export_category("Options")
@export_range(0.1, 10, 0.1, "or_greater") var brush_size:float = 1.0:
	set(v):
		Landscaper.scene.brush.scale = v * Vector3.ONE
	get: return Landscaper.scene.brush.scale.x


@export_category("Select Action:")
## Left-Button-Mouse Action. Only available on Multi Mesh Instances
@export var primary_color:Color = Color.SEA_GREEN
## Right-Button-Mouse Action. Only available on Multi Mesh Instances
@export var secondary_color:Color = Color.PALE_GREEN
## Space between the ground color and the instance color. Only available on Multi Mesh Instances

## How many instances to spawn per input tick
@export_range(1, 10, 1, "or_greater") var add_ratio:float = 2.0
## How many instances to de-spawn per input tick
@export_range(0.1, 1, 0.01) var remove_ratio:float = 0.7

@export_category("Enable Instances:")
@export_storage var _instances:Array[Instancer]


func _get(property:StringName):
	if property.left(-1) == "instance_":
		var index:int = property.right(-1).to_int()
		return _instances[index]

func _set(property:StringName, value:Variant):
	if property.left(-1) == "instance_":
		var index:int = property.right(-1).to_int()
		_instances[index] = value
		notify_property_list_changed()
		return true
	return false

func _get_property_list():
	var props:Array[Dictionary]
	_instances = _instances.filter(func(v): return v)
	_instances.resize( _instances.size()+1 )
	
	for i in _instances.size():
		props.append({
			"name": "instance_%d" % i,
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Instancer",
		})
	return props

func _for_each_instance(method:Callable):
	var i:int = 0
	for instance in _instances:
		if instance and instance.enable:
			method.call( i, instance )
		i += 1



func action_start(hit_info:Dictionary):
	_for_each_instance(func(i:int, instance:Instancer):
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
		if UIManager.spawn:
			instance.spawn.start( instance )
		if UIManager.color:
			instance.color.start( instance )
	)
	

func action_primary(hit_info:Dictionary):
	_for_each_instance(func(_i:int, instance:Instancer):
		instance.face_index = hit_info.face_index
		instance.cursor_position = hit_info.position
		if UIManager.spawn:
			instance.spawn.primary( instance )
		if UIManager.color:
			instance.color.primary( instance )
	)

func action_secondary(hit_info:Dictionary):
	_for_each_instance(func(_i:int, instance:Instancer):
		instance.face_index = hit_info.face_index
		instance.cursor_position = hit_info.position
		if UIManager.spawn:
			instance.spawn.secondary( instance )
		if UIManager.color:
			instance.color.secondary( instance )
	)

func action_end():
	_for_each_instance(func(_i:int, instance:Instancer):
		if UIManager.spawn:
			instance.spawn.end( instance )
		if UIManager.color:
			instance.color.end( instance )
	)

func scale_by(value:float):
	brush_size = clamp( brush_size+value, 0.01, 10 )
