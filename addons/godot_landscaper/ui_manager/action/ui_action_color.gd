@tool
extends UIAction
class_name UIActionColor

@onready var primary_color:UIColorPicker = $PrimaryColor
@onready var secondary_color:UIColorPicker = $SecondaryColor



func action_start(hit_info:Dictionary):
	# Fill base properties
	super( hit_info )
	
	# Add Action-specific properties to the stroke
	for stroke in _strokes:
		stroke.primary_color = primary_color.color
		stroke.secondary_color = secondary_color.color
		stroke.instance.color.start( stroke )
	
	

func action_primary(hit_info:Dictionary):
	for stroke in _strokes:
		stroke.cursor_position = hit_info.position
		stroke.face_index = hit_info.face_index
		stroke.instance.color.primary( stroke )


func action_secondary(hit_info:Dictionary):
	for stroke in _strokes:
		stroke.cursor_position = hit_info.position
		stroke.face_index = hit_info.face_index
		stroke.instance.color.secondary( stroke )


func action_end():
	for stroke in _strokes:
		stroke.instance.color.end()
