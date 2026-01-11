extends RefCounted
class_name GLBitMask

var mask:int
var total:int
var _bit_index:int


func _init(mask:int, total_layers:int=32):
	self.mask = mask
	self.total = total_layers

func _iter_init(_arg) -> bool:
	_bit_index = 0
	return _bit_index < total

func _iter_next(_arg) -> bool:
	_bit_index += 1
	return _bit_index < total

func _iter_get(_arg) -> int:
	return _bit_index


func is_set(index) -> int:
	return get_bit(index) == 1

func is_clear(index:int) -> int:
	return get_bit(index) == 0

func get_bit(index:int) -> int:
	return (mask >> index) & 1

func set_bit(index:int):
	if index >= 0:
		mask |= (1 << index)

func clear_bit(index:int):
	if index >= 0:
		mask &= ~(1 << index)


static func set_bit_mask(mask:int, index:int) -> int:
	if index >= 0:
		mask |= (1 << index)
	return mask

static func clear_bit_mask(mask:int, index:int) -> int:
	if index >= 0:
		mask &= ~(1 << index)
	return mask

static func get_bit_mask(mask:int, index:int) -> int:
	return (mask >> index) & 1
