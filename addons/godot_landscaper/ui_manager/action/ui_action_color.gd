@tool
extends UIAction
class_name UIActionColor

@onready var primary_color:UIColorPicker = $PrimaryColor
@onready var secondary_color:UIColorPicker = $SecondaryColor
@onready var ground_gradient:UIRange = $GroundGradient


func _ready():
	ground_gradient.on_change.connect( _on_ground_gradient_changed )

func _on_ground_gradient_changed():
	for stroke in _strokes:
		if stroke.mm:
			var mat:ShaderMaterial = stroke.mm.mesh.surface_get_material(0)
			mat.set_shader_parameter("ground_gradient", ground_gradient.value)


func action_start(hit_info:Dictionary):
	# Fill base properties
	super( hit_info )
	
	# Add ActionColor-specific properties to the stroke
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
