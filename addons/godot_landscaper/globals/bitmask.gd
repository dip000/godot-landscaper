extends RefCounted
class_name GLBitMask

var mask:int
var total:int


func _init(mask:int, total_layers:int=32):
	self.mask = mask
	self.total = total_layers

func _iter_init(iter) -> bool:
	iter[0] = 0
	return iter[0] < total

func _iter_next(iter) -> bool:
	iter[0] += 1
	return iter[0] < total

func _iter_get(iter) -> int:
	return iter


func is_set(index) -> bool:
	return get_bit(index) == 1

func is_clear(index:int) -> bool:
	return get_bit(index) == 0

func get_bit(index:int) -> int:
	return (mask >> index) & 1

func set_bit(index:int):
	if index >= 0:
		set_mask( 1 << index )

func clear_bit(index:int):
	if index >= 0:
		clear_mask( 1 << index )

func set_mask(mask:int):
	mask |= mask

func clear_mask(mask:int):
	mask &= ~mask


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
