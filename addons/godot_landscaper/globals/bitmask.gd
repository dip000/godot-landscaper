## Highly overengineered bit utilities.
##
## Has iterators, set, reset, static, stringify, shampoo, lubricant, signal, etc..
@tool
extends RefCounted
class_name GLBitMask

signal on_mask_changed(mask:int)

var mask:int
var total:int


func _init(mask:int=0, total_layers:int=32):
	self.mask = mask
	self.total = total_layers
	on_mask_changed.emit( mask )

func _iter_init(iter) -> bool:
	iter[0] = 0
	return iter[0] < total

func _iter_next(iter) -> bool:
	iter[0] += 1
	return iter[0] < total

func _iter_get(iter) -> int:
	return iter


func _to_string() -> String:
	return format_mask( mask, total )


func is_set(index) -> bool:
	return get_bit(index) == 1

func is_clear(index:int) -> bool:
	return get_bit(index) == 0

func get_bit(index:int) -> int:
	return (mask >> index) & 1

func set_bit(index:int):
	if index >= 0 and index < total:
		set_mask( 1 << index )

func clear_bit(index:int):
	if index >= 0 and index < total:
		clear_mask( 1 << index )

func set_mask(new_mask:int):
	mask |= new_mask
	on_mask_changed.emit( mask )

func clear_mask(new_mask:int=0xFFFF_FFFF):
	mask &= ~new_mask
	on_mask_changed.emit( mask )


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


static func format_mask(mask:int, total_layers:int) -> String:
	var hex_digits:int = int(ceil(total_layers / 4.0))
	var trimmed:int = mask & ((1 << total_layers) - 1)
	return "0x%0*X" % [hex_digits, trimmed]



	
