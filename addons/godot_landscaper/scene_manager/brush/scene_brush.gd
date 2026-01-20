@tool
extends Node3D
class_name SceneBrush

const SCALE_INCREASE:Vector3 = Vector3.ONE * 0.1
const GRID_MARGIN:float = 5

@onready var _brushes:Node3D = $Brushes

@onready var _sphere_brush:Node3D = %Sphere
@onready var _sphere_icon:Sprite3D = %Sphere/Icon

@onready var _box_brush:Node3D = %Box
@onready var _box_icon:Sprite3D = %Box/Icon

@onready var _grid:MeshInstance3D = $Grid


func selected(controller:GLController):
	if controller.use_grid:
		_grid.process_mode = Node.PROCESS_MODE_INHERIT
		_grid.show()
		_box_brush.show()
		_sphere_brush.hide()
	else:
		_grid.process_mode = Node.PROCESS_MODE_DISABLED
		_grid.hide()
		_box_brush.hide()
		_sphere_brush.show()

func deselected(controller:GLController):
	_grid.process_mode = Node.PROCESS_MODE_DISABLED
	_grid.hide()
	_box_brush.hide()
	_sphere_brush.hide()


func over_surface(controller:GLController, pos:Vector3):
	if controller.use_grid:
		if roundi( get_scale_ratio() ) % 2 == 0.0:
			pos.x = roundf(pos.x)
			pos.z = roundf(pos.z)
		else:
			pos.x = floorf(pos.x) + 0.5
			pos.z = floorf(pos.z) + 0.5
		_box_brush.global_position = pos
		_set_shader( "mask_center", pos )
	else:
		_sphere_brush.global_position = pos
		_sphere_icon.global_position.y = pos.y + get_scale_ratio()


func select_brush(brush:GLBrush):
	_sphere_icon.texture = brush.icon
	_box_icon.texture = brush.icon


func scale_down(controller:GLController):
	if controller.use_grid:
		_brushes.scale -= Vector3.ONE
		_brushes.scale = _brushes.scale.clampf( 1, 100 )
		_brushes.scale.y = 1
		_brushes.scale = _brushes.scale.round()
		_set_shader( "mask_radius", get_radius() + GRID_MARGIN )
	else:
		_brushes.scale -= SCALE_INCREASE
		_brushes.scale = _brushes.scale.clampf( 0.1, 100 )

func scale_up(controller:GLController):
	if controller.use_grid:
		_brushes.scale += Vector3.ONE
		_brushes.scale = _brushes.scale.clampf( 1, 100 )
		_brushes.scale.y = 1
		_brushes.scale = _brushes.scale.round()
		_set_shader( "mask_radius", get_radius() + GRID_MARGIN )
	else:
		_brushes.scale.y = _brushes.scale.x
		_brushes.scale.z = _brushes.scale.x
		_brushes.scale += SCALE_INCREASE
		_brushes.scale = _brushes.scale.clampf( 0.1, 100 )


func set_scale_ratio(controller:GLController, value:float):
	_brushes.scale.x = clampf(value, 0.1, 100)
	_brushes.scale.z = clampf(value, 0.1, 100)
	if controller.use_grid:
		_brushes.scale.y = 1
		_brushes.scale = _brushes.scale.round()
		_set_shader( "mask_radius", get_radius() + GRID_MARGIN )
	else:
		_brushes.scale.y = clampf(value, 0.1, 100)

func get_scale_ratio() -> float:
	return _brushes.scale.x

func get_radius() -> float:
	return _brushes.scale.x * 0.5


func _set_shader(parameter:String, value:Variant):
		_grid.material_override.set_shader_parameter( parameter, value )
	
