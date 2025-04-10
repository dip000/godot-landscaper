@tool
extends UIAction
class_name UIActionSpawn

@onready var add_ratio:UIRange = $AddRatio
@onready var remove_ratio:UIRange = $RemoveRatio


func action_start(hit_info:Dictionary):
	# Fill base properties
	super( hit_info )
	
	# Add Action-specific properties to the stroke
	for stroke in _strokes:
		stroke.add_ratio = add_ratio.value
		stroke.remove_ratio = remove_ratio.value
		stroke.instance.spawn.start( stroke )
	
	

func action_primary(hit_info:Dictionary):
	for stroke in _strokes:
		stroke.cursor_position = hit_info.position
		stroke.face_index = hit_info.face_index
		stroke.instance.spawn.primary( stroke )


func action_secondary(hit_info:Dictionary):
	for stroke in _strokes:
		stroke.cursor_position = hit_info.position
		stroke.face_index = hit_info.face_index
		stroke.instance.spawn.secondary( stroke )


func action_end():
	for stroke in _strokes:
		stroke.instance.spawn.end()
