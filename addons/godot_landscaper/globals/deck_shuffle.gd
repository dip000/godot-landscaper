## Shuffler based on a "deck"
##
## The main characteristic of a "deck" or stack
## is that the "cards" or values never repeat until the deck is empty.

@tool
extends Resource
class_name GLDeckShuffle

var _deck:Array


## Constructor for using a starting array as deck
func _init(deck:Array):
	_deck = deck

func _iter_init(iter) -> bool:
	iter[0] = 0
	return iter[0] < _deck.size()

func _iter_next(iter) -> bool:
	iter[0] += 1
	return iter[0] < _deck.size()

func _iter_get(iter) -> Variant:
	return _deck[iter]


## Constructor for using the input arguments as deck
static func from_args(... deck:Array) -> GLDeckShuffle:
	return GLDeckShuffle.new( deck )


## Returns the next card from the deck.
## Does not repeat cards until emptied.
## Returns the elements in order, use shuffle() first to randomize 
func next() -> Variant:
	var hand:Variant = _deck.pop_front()
	_deck.push_back( hand )
	return hand


func shuffle():
	_deck.shuffle()



	
