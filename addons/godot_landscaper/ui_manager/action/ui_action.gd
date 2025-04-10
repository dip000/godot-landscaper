@tool
extends VBoxContainer
class_name UIAction

@onready var instances:UITabs = %Instances
@onready var brush_diameter:UIRange = %BrushDiameter

var _strokes:Array[Stroke]


func _enter():
	show()

func _exit():
	hide()

func _create_multi_mesh() -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.mesh = AssetsManager.QUAD_GRASS
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	return multimesh


func action_start(hit_info:Dictionary):
	# Fix references
	var current_scene:Node = get_tree().edited_scene_root
	var root:Node3D = SceneManager.find_or_create_node( Node3D, current_scene, "EcoLandscaper" )
	root.owner = current_scene
	_strokes.clear()
	
	# Fill initial stroke
	for instance in instances.enabled_tabs:
		if instance is UIInstance:
			var stroke := Stroke.new()
			stroke.root_node = root
			stroke.instance = instance.data
			stroke.surface_position = hit_info.collider.global_position
			stroke.radius = brush_diameter.value * 0.5
			_strokes.append( stroke )
	

func action_primary(hit_info:Dictionary): ## virtual
	pass

func action_secondary(hit_info:Dictionary): ## virtual
	pass

func action_end():
	pass
