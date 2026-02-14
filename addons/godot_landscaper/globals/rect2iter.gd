extends RefCounted
class_name GLRect2iter

var _position:Vector2i
var _size:Vector2i
var _x:int
var _y:int


func _init(position:Vector2i, size:Vector2i):
	_position = position
	_size = size

static func from(rect:Rect2i) -> GLRect2iter:
	return GLRect2iter.new( rect.position, rect.size )

func _iter_init(_iter):
	_x = _position.x
	_y = _position.y
	return _size.x > 0 and _size.y > 0

func _iter_next(_iter):
	_x += 1
	if _x >= _position.x + _size.x:
		_x = _position.x
		_y += 1
	return _y < _position.y + _size.y

func _iter_get(_iter) -> Vector2i:
	return Vector2i(_x, _y)
