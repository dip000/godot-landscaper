extends RefCounted
class_name Rect2iter

var _rect: Rect2i
var _x: int
var _y: int

func _init(rect: Rect2i):
	_rect = rect

func _iter_init(_iter):
	_x = _rect.position.x
	_y = _rect.position.y
	return _rect.size.x > 0 and _rect.size.y > 0

func _iter_next(_iter):
	_x += 1
	if _x >= _rect.position.x + _rect.size.x:
		_x = _rect.position.x
		_y += 1
	return _y < _rect.position.y + _rect.size.y

func _iter_get(_iter) -> Vector2i:
	return Vector2i(_x, _y)
