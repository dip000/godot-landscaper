## Handy Cell Iterator For Recti
##
## Usefull for cleaning up the double for loop of:[br]
## [code]
## for x in width + offset_x:
##     for y in height + offset_y:
##         var cell := Vector2i(x, y)
## [/code][br]
##
## This class allows for safe cell iterations including the offsets (Rect2i.position)[br]
## [code]
## for cell in GLRect2iter.from(my_rect)
## [/code][br]
## 
## [b]Tip[/b]: Use Recti.intersect(..) previous of iterating to define an effect area
## for long iterations like in image processing

@tool
extends RefCounted
class_name GLRect2iter

var _position:Vector2i
var _size:Vector2i
var _x:int
var _y:int


func _init(position:Vector2i, size:Vector2i):
	_position = position
	_size = size


## Constructor that returns a GLRect2iter initialized with a Rect2i instead of position and size
static func from(rect:Rect2i) -> GLRect2iter:
	return GLRect2iter.new( rect.position, rect.size )


## Shorthand for [member range] with rects in one dimension.
## This is more performant than using [member from] in larger loops
static func range_y(rect:Rect2i) -> PackedInt32Array:
	return range(rect.position.y, rect.end.y)


## Shorthand for [member range] with rects in one dimension.
## This is more performant than using [member from] in larger loops
static func range_x(rect:Rect2i) -> PackedInt32Array:
	return range(rect.position.x, rect.end.x)


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







	
