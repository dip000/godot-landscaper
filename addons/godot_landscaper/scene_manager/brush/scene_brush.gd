@tool
extends Node3D
class_name GLSceneBrush

const SCALE_INCREASE:Vector3 = Vector3.ONE * 0.2
const GRID_MARGIN:float = 5

@onready var _icon:Sprite3D = %Icon
@onready var _sphere:Node3D = %Sphere
@onready var _grid_select:MeshInstance3D = %GridSelect
@onready var _static_grid:MeshInstance3D = %StaticGrid


func selected(controller:GLController):
	if not controller.is_ready:
		deselected( controller )
		return
	show()
	_icon.set_disable_scale( true )
	if controller.use_grid:
		_static_grid.process_mode = Node.PROCESS_MODE_INHERIT
		_static_grid.show()
		_grid_select.show()
	else:
		_static_grid.process_mode = Node.PROCESS_MODE_DISABLED
		_static_grid.hide()
		_grid_select.hide()
	
	set_size.call_deferred(controller.use_grid, controller.brush_size)


func deselected(controller:GLController):
	_grid_select.process_mode = Node.PROCESS_MODE_DISABLED
	hide()


func over_surface(controller:GLController, scan_data:GLScanData):
	var pos:Vector3 = scan_data.position
	_sphere.global_position = pos
	
	if controller.use_grid:
		_set_shader( "mask_center", pos )
	if _is_size_even():
		pos.x = roundf(pos.x)
		pos.z = roundf(pos.z)
	else:
		pos.x = floorf(pos.x) + 0.5
		pos.z = floorf(pos.z) + 0.5
	_grid_select.global_position = pos


func select_brush(brush:GLBrush):
	_icon.texture = brush.icon


func scale_down(controller:GLController):
	_sphere.scale -= SCALE_INCREASE
	_sphere.scale = _sphere.scale.clampf( 0.1, 100 )
	if controller.use_grid:
		_grid_select.scale = _sphere.scale.clampf( 1, 100 )
		_grid_select.scale = _sphere.scale.round()
		_grid_select.scale.y = 1
		_set_shader( "mask_radius", get_radius() + GRID_MARGIN )


func scale_up(controller:GLController):
	_sphere.scale += SCALE_INCREASE
	_sphere.scale = _sphere.scale.clampf( 0.1, 100 )
	if controller.use_grid:
		_grid_select.scale = _sphere.scale.clampf( 1, 100 )
		_grid_select.scale = _sphere.scale.round()
		_grid_select.scale.y = 1
		_set_shader( "mask_radius", get_radius() + GRID_MARGIN )


func set_size(use_grid:bool, value:float):
	_sphere.scale = Vector3.ONE * value
	_sphere.scale = _sphere.scale.clampf( 0.1 , 100 )
	if use_grid:
		_grid_select.scale = _sphere.scale.clampf( 1, 100 )
		_grid_select.scale = _sphere.scale.round()
		_grid_select.scale.y = 1
		_set_shader( "mask_radius", get_radius() + GRID_MARGIN )


func get_size() -> float:
	return _sphere.scale.x


func get_rect() -> Rect2:
	var rect:Rect2 = Rect2(_grid_select.global_position.x, _grid_select.global_position.z, 0, 0)
	return rect.grow( _grid_select.scale.x * 0.5 )

func get_radius() -> float:
	return _sphere.scale.x * 0.5


func _set_shader(parameter:String, value:Variant):
	_static_grid.material_override.set_shader_parameter( parameter, value )


func _is_size_even() -> bool:
	return (roundi( _sphere.scale.x ) % 2 == 0)
	
	
