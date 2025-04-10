@tool
extends Action
class_name ActionMMIColor

var transforms:Array[Transform3D]
var top_colors:Array[Color]


func start(stroke:Stroke):
	# Add Multimesh if needed
	var mmi:MultiMeshInstance3D = SceneManager.find_or_create_node( MultiMeshInstance3D, stroke.root_node, stroke.instance.name )
	if not mmi.multimesh:
		mmi.multimesh = MultiMesh.new()
		mmi.multimesh.mesh = AssetsManager.QUAD_GRASS
		mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mmi.multimesh.use_colors = true
		mmi.multimesh.use_custom_data = true
	stroke.mm = mmi.multimesh
	
	# Initialize
	transforms.clear()
	top_colors.clear()
	_get_all( stroke )


func primary(stroke:Stroke):
	_paint_radial( stroke, stroke.primary_color )
	_spawn( stroke )

func secondary(stroke:Stroke):
	_paint_radial( stroke, stroke.secondary_color )
	_spawn( stroke )


# Gets every MultiMesh transform and color
func _get_all(stroke:Stroke):
	for i in stroke.mm.instance_count:
		transforms.append( stroke.mm.get_instance_transform(i) )
		top_colors.append( stroke.mm.get_instance_custom_data(i) )


# Gets every MultiMesh transform and color
func _paint_radial(stroke:Stroke, color:Color):
	for i in stroke.mm.instance_count:
		var pos:Vector3 = transforms[i].origin
		var dist:float = stroke.cursor_position.distance_to(pos)
		if dist < stroke.radius:
			top_colors[i] = color
	

# Re-Spawns the grass from the transforms given
func _spawn(stroke:Stroke):
	for i in range(stroke.mm.instance_count):
		stroke.mm.set_instance_custom_data( i, top_colors[i] )
