@tool
extends Node
class_name LandscaperTool

var TABS_CONFIG:Array[InspectorTab] = [
	preload(AssetsManager.SPAWN_TAB),
	preload(AssetsManager.PAINT_TAB),
]
var CURRENT_TAB:InspectorTab = TABS_CONFIG[0]
var TEMPLATE_CONFIGS:StringName = "configs"
var TEMPLATE_INSTANCE:StringName = "grass_"
var TEMPLATE_PROJECT:StringName = "_project"


func get_instance(project:Resource, index:int) -> InstanceConfigs:
	if not project: return null
	var configs:Array = project[TEMPLATE_CONFIGS]
	if index >= configs.size(): return null
	return configs[index]

func set_instance(project:Resource, instance:InstanceConfigs, index:int):
	if not project: return
	project[TEMPLATE_CONFIGS][index] = instance
	if instance:
		instance.set_instance_index(index)
		instance.select_brush(CURRENT_TAB.brush, self, project)
		instance.fix_dependencies()
		instance.load_template()
	_notify_property_list_changed_once()


func _validate_configs(project:Resource, cap:int, property:Dictionary):
	if not project or not property.name.begins_with(TEMPLATE_INSTANCE):
		return
	
	# Trim slots + 1 so user can keep adding until cap
	var configs:Array = project.get(TEMPLATE_CONFIGS)
	configs = configs.filter(func(v): return v)
	for i in configs.size():
		configs[i].set_instance_index( i )
	if configs.size() < cap:
		configs.resize(configs.size() + 1)
	
	# Hide empty export slots
	var index:int = property.name.right(1).to_int()
	if index > configs.size()-1:
		property.usage = PROPERTY_USAGE_NONE
	project.set(TEMPLATE_CONFIGS, configs)


func _set_project(new_type, project:SaveData, new_project:SaveData):
	set(TEMPLATE_PROJECT, new_project)
	if not is_ready: return
	if new_project:
		_notify_property_list_changed_once()
		new_project.fix_dependencies()
		new_project.select_brush(CURRENT_TAB.brush, self)
		new_project.load_project_data()
	else:
		set(TEMPLATE_PROJECT, new_type.new())
		_notify_property_list_changed_once()


func _validate_paint_with_sencondary_color(property:Dictionary):
	var hide_properties:Array[String] = [
		"parent_of_physics_body", "children_of_physics_body", "relative_path_from_physics_body",
		"active_material_indexes",
		"paths_in_standar_materials", "paths_in_shader_materials", "fallback_color",
	]
	if property.name in hide_properties:
		property.usage = PROPERTY_USAGE_NONE

## The amount of messages printed from Godot Landscaper
@export var level:GLDebug.Level=GLDebug.Level.STATES:
	set(v): GLDebug.level = v
	get: return GLDebug.level


## Diameter of the 3D brush sphere. Keybind is [Shift] + [MouseWheel]
@export_range(0.1, 20, 0.1) var brush_size:float = 2.0:
	set(v):
		if Landscaper.running():
			Landscaper.scene.brush.set_scale_ratio(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_scale_ratio()
		return 0.1

## Color of the 3D brush shpere
@export var brush_color:Color = Color(1.0, 0.0, 1.0, 0.3):
	set(v):
		if Landscaper.running():
			Landscaper.scene.brush.set_color(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_color()
		return Color.MAGENTA


# This avoids clicktrhough
var is_ready:bool
func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	is_ready = true

# This avoids calling notify_property_list_changed() too often or stack overflowing it
var _notify_dirty:bool
func _notify_property_list_changed_once() -> void:
	_notify_dirty = true
	_call_notify_property_list.call_deferred()
func _call_notify_property_list() -> void:
	if _notify_dirty:
		_notify_dirty = false
		notify_property_list_changed()
		GLDebug.spam("Notified property list change once")

func selected() -> void:
	pass

func deselected() -> void:
	pass

func action_start(hit_info:Dictionary) -> void:
	pass

func action_primary(hit_info:Dictionary) -> void:
	pass

func action_secondary(hit_info:Dictionary) -> void:
	pass

func action_end() -> void:
	pass

func scale_by(value:float):
	pass
