extends Resource
class_name GLDeckShuffle

var _deck:Array


func _init(... deck:Array):
	_deck = deck


func next() -> Variant:
	var hand:Variant = _deck.pop_front()
	_deck.push_back( hand )
	return hand
