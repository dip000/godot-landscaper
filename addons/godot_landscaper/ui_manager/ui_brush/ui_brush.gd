@tool
extends State
class_name UIBrush
## BASE VIRTUAL CLASS FOR ALL BRUSHES
## Brushes may implement state logic from 'State' class.
## Brushes may implement a different functionality based of brush-painting.
## Brush-specific properties inherit from 'UIProperty'.


# Pack/Unpack properties from new "project"
func _load_ui():
	pass

func _save_ui():
	pass

# Called while paint-brushing over the 3D scene's terrain
func _paint_start(info:Dictionary):
	pass

func _paint_primary(info:Dictionary):
	pass

func _paint_secondary(info:Dictionary):
	pass

func _paint_end():
	pass

# Any logic needed to rebuild the scene terrain; update textures, colliders, shaders, scatteres, ect..
func _rebuild():
	pass
